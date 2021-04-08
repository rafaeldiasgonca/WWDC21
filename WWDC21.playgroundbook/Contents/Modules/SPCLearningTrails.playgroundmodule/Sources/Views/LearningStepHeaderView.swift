//
//  LearningStepHeaderView.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import SPCCore

// Implement this protocol to receive updates from a LearningStepHeaderView.
protocol LearningStepHeaderViewDelegate {
    func stepHeaderView(_ stepHeaderView: LearningStepHeaderView, didSelectStep step: LearningStep)
}

class LearningStepHeaderView: UIView {
    let textLabel = UILabel()
    var badgeViews = [LearningStepBadgeView]()
    var axElement: UIAccessibilityElement?
    
    private let badgeSize = DefaultLearningStepStyle.headerButtonSize
    private let interBadgePadding: CGFloat = 4
    private var textLabelLeadingConstraint: NSLayoutConstraint?
    
    var step: LearningStep?
    var style: LearningStepStyle?
    
    var delegate: LearningStepHeaderViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 10)
        
        addSubview(textLabel)
        
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        axElement = UIAccessibilityElement(accessibilityContainer: self)
        axElement?.isAccessibilityElement = true
        isAccessibilityElement = false // Accessibility container
        
        let labelLeadingConstraint = textLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
        let labelTrailingConstraint = textLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        labelTrailingConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            labelLeadingConstraint,
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelTrailingConstraint
        ])
        
        textLabelLeadingConstraint = labelLeadingConstraint
        backgroundColor = UIColor.secondarySystemBackgroundLT
        
        if LearningTrails.isAuthoringSupportEnabled {
            backgroundColor = UIColor.yellow.withAlphaComponent(0.5)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func load(step: LearningStep, style: LearningStepStyle, assessableSteps: [LearningStep]? = nil) {
        self.step = step
        self.style = style
        
        if LearningTrails.isStepTitleInHeader {
            // Step title in the header.
            if let title = step.title?.linesLeftTrimmed() {
                textLabel.attributedText = NSAttributedString(xml: "<title>\(title)</title>", style: style.textStyle)
            }
        } else {
            // Step type in the header.
            textLabel.attributedText = NSAttributedString(xml: "<type>\(step.type.localizedName)</type>", style: style.textStyle)
        }

        textLabel.sizeToFit()
        axElement?.accessibilityLabel = String(format: NSLocalizedString("%@ step", tableName: "SPCLearningTrails", comment: "AX step type"), step.type.localizedName)
        axElement?.accessibilityIdentifier = "\(step.identifier).steptype"

        if let assessableSteps = assessableSteps, !assessableSteps.isEmpty {
            let badgeSpacing = badgeSize.width + interBadgePadding
            var xOffset: CGFloat = layoutMargins.right + (badgeSize.width / 2) + 45 // Center of right-most badge.
            xOffset += badgeSpacing * CGFloat(assessableSteps.count - 1)
            for step in assessableSteps {
                let badgeView = LearningStepBadgeView(step: step)
                addSubview(badgeView)
                badgeViews.append(badgeView)
                badgeView.translatesAutoresizingMaskIntoConstraints = false
                
                badgeView.widthConstraint = badgeView.widthAnchor.constraint(equalToConstant: badgeSize.width)
                let aspectRatioConstraint = NSLayoutConstraint(item: badgeView,
                                                               attribute: NSLayoutConstraint.Attribute.height,
                                                               relatedBy: NSLayoutConstraint.Relation.equal,
                                                               toItem: badgeView,
                                                               attribute: NSLayoutConstraint.Attribute.width,
                                                               multiplier: 1.0,
                                                               constant: 0)

                NSLayoutConstraint.activate([
                    badgeView.centerXAnchor.constraint(equalTo: trailingAnchor, constant: -xOffset),
                    badgeView.centerYAnchor.constraint(equalTo: centerYAnchor),
                    badgeView.widthConstraint,
                    aspectRatioConstraint
                    ])
                xOffset -= badgeSpacing
                
                let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onTapBadge(recognizer:)))
                badgeView.addGestureRecognizer(gestureRecognizer)
                badgeView.isUserInteractionEnabled = true
            }
        }
        
        if let badgeView = badgeViews.first {
            let labelTrailingConstraint = textLabel.trailingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: -interBadgePadding)
            labelTrailingConstraint.priority = .required
            NSLayoutConstraint.activate([labelTrailingConstraint])
        }

        if let axElement = axElement {
            accessibilityElements = [axElement] + badgeViews
        }
        
        setNeedsDisplay()
        setNeedsLayout()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        axElement?.accessibilityFrameInContainerSpace = textLabel.frame
        var textLabelLeading = bounds.width * (1 - LearningBlockTableViewCell.contentWidthMultiplier) / 2.0
        textLabelLeading += UITextView().textContainer.lineFragmentPadding
        textLabelLeadingConstraint?.constant = textLabelLeading
    }
    
    @objc
    func onTapBadge(recognizer: UITapGestureRecognizer) {
        guard let badgeView = recognizer.view as? LearningStepBadgeView else { return }
        delegate?.stepHeaderView(self, didSelectStep: badgeView.step)
    }
    
    func refresh() {
        badgeViews.forEach({ $0.update() })
    }
    
    func celebrate() {
        var delay = 0.0
        badgeViews.forEach({
            $0.roll(after: delay)
            delay += 0.25
        })
    }
    
    func setActiveStep(_ step: LearningStep?) {
        for badgeView in badgeViews {
            badgeView.isActive = badgeView.step == step
        }
    }
}
