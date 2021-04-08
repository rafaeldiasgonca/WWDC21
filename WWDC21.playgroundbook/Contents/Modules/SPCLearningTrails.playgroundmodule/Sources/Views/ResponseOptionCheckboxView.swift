//
//  ResponseOptionCheckboxView.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit



protocol ResponseOptionContainerDelegate {
    func didPickResponseOption(_ container: ResponseOptionContainer)
    func didTapLink(_ container: ResponseOptionContainer, url: URL, linkRect: CGRect)
}

// Response option objects should conform to this protocol.
protocol ResponseOptionContainer {
    var responseOption: LearningResponseOption { get set }
    var isEnabled: Bool { get set }
    var isSelected: Bool { get set }
    var isFeedbackVisible: Bool { get set }
    var state: LearningResponseOption.State { get set }
    var delegate: ResponseOptionContainerDelegate? { get set }
}

class ResponseOptionCheckboxView: UIView, ResponseOptionContainer {
    
    private var checkboxButton = CheckboxButton()
    private var feedbackTextView = LTTextView()
    
    var responseOption: LearningResponseOption
    
    var imageForState: UIImage? {
        switch state {
        case .unchecked:
            return UIImage(named: "checkbox-unchecked")
        case .chosen:
            return UIImage(named: "checkbox-circle")
        case .correct:
            return UIImage(named: "checkbox-tick")
        case .wrong:
            return UIImage(named: "checkbox-cross")
        }
    }
    
    public var textStyle: AttributedStringStyle
    
    var isEnabled: Bool {
        get { return checkboxButton.isEnabled }
        set { checkboxButton.isEnabled = newValue }
    }
    
    var isSelected: Bool {
        get { return checkboxButton.isSelected }
        set { checkboxButton.isSelected = newValue }
    }
    
    var isFeedbackVisible: Bool {
        get { return !feedbackTextView.isHidden }
        set { feedbackTextView.isHidden = !newValue }
    }
    
    // The current state of the checkbox.
    var state = LearningResponseOption.State.unchecked
    
    // The state of the checkbox when it’s selected.
    var stateForSelected = LearningResponseOption.State.chosen {
        didSet {
            var image: UIImage?
            switch stateForSelected {
            case .unchecked:
                image = UIImage(named: "checkbox-unchecked")
            case .chosen:
                image = UIImage(named: "checkbox-circle")
            case .correct:
                image = UIImage(named: "checkbox-tick")
            case .wrong:
                image = UIImage(named: "checkbox-cross")
            }
            checkboxButton.setImage(image, for: .selected)
            checkboxButton.setImage(image, for: [.selected, .disabled]) // After confirmed.
        }
    }
    
    var delegate: ResponseOptionContainerDelegate?
    
    init(responseOption: LearningResponseOption, textStyle: AttributedStringStyle) {
        self.responseOption = responseOption
        self.textStyle = textStyle
        super.init(frame: CGRect.zero)
        
        addSubview(checkboxButton)
        addSubview(feedbackTextView)
        
        feedbackTextView.isHidden = true
        feedbackTextView.textContainer.lineFragmentPadding = 0.0
        feedbackTextView.textContainerInset = UIEdgeInsets.zero
        feedbackTextView.ltTextViewDelegate = self
        
        let textXML = responseOption.textXML.linesLeftTrimmed()
        let attributedText = NSMutableAttributedString(attributedString: NSAttributedString(xml: textXML, style: textStyle))
        checkboxButton.setAttributedTitle(attributedText, for: .normal)
        checkboxButton.addTarget(self, action: #selector(onCheckboxValueDidChange(_:)), for: .valueChanged)
        
        if let feedbackXML = responseOption.feedbackXML?.linesLeftTrimmed {
            var styleTag = "text"
            switch responseOption.type {
            case .correct: styleTag = "correct"
                case .wrong: styleTag = "wrong"
            default: break
            }
            let feedbackTextXML = "<text><\(styleTag)>\(feedbackXML())</\(styleTag)></text>"
            feedbackTextView.attributedText = NSAttributedString(xml: feedbackTextXML, style: textStyle)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var feedbackInset: CGFloat {
        return checkboxButton.titleLabel?.frame.minX ?? 0.0
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var targetSize = CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude)
        let buttonSize = checkboxButton.sizeThatFits(targetSize)
        var returnSize = CGSize(width: targetSize.width, height: buttonSize.height)
        if isFeedbackVisible {
            targetSize.width -= feedbackInset
            let feedbackSize = feedbackTextView.sizeThatFits(targetSize)
            returnSize.height += feedbackSize.height
        }
        return returnSize
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let cbSize = checkboxButton.sizeThatFits(bounds.size)
        checkboxButton.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: cbSize.height)
        feedbackTextView.frame = CGRect(x: feedbackInset, y: checkboxButton.frame.maxY, width: bounds.size.width - feedbackInset, height: bounds.size.height - cbSize.height)
    }
    
    @objc
    func onCheckboxValueDidChange(_ sender: UIButton) {
        delegate?.didPickResponseOption(self)
    }
}

// MARK: LTTextViewDelegate
extension ResponseOptionCheckboxView: LTTextViewDelegate {
    
    public func didTapLink(_ ltTextView: LTTextView, url: URL, linkRect: CGRect) {
        delegate?.didTapLink(self, url: url, linkRect: linkRect)
    }
}
