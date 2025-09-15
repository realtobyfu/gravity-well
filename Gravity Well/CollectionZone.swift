//
//  CollectionZone.swift
//  Gravity Well
//
//  Created by Tobias Fu on 15/09/2025.
//

import UIKit

// MARK: - Collection Zone
class CollectionZone: UIView {
    let color: UIColor
    let acceptedShape: ShapeType

    init(frame: CGRect, color: UIColor, acceptedShape: ShapeType) {
        self.color = color
        self.acceptedShape = acceptedShape
        super.init(frame: frame)
        setupZone()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupZone() {
        backgroundColor = color.withAlphaComponent(0.2)
        layer.cornerRadius = 10
        layer.borderWidth = 3
        layer.borderColor = color.cgColor

        // Add shape icon
        let iconLayer = CAShapeLayer()
        let iconPath = acceptedShape.path(in: CGRect(x: bounds.width/2 - 15, y: bounds.height/2 - 15, width: 30, height: 30))
        iconLayer.path = iconPath.cgPath
        iconLayer.fillColor = color.withAlphaComponent(0.5).cgColor
        layer.addSublayer(iconLayer)

        // Pulsing animation
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 0.2
        pulse.toValue = 0.4
        pulse.duration = 2
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        layer.add(pulse, forKey: "pulse")
    }

    func flash() {
        let flash = CABasicAnimation(keyPath: "backgroundColor")
        flash.fromValue = color.withAlphaComponent(0.2).cgColor
        flash.toValue = color.cgColor
        flash.duration = 0.3
        flash.autoreverses = true
        layer.add(flash, forKey: "flash")
    }
}