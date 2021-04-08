//
//  LearningStepBadgeView.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport
import SPCCore

class LearningStepBadgeView: UIView {
    private var imageView = UIImageView()
    var step: LearningStep
    
    var widthConstraint: NSLayoutConstraint = NSLayoutConstraint()
    
    var isActive: Bool = false {
        didSet {
            update()
        }
    }

    init(step: LearningStep) {
        self.step = step
        super.init(frame: CGRect.zero)
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = true
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
            imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.7)
            ])
        loadImage()
        updateAX()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let image = UIImage(named: "reward-trophy")
            DispatchQueue.main.async {
                self.imageView.image = image
                self.update()
                self.setNeedsLayout()
            }
        }
    }
    
    func update() {
        imageView.alpha = step.assessmentState == .completedSuccessfully ? 1.0 : 0.4
        updateAX()
    }
    
    func updateAX() {
        var axLabelMessage = String(format: NSLocalizedString("Reward for step %d", tableName: "SPCLearningTrails", comment: "AX reward for step n"), step.index + 1)
        if isActive {
            axLabelMessage = NSLocalizedString("Reward for this step", tableName: "SPCLearningTrails", comment: "AX reward for this step")
        }
        let axValue = step.assessmentState == .completedSuccessfully ? NSLocalizedString("completed", tableName: "SPCLearningTrails", comment: "AX completed") : NSLocalizedString("not completed", tableName: "SPCLearningTrails", comment: "AX not completed")
        var axIdentifier = "\(step.identifier).reward"
        axIdentifier += step.assessmentState == .completedSuccessfully ? ".completed" : ""
        axIdentifier += isActive ? ".active" : ""
        accessibilityLabel = axLabelMessage
        accessibilityValue = axValue
        accessibilityIdentifier = axIdentifier
    }
    
    func roll(after delay: TimeInterval) {
        UIView.animate(withDuration: 0.4, delay: delay, options: [.curveEaseIn] , animations: {
            self.imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        }, completion: { _ in
            UIView.animate(withDuration: 0.4, delay: 0.0, options: [.curveEaseOut] , animations: {
                self.imageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi * 2)
            }, completion: { _ in
                
            })
        })
    }
}
