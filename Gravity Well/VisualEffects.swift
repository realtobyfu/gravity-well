//
//  VisualEffects.swift
//  Gravity Well
//
//  Created by Tobias Fu on 15/09/2025.
//

import UIKit

// MARK: - Visual Effects Manager
class VisualEffects {

    weak var containerView: UIView?

    init(containerView: UIView) {
        self.containerView = containerView
    }

    // MARK: - Particle Effects
    func createParticleEffect(at position: CGPoint, color: UIColor) {
        guard let containerView = containerView else { return }

        // Create multiple square particles for retro effect
        for _ in 0..<GameConfig.Effects.particleCount {
            let particle = UIView(frame: CGRect(x: position.x - 2, y: position.y - 2, width: 4, height: 4))
            particle.backgroundColor = color
            particle.layer.shadowColor = color.cgColor
            particle.layer.shadowRadius = 3
            particle.layer.shadowOpacity = 1
            particle.layer.shadowOffset = .zero
            containerView.addSubview(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: GameConfig.Effects.particleMinDistance...GameConfig.Effects.particleMaxDistance)

            UIView.animate(withDuration: GameConfig.Effects.particleDuration, animations: {
                particle.center = CGPoint(
                    x: position.x + cos(angle) * distance,
                    y: position.y + sin(angle) * distance
                )
                particle.alpha = 0
                particle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }) { _ in
                particle.removeFromSuperview()
            }
        }
    }

    func createExplosion(at position: CGPoint) {
        guard let containerView = containerView else { return }

        // Create bright arcade-style explosion
        for _ in 0..<GameConfig.Effects.explosionParticleCount {
            let particle = UIView(frame: CGRect(x: position.x - 6, y: position.y - 6, width: 12, height: 12))
            particle.backgroundColor = GameConfig.Colors.explosionColors.randomElement()
            particle.layer.shadowColor = particle.backgroundColor?.cgColor
            particle.layer.shadowRadius = 4
            particle.layer.shadowOpacity = 1
            containerView.addSubview(particle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: GameConfig.Effects.explosionMinDistance...GameConfig.Effects.explosionMaxDistance)

            UIView.animate(withDuration: GameConfig.Effects.explosionDuration, animations: {
                particle.center = CGPoint(
                    x: position.x + cos(angle) * distance,
                    y: position.y + sin(angle) * distance
                )
                particle.alpha = 0
                particle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }) { _ in
                particle.removeFromSuperview()
            }
        }
    }

    // MARK: - Screen Effects
    func shakeScreen() {
        guard let containerView = containerView else { return }

        let shake = CABasicAnimation(keyPath: "position")
        shake.duration = 0.1
        shake.repeatCount = 3
        shake.autoreverses = true
        shake.fromValue = NSValue(cgPoint: CGPoint(x: containerView.center.x - 10, y: containerView.center.y))
        shake.toValue = NSValue(cgPoint: CGPoint(x: containerView.center.x + 10, y: containerView.center.y))
        containerView.layer.add(shake, forKey: "shake")
    }

    func addScanlines() {
        guard let containerView = containerView else { return }

        let scanlineLayer = CALayer()
        scanlineLayer.frame = containerView.bounds
        scanlineLayer.backgroundColor = UIColor.clear.cgColor

        // Create scanline pattern
        for i in stride(from: 0, to: Int(containerView.bounds.height), by: GameConfig.Effects.scanlineSpacing) {
            let line = CALayer()
            line.frame = CGRect(x: 0, y: CGFloat(i), width: containerView.bounds.width, height: 1)
            line.backgroundColor = GameConfig.Colors.scanline.cgColor
            scanlineLayer.addSublayer(line)
        }

        containerView.layer.insertSublayer(scanlineLayer, at: 1)
    }

    func addStarField() {
        guard let containerView = containerView else { return }

        for _ in 0..<30 {
            let star = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
            star.backgroundColor = .white
            star.alpha = CGFloat.random(in: 0.3...0.8)
            star.center = CGPoint(
                x: CGFloat.random(in: 0...containerView.bounds.width),
                y: CGFloat.random(in: 0...containerView.bounds.height)
            )
            star.layer.cornerRadius = 1
            containerView.insertSubview(star, at: 0)

            // Twinkle animation
            UIView.animate(withDuration: Double.random(in: 1...3), delay: Double.random(in: 0...1), options: [.repeat, .autoreverse], animations: {
                star.alpha = star.alpha == 0.3 ? 0.8 : 0.3
            }, completion: nil)
        }
    }
}