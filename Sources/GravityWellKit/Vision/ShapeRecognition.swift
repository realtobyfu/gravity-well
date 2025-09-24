import Foundation
import Vision
import CoreML
import AVFoundation
import UIKit

@available(iOS 17.0, macOS 14.0, *)
public protocol ShapeRecognitionDelegate: AnyObject {
    func didRecognizeShape(_ shape: RecognizedShape, at location: CGPoint)
    func didUpdateShapeTracking(_ shapes: [TrackedShape])
    func shapeRecognitionDidFail(with error: Error)
}

@available(iOS 17.0, macOS 14.0, *)
public struct RecognizedShape {
    public let type: PhysicsShapeType
    public let confidence: Float
    public let boundingBox: CGRect
    public let estimatedRadius: Float
    public let color: UIColor?

    public init(
        type: PhysicsShapeType,
        confidence: Float,
        boundingBox: CGRect,
        estimatedRadius: Float,
        color: UIColor? = nil
    ) {
        self.type = type
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.estimatedRadius = estimatedRadius
        self.color = color
    }
}

@available(iOS 17.0, macOS 14.0, *)
public struct TrackedShape {
    public let id: UUID
    public let shape: RecognizedShape
    public let position: Vector2
    public let lastSeen: Date
    public var isActive: Bool

    public init(shape: RecognizedShape, position: Vector2) {
        self.id = UUID()
        self.shape = shape
        self.position = position
        self.lastSeen = Date()
        self.isActive = true
    }
}

@available(iOS 17.0, macOS 14.0, *)
public final class ShapeRecognitionEngine: NSObject {
    public weak var delegate: ShapeRecognitionDelegate?

    private var visionRequests: [VNRequest] = []
    private var trackedShapes: [UUID: TrackedShape] = [:]
    private let trackingQueue = DispatchQueue(label: "com.gravitywell.shape-tracking", qos: .userInitiated)

    private var lastProcessingTime: CFTimeInterval = 0
    private let processingInterval: CFTimeInterval = 1.0 / 30.0 // 30 FPS max

    public override init() {
        super.init()
        setupVisionRequests()
    }

    private func setupVisionRequests() {
        // Shape detection using built-in Vision framework
        let shapeRequest = VNDetectRectanglesRequest { [weak self] request, error in
            self?.handleShapeDetection(request: request, error: error)
        }
        shapeRequest.minimumAspectRatio = 0.2
        shapeRequest.maximumAspectRatio = 5.0
        shapeRequest.minimumSize = 0.05
        shapeRequest.maximumObservations = 10

        // Circle detection using contour detection
        let contourRequest = VNDetectContoursRequest { [weak self] request, error in
            self?.handleContourDetection(request: request, error: error)
        }
        contourRequest.contrastAdjustment = 1.5
        contourRequest.detectsDarkOnLight = true

        visionRequests = [shapeRequest, contourRequest]
    }

    public func processFrame(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .up) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        guard currentTime - lastProcessingTime >= processingInterval else { return }
        lastProcessingTime = currentTime

