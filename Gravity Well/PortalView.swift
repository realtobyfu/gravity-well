//
//  PortalView.swift
//  Gravity Well
//
//  Created by Tobias Fu on 15/09/2025.
//

import UIKit

// MARK: - Portal View
class PortalView: UIView {
    private var pulseLayer: CAShapeLayer!
    private var rotationLayer: CALayer!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPortal()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupPortal() {
        backgroundColor = .clear

        // Outer ring
        let ring = CAShapeLayer()
        ring.path = UIBezierPath(ovalIn: bounds).cgPath
        ring.fillColor = UIColor.clear.cgColor
        ring.strokeColor = UIColor.magenta.cgColor
        ring.lineWidth = 4
        layer.addSublayer(ring)

        // Inner glow
        let glow = CAGradientLayer()
        glow.frame = bounds
        glow.colors = [
            UIColor.magenta.withAlphaComponent(0.3).cgColor,
            UIColor.cyan.withAlphaComponent(0.5).cgColor,
            UIColor.clear.cgColor
        ]
        glow.type = .radial
        glow.startPoint = CGPoint(x: 0.5, y: 0.5)
        glow.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(glow, at: 0)

        // Rotation animation
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = 2 * CGFloat.pi
        rotation.duration = 8
        rotation.repeatCount = .infinity
        ring.add(rotation, forKey: "rotate")

        // Center core
        let core = UIView(frame: CGRect(x: bounds.width/2 - 15, y: bounds.height/2 - 15, width: 30, height: 30))
        core.backgroundColor = .magenta
        core.layer.cornerRadius = 15
        core.layer.shadowColor = UIColor.magenta.cgColor
        core.layer.shadowRadius = 10
        core.layer.shadowOpacity = 1
        addSubview(core)
    }

    func pulse() {
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.0
        pulse.toValue = 1.2
        pulse.duration = 0.2
        pulse.autoreverses = true
        layer.add(pulse, forKey: "pulse")
    }

    func takeDamage() {
        backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
        UIView.animate(withDuration: 0.5) {
            self.backgroundColor = .clear
        }
    }
}