//
//  GroupLearningBlockView.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

protocol GroupLearningBlockViewDelegate {
    func groupBlockView(_ groupBlockView: GroupLearningBlockView, didChangeDisclosedState disclosed: Bool)
}

class GroupLearningBlockView: UIView {
    public var learningBlock: LearningBlock?
    public var style: LearningBlockStyle?
    public var textStyle: AttributedStringStyle?
    
    private let backgroundView = UIView()
    private let textView = UITextView()
    private let discloseButton = UIButton()
    private let buttonSize = CGSize(width: 30, height: 30)
    private let textViewButtonPadding: CGFloat = 20
    private let alwaysDisclosedHeight: CGFloat = 8
    
    var isDisclosed: Bool = true {
        didSet {
            backgroundView.isHidden = isAlwaysDisclosed
            discloseButton.isHidden = isAlwaysDisclosed
            updateAX()
            setNeedsLayout()
        }
    }
    
    var isAlwaysDisclosed: Bool {
        return isDisclosed && !hasTitle
    }
    
    private var hasTitle: Bool {
        if let attributedString = textView.attributedText, !attributedString.string.isEmpty {
            return true
        }
        return false
    }
    
    private func updateAX() {
        let axLabel = isDisclosed ?
            NSLocalizedString("Hide", tableName: "SPCLearningTrails", comment: "AX label for disclose button when block is visible.") :
            NSLocalizedString("Show", tableName: "SPCLearningTrails", comment: "AX label for disclose button when block is hidden.")
        let axHint = isDisclosed ?
            NSLocalizedString("Hides this block", tableName: "SPCLearningTrails", comment: "AX hint for disclose button when block is visible.") :
            NSLocalizedString("Shows this block", tableName: "SPCLearningTrails", comment: "AX hint for disclose button when block is hidden.")
        textView.accessibilityHint = axHint
        discloseButton.accessibilityLabel = axLabel
        discloseButton.accessibilityHint = axHint

        guard let learningBlock = learningBlock else { return }
        let state = isDisclosed ? ".open" : ".closed"
        textView.accessibilityIdentifier = learningBlock.accessibilityIdentifier + state
        discloseButton.accessibilityIdentifier = "\(learningBlock.accessibilityIdentifier).disclosebutton" + state
    }

    var delegate: GroupLearningBlockViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 5)
        
        isOpaque = false
        
        isAccessibilityElement = false // Accessibility container
        textView.isAccessibilityElement = true
        textView.accessibilityTraits = .button
        discloseButton.isAccessibilityElement = true
        
        backgroundView.frame = bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(backgroundView)

        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isHidden = true
        textView.textContainerInset = UIEdgeInsets.zero
        textView.adjustsFontForContentSizeCategory = true
        textView.backgroundColor = UIColor.systemBackgroundLT
        addSubview(textView)
        
        discloseButton.tintColor = tintColor
        discloseButton.translatesAutoresizingMaskIntoConstraints = false
        discloseButton.addTarget(self, action: #selector(didPressDiscloseButton(_:)), for: .touchUpInside)
        addSubview(discloseButton)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onTap(recognizer:)))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let image = isDisclosed ? UIImage(named: "disclosureclose") : UIImage(named: "disclosureopen")
        let colorizedImage = image?.withRenderingMode(.alwaysTemplate)
        discloseButton.setImage(colorizedImage, for: .normal)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        super.sizeThatFits(size)
        
        if isAlwaysDisclosed {
            return CGSize(width: size.width, height: alwaysDisclosedHeight)
        }
        
        let textViewWidth = size.width - directionalLayoutMargins.leading - directionalLayoutMargins.trailing - buttonSize.width - textViewButtonPadding
        let textViewSize = textView.sizeThatFits(CGSize(width: textViewWidth, height: CGFloat.greatestFiniteMagnitude))
        let fittingSize = CGSize(width: size.width, height: textViewSize.height + directionalLayoutMargins.top + directionalLayoutMargins.bottom)
        //print("====> size: \(size) -> fittingSize \(fittingSize)")
        return fittingSize
    }
    
    // MARK: Actions
    
    @objc
    func didPressDiscloseButton(_ sender: UIButton) {
        toggleDisclosed()
    }
    
    @objc
    func onTap(recognizer: UITapGestureRecognizer) {
        toggleDisclosed()
    }
    
    // MARK: Private
    
    func toggleDisclosed() {
        isDisclosed = !isDisclosed
        delegate?.groupBlockView(self, didChangeDisclosedState: isDisclosed)
        UIAccessibility.post(notification: .layoutChanged, argument: textView)
    }
}

extension GroupLearningBlockView: LearningBlockViewable {
    
    var isVisibleToAccessibility: Bool {
        return !isAlwaysDisclosed
    }
    
    func load(learningBlock: LearningBlock, style: LearningBlockStyle, textStyle: AttributedStringStyle? = TextAttributedStringStyle.shared) {
        self.learningBlock = learningBlock
        self.style = style
        self.textStyle = textStyle

        backgroundView.backgroundColor = style.backgroundColor
        backgroundView.alpha = style.backgroundAlpha
        directionalLayoutMargins = style.margins
        
        isDisclosed = learningBlock.isDisclosed
        
        updateAX()
        
        let xmlContent = learningBlock.content.linesLeftTrimmed()
        
        if let textStyle = textStyle, !learningBlock.content.isEmpty {
            textView.attributedText = NSAttributedString(xml: xmlContent, style: textStyle)
            textView.isHidden = false
        }
        
        var buttonHeight: CGFloat = buttonSize.height
        if isAlwaysDisclosed {
            buttonHeight = 0
        }

        NSLayoutConstraint.activate([
            discloseButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            discloseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            discloseButton.widthAnchor.constraint(equalToConstant: buttonSize.width),
            discloseButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: discloseButton.leadingAnchor, constant: -textViewButtonPadding)
            ])
        
        self.setNeedsLayout()
    }
}