        trackingQueue.async { [weak self] in
            self?.performVisionAnalysis(on: pixelBuffer, orientation: orientation)
        }
    }

    public func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        trackingQueue.async { [weak self] in
            let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try imageRequestHandler.perform(self?.visionRequests ?? [])
            } catch {
                DispatchQueue.main.async {
                    self?.delegate?.shapeRecognitionDidFail(with: error)
                }
            }
        }
    }

    private func performVisionAnalysis(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) {
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])

        do {
            try imageRequestHandler.perform(visionRequests)
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.shapeRecognitionDidFail(with: error)
            }
        }
    }

    private func handleShapeDetection(request: VNRequest, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.shapeRecognitionDidFail(with: error)
            }
            return
        }

        guard let observations = request.results as? [VNRectangleObservation] else { return }

        for observation in observations {
            let confidence = observation.confidence

            guard confidence > 0.5 else { continue }

            let boundingBox = observation.boundingBox
            let estimatedRadius = Float(min(boundingBox.width, boundingBox.height) * 50) // Convert to pixel radius estimate

            let recognizedShape = RecognizedShape(
                type: .rectangle,
                confidence: confidence,
                boundingBox: boundingBox,
                estimatedRadius: estimatedRadius
            )

            let centerPoint = CGPoint(
                x: boundingBox.midX,
                y: 1.0 - boundingBox.midY // Flip Y coordinate
            )

            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didRecognizeShape(recognizedShape, at: centerPoint)
            }

            updateTracking(with: recognizedShape, at: centerPoint)
        }
    }

    private func handleContourDetection(request: VNRequest, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.shapeRecognitionDidFail(with: error)
            }
            return
        }

        guard let observations = request.results as? [VNContoursObservation] else { return }

        for observation in observations {
            let confidence = observation.confidence

            guard confidence > 0.6 else { continue }

            // Analyze contour to determine if it's circular
            let contour = observation.topLevelContours.first
            if let contour = contour, isCircular(contour: contour) {
                let boundingBox = observation.boundingBox
                let estimatedRadius = Float(min(boundingBox.width, boundingBox.height) * 25)

                let recognizedShape = RecognizedShape(
                    type: .circle,
                    confidence: confidence,
                    boundingBox: boundingBox,
                    estimatedRadius: estimatedRadius
                )

                let centerPoint = CGPoint(
                    x: boundingBox.midX,
                    y: 1.0 - boundingBox.midY
                )

                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.didRecognizeShape(recognizedShape, at: centerPoint)
                }

                updateTracking(with: recognizedShape, at: centerPoint)
            }
        }
    }

    private func isCircular(contour: VNContour) -> Bool {
        let points = contour.normalizedPoints

        guard points.count > 8 else { return false }

        // Calculate center
        let center = points.reduce(CGPoint.zero) { sum, point in
            CGPoint(x: sum.x + point.x, y: sum.y + point.y)
        }
        let centroid = CGPoint(x: center.x / CGFloat(points.count), y: center.y / CGFloat(points.count))

        // Calculate distances from center
        let distances = points.map { point in
            let dx = point.x - centroid.x
            let dy = point.y - centroid.y
            return sqrt(dx * dx + dy * dy)
        }

        let averageDistance = distances.reduce(0, +) / Double(distances.count)
        let variance = distances.map { pow($0 - averageDistance, 2) }.reduce(0, +) / Double(distances.count)
        let standardDeviation = sqrt(variance)

        // If standard deviation is low relative to average distance, it's likely circular
        let circularityThreshold = 0.15
        return (standardDeviation / averageDistance) < circularityThreshold
    }

    private func updateTracking(with shape: RecognizedShape, at location: CGPoint) {
        let position = Vector2(Float(location.x), Float(location.y))
        let trackedShape = TrackedShape(shape: shape, position: position)

        // Simple tracking: replace old shapes or add new ones
        // In a more sophisticated implementation, you'd match shapes based on proximity and characteristics
        let shapeId = UUID()
        trackedShapes[shapeId] = trackedShape

        // Clean up old tracked shapes (older than 2 seconds)
        let cutoffTime = Date().addingTimeInterval(-2.0)
        trackedShapes = trackedShapes.filter { $0.value.lastSeen > cutoffTime }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.didUpdateShapeTracking(Array(self.trackedShapes.values))
        }
    }

    public func clearTracking() {
        trackingQueue.async { [weak self] in
            self?.trackedShapes.removeAll()
        }
    }

    public func getTrackedShapes() -> [TrackedShape] {
        return Array(trackedShapes.values)
    }
}

@available(iOS 17.0, macOS 14.0, *)
public final class CameraManager: NSObject {
    public weak var delegate: CameraManagerDelegate?

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.gravitywell.camera-session")

    private var isSessionRunning = false
    private var setupResult: SessionSetupResult = .success

    public var isRunning: Bool { isSessionRunning }

    public override init() {
        super.init()
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    private func configureSession() {
        guard setupResult == .success else { return }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .medium

        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else {
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            return
        }

        captureSession.addInput(videoDeviceInput)

        // Add video output
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        } else {
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            return
        }

        captureSession.commitConfiguration()
    }

    public func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            switch self.setupResult {
            case .success:
                self.captureSession.startRunning()
                self.isSessionRunning = self.captureSession.isRunning

            case .notAuthorized:
                DispatchQueue.main.async {
                    self.delegate?.cameraManagerDidFailWithError(.notAuthorized)
                }

            case .configurationFailed:
                DispatchQueue.main.async {
                    self.delegate?.cameraManagerDidFailWithError(.configurationFailed)
                }
            }
        }
    }

    public func stopSession() {
        sessionQueue.async { [weak self] in
            if self?.setupResult == .success {
                self?.captureSession.stopRunning()
                self?.isSessionRunning = false
            }
        }
    }

    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.delegate?.cameraManager(self!, didOutput: pixelBuffer)
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
public protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput pixelBuffer: CVPixelBuffer)
    func cameraManagerDidFailWithError(_ error: CameraError)
}

@available(iOS 17.0, macOS 14.0, *)
public enum CameraError: Error {
    case notAuthorized
    case configurationFailed

    public var localizedDescription: String {
        switch self {
        case .notAuthorized:
            return "Camera access not authorized"
        case .configurationFailed:
            return "Camera configuration failed"
        }
    }
}