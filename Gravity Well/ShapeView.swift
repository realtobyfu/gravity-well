//
//  ShapeView.swift
//  Gravity Well
//
//  Created by Tobias Fu on 15/09/2025.
//

import UIKit

// MARK: - Shape View
class ShapeView: UIView {
    let shapeType: ShapeType

    init(type: ShapeType, position: CGPoint) {
        self.shapeType = type
        let size = CGSize(width: 40, height: 40)
        super.init(frame: CGRect(origin: position, size: size))
        setupShape()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupShape() {
        backgroundColor = .clear

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = shapeType.path(in: bounds).cgPath
        shapeLayer.fillColor = shapeType.color.cgColor
        shapeLayer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        shapeLayer.lineWidth = 2
        layer.addSublayer(shapeLayer)

        // Add glow
        layer.shadowColor = shapeType.color.cgColor
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.8
        layer.shadowOffset = .zero
    }

    override var collisionBoundsType: UIDynamicItemCollisionBoundsType { .path }
    override var collisionBoundingPath: UIBezierPath { shapeType.path(in: bounds) }
}