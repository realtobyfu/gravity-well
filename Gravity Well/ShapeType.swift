//
//  ShapeType.swift
//  Gravity Well
//
//  Created by Tobias Fu on 15/09/2025.
//

import UIKit

// MARK: - Shape Types
enum ShapeType: CaseIterable {
    case star, triangle, hexagon, circle, cross

    var color: UIColor {
        switch self {
        case .star: return UIColor.cyan
        case .triangle: return UIColor.magenta
        case .hexagon: return UIColor.green
        case .circle: return UIColor.yellow
        case .cross: return UIColor.orange
        }
    }

    func path(in rect: CGRect) -> UIBezierPath {
        switch self {
        case .star:
            return starPath(in: rect)
        case .triangle:
            return trianglePath(in: rect)
        case .hexagon:
            return hexagonPath(in: rect)
        case .circle:
            return UIBezierPath(ovalIn: rect)
        case .cross:
            return crossPath(in: rect)
        }
    }

    private func starPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let rInner = r * 0.4

        for i in 0..<10 {
            let angle = (CGFloat(i) * .pi * 2) / 10 - .pi/2
            let radius = i % 2 == 0 ? r : rInner
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            i == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.close()
        return path
    }

    private func trianglePath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.close()
        return path
    }

    private func hexagonPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for i in 0..<6 {
            let angle = (CGFloat(i) * .pi * 2) / 6 - .pi/2
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            i == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.close()
        return path
    }

    private func crossPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let thickness = rect.width * 0.3

        // Horizontal
        path.move(to: CGPoint(x: rect.minX, y: rect.midY - thickness/2))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY - thickness/2))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + thickness/2))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + thickness/2))
        path.close()

        // Vertical
        path.move(to: CGPoint(x: rect.midX - thickness/2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + thickness/2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + thickness/2, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - thickness/2, y: rect.maxY))
        path.close()

        return path
    }
}