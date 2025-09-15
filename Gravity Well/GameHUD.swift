//
//  GameHUD.swift
//  Gravity Well
//
//  Created by Tobias Fu on 15/09/2025.
//

import UIKit

// MARK: - Game HUD Manager
class GameHUD {

    private weak var containerView: UIView?

    // UI Elements
    private var scoreLabel: UILabel!
    private var livesLabel: UILabel!
    private var levelLabel: UILabel!
    private var messageLabel: UILabel!

    init(containerView: UIView) {
        self.containerView = containerView
        setupUI()
    }

    private func setupUI() {
        guard let containerView = containerView else { return }

        // Score Display
        scoreLabel = createArcadeLabel(text: "SCORE: 00000000", position: CGPoint(x: 20, y: 50))
        livesLabel = createArcadeLabel(text: "LIVES: 3", position: CGPoint(x: containerView.bounds.width - 120, y: 50))
        levelLabel = createArcadeLabel(text: "LEVEL 1", position: CGPoint(x: containerView.bounds.midX - 50, y: 50))

        // Message Label (for combos, warnings)
        messageLabel = UILabel(frame: CGRect(x: 20, y: containerView.bounds.midY - 100, width: containerView.bounds.width - 40, height: GameConfig.UI.messageHeight))
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "Courier-Bold", size: 28) ?? .boldSystemFont(ofSize: 28)
        messageLabel.textColor = .white
        messageLabel.alpha = 0
        containerView.addSubview(messageLabel)
    }

    private func createArcadeLabel(text: String, position: CGPoint) -> UILabel {
        guard let containerView = containerView else { return UILabel() }

        let label = UILabel(frame: CGRect(x: position.x, y: position.y, width: 200, height: GameConfig.UI.labelHeight))
        label.text = text
        label.textColor = GameConfig.Colors.hudText
        label.font = UIFont(name: "Courier-Bold", size: 16) ?? .boldSystemFont(ofSize: 16)
        label.layer.shadowColor = GameConfig.Colors.hudText.cgColor
        label.layer.shadowRadius = 2
        label.layer.shadowOpacity = 1
        label.layer.shadowOffset = .zero
        containerView.addSubview(label)
        return label
    }

    // MARK: - Update Methods
    func updateScore(_ score: Int) {
        scoreLabel.text = "SCORE: \(String(format: "%08d", score))"
        scoreLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        UIView.animate(withDuration: 0.3) {
            self.scoreLabel.transform = .identity
        }
    }

    func updateLives(_ lives: Int) {
        livesLabel.text = "LIVES: \(max(0, lives))"
        if lives <= 0 {
            livesLabel.textColor = .systemRed
        } else {
            livesLabel.textColor = GameConfig.Colors.hudText
        }
    }

    func updateLevel(_ level: Int) {
        levelLabel.text = "LEVEL \(level)"
    }

    func showMessage(_ text: String, duration: Double, color: UIColor = .white) {
        messageLabel.text = text
        messageLabel.textColor = color
        messageLabel.alpha = 0
        messageLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

        UIView.animate(withDuration: 0.3, animations: {
            self.messageLabel.alpha = 1
            self.messageLabel.transform = .identity
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: duration, options: [], animations: {
                self.messageLabel.alpha = 0
            }, completion: nil)
        }
    }

    func showRestartButton(target: Any?, action: Selector) {
        guard let containerView = containerView else { return }

        let button = UIButton(frame: CGRect(x: containerView.bounds.midX - 60, y: containerView.bounds.midY + 100, width: 120, height: 44))
        button.setTitle("RESTART", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 22
        button.titleLabel?.font = UIFont(name: "Courier-Bold", size: 16) ?? .boldSystemFont(ofSize: 16)
        button.addTarget(target, action: action, for: .touchUpInside)
        containerView.addSubview(button)
    }

    func removeRestartButton() {
        guard let containerView = containerView else { return }
        containerView.subviews.first(where: { $0 is UIButton })?.removeFromSuperview()
    }
}