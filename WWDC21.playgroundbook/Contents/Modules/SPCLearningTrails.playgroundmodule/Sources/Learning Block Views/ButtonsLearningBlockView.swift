//
//  ButtonsLearningBlockView.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import PDFKit
import SPCCore

public protocol ButtonsLearningBlockViewDelegate {
    func didPressButton(_ buttonsBlockView: ButtonsLearningBlockView, button: LearningInteractive.Button, screenRect: CGRect)
}

class ChoiceButton: UIButton {
    
    override var isHighlighted: Bool {
        didSet {
            guard oldValue != isHighlighted else { return }
            // Highlight entire button by reducing alpha.
            UIView.animate(withDuration: 0.25, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                self.alpha = self.isHighlighted ? 0.7 : 1
            }, completion: nil)
        }
    }
    
}

public class ButtonsLearningBlockView: UIView {
    
    enum Distribution: String {
        case horizontal, vertical
    }
    
    public var learningBlock: LearningBlock?
    public var style: LearningBlockStyle?
    public var textStyle: AttributedStringStyle?
    
    private var distribution: Distribution = .horizontal

    private var buttons = [UIButton]()
    private var choices = [LearningInteractive.Button]()
    
    // Default Specified size: see below.
    private var defaultSizeRelativeToWidth = CGSize(width: -1, height: 0.35)
    
    // Specified size (normalized) for the content relative to the width of the block.
    // The content is aspect-fitted within the specified size.
    // Size width and height values are normalized, and both are relative to the width. -1 => unspecified.
    // Examples:
    //      (width: -1, height: 0.5) => the height of the image is to be 0.5 times the width of the block.
    //      (width: 0.8, height: -1) => the width of the image is to be 0.8 times the width of the block.
    // Note that when the width is specified, the block may change size once the image is loaded as it has to calculate the height based on the image aspect ratio.
    private var specifiedSizeRelativeToWidth = CGSize(width: -1, height: -1)
    
    private var choicesDescription: String?
    
    private var interactive: LearningInteractive?
    
    public var delegate: ButtonsLearningBlockViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isAccessibilityElement = false // Accessibility container
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func load(interactive: LearningInteractive) {
        guard let learningBlock = learningBlock else { return }
        self.interactive = interactive
        for (index, choice) in interactive.buttons.enumerated() {
            let button = ChoiceButton()
            guard let textStyle = textStyle else { return }
            if let textXML = choice.xmlText?.linesLeftTrimmed() {
                let attributedText = NSMutableAttributedString(attributedString: NSAttributedString(xml: textXML, style: textStyle))
                button.setAttributedTitle(attributedText, for: .normal)
                button.titleLabel?.sizeToFit()
            }
            button.addTarget(self, action: #selector(didPressButton), for: .touchUpInside)
            button.accessibilityIdentifier = "\(learningBlock.accessibilityIdentifier).button\(index + 1)"
            button.backgroundColor = ButtonsLearningBlockStyle.buttonBackgroundColor
            button.layer.cornerRadius = ButtonsLearningBlockStyle.buttonCornerRadius
            button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
            button.titleLabel?.numberOfLines = 0

            addSubview(button)
            buttons.append(button)
            choices.append(choice)
        }
    }
    
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        // Start with a square width x width: the size returned will never be larger than this.
        let availableSize = CGSize(width: size.width, height: size.width)
        var returnSize = availableSize
        
        if specifiedSizeRelativeToWidth.height >= 0 {
            // Height is specified => sufficient to fully determine size.
            returnSize.height = min(availableSize.width * specifiedSizeRelativeToWidth.height, availableSize.width)
        }
        
        // Add any margins.
        returnSize.width += (layoutMargins.left + layoutMargins.right)
        returnSize.height += (layoutMargins.top + layoutMargins.bottom)
        return returnSize
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        let availableBounds = bounds.inset(by: layoutMargins)
        
        let padding = ButtonsLearningBlockStyle.buttonPadding
        var buttonSize = CGSize()
        
        if distribution == .horizontal {
            // Distribute buttons horizontally.
            buttonSize.height = availableBounds.height
            let buttonsWidth = availableBounds.width - (padding * CGFloat((choices.count - 1)))
            buttonSize.width = buttonsWidth / CGFloat(choices.count)
            var position = CGPoint(x: layoutMargins.left + (buttonSize.width / 2.0),
                                         y: layoutMargins.left + (buttonSize.height / 2.0))
            for button in buttons {
                button.frame = CGRect(origin: CGPoint.zero, size: buttonSize)
                button.center = position
                position.x += buttonSize.width + padding
            }
        } else {
            // Distribute buttons vertically.
            buttonSize.width = availableBounds.width
            let buttonsHeight = availableBounds.height - (padding * CGFloat((choices.count - 1)))
            buttonSize.height = buttonsHeight / CGFloat(choices.count)
            var position = CGPoint(x: layoutMargins.left + (buttonSize.width / 2.0),
                                         y: layoutMargins.left + (buttonSize.height / 2.0))
            for button in buttons {
                button.frame = CGRect(origin: CGPoint.zero, size: buttonSize)
                button.center = position
                position.y += buttonSize.height + padding
            }
        }
    }
    
    /// Returns the image view frame in screen coordinates.
    private func rectInScreenCoordinateSpaceFor(frame: CGRect) -> CGRect {
        return convert(frame, to: nil)
    }
    
    private func updateAX() {
        accessibilityElements = buttons
    }
    
    // MARK: Actions

    @objc
    func didPressButton(_ sender: UIButton) {
        guard let index = buttons.firstIndex(of: sender), index < choices.count else { return }
        let screenRect = rectInScreenCoordinateSpaceFor(frame: sender.frame)
        delegate?.didPressButton(self, button: choices[index], screenRect: screenRect)
    }
}

// MARK: LearningBlockViewable
extension ButtonsLearningBlockView: LearningBlockViewable {
    public func load(learningBlock: LearningBlock, style: LearningBlockStyle, textStyle: AttributedStringStyle? = nil) {
        self.learningBlock = learningBlock
        self.style = style
        self.textStyle = textStyle
        
        directionalLayoutMargins = style.margins
        backgroundColor = style.backgroundColor
        
        if let distributionValue = learningBlock.attributes["distribution"], let distribution = Distribution(rawValue: distributionValue) {
            self.distribution = distribution
        }

        if let heightValue = learningBlock.attributes["height"] {
            if let height = Float(heightValue) {
                specifiedSizeRelativeToWidth.height = CGFloat(height)
            }
        }
        
        if specifiedSizeRelativeToWidth.width == -1 && specifiedSizeRelativeToWidth.height == -1 {
            specifiedSizeRelativeToWidth = defaultSizeRelativeToWidth
        }

        let blockXML = "<block>\(learningBlock.content)</block>"
        
        if let descriptionElement = SlimXMLParser.getElementsIn(xml: blockXML, named: "description").first {
            choicesDescription = descriptionElement.content
        }
        
        if let interactiveElement = SlimXMLParser.getElementsIn(xml: blockXML, named: "interactive").first {
            let interactiveXML = "<interactive>\(interactiveElement.content)</interactive>"
            if let interactive = LearningInteractive(xml: interactiveXML) {
                self.load(interactive: interactive)
            }
        }
        
        updateAX()
    }
}
