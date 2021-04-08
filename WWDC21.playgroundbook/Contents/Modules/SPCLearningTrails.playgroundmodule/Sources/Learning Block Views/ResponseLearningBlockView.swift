//
//  ResponseLearningBlockView.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import SPCCore

protocol ResponseLearningBlockViewDelegate: LearningBlockViewDelegate {
    func responseBlockView(_ responseBlockView: ResponseLearningBlockView, didSelectOption index: Int)
    func responseBlockView(_ responseBlockView: ResponseLearningBlockView, didRevealFeedbackForOption index: Int)
    func responseBlockView(_ responseBlockView: ResponseLearningBlockView, didSubmitResponseFor learningResponse: LearningResponse)
}

class ResponseLearningBlockView: UIView {
    public var learningBlock: LearningBlock?
    public var style: LearningBlockStyle?
    public var textStyle: AttributedStringStyle?
    
    private let promptTextView = LTTextView()
    private var optionCheckboxViews = [ResponseOptionCheckboxView]()
    private var confirmButton: UIButton?
    private var confirmMessageLabel: UILabel?
    private var padding: CGFloat = 10
    private var confirmButtonHeight: CGFloat = 30
    private var ignoreValueChangedEvents = false
    
    public var learningResponse: LearningResponse?
    
    var delegate: ResponseLearningBlockViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        promptTextView.textContainerInset = UIEdgeInsets.zero
        promptTextView.translatesAutoresizingMaskIntoConstraints = false
        promptTextView.ltTextViewDelegate = self
        
        addSubview(promptTextView)
        layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var returnSize = CGSize(width: size.width, height: 0)
        var textSize = CGSize(width: size.width, height: 0.0)
        if promptTextView.attributedText.length > 0 {
            textSize = promptTextView.sizeThatFits(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
        }
        returnSize.height += textSize.height
        returnSize.height += textSize.height > 0 ? padding : 0

        var h: CGFloat = 0
        let availableWidth = size.width - promptTextView.textContainer.lineFragmentPadding // Line up with start of prompt text.
        for qcb in optionCheckboxViews {
            h += qcb.sizeThatFits(CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)).height
            h += (qcb != optionCheckboxViews.last) ? padding : 0.0
        }
        returnSize.height += h
        returnSize.height += directionalLayoutMargins.top + directionalLayoutMargins.bottom
        
        if let button = confirmButton {
            returnSize.height += padding
            let buttonSize = button.sizeThatFits(CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude))
            returnSize.height += max(confirmButtonHeight, buttonSize.height)
        }
        
        return returnSize
    }
    
    func load(learningResponse: LearningResponse, style: LearningBlockStyle, textStyle: AttributedStringStyle) {
        self.learningResponse = learningResponse
        self.style = style
        self.textStyle = textStyle
        
        if let xml = learningResponse.promptXML {
            promptTextView.attributedText = NSAttributedString(xml: "<text>\(xml)</text>", style: textStyle)
            let responseBlockPrefix = NSLocalizedString("Question with options", tableName: "SPCLearningTrails", comment: "AX prefix for a response block")
            promptTextView.accessibilityLabel = "\(responseBlockPrefix): \(promptTextView.attributedText.string)"
            promptTextView.accessibilityIdentifier = "\(learningResponse.identifier).prompt"
            promptTextView.backgroundColor = style.backgroundColor
        }
        
        for (index, option) in learningResponse.options.enumerated() {
            let cbv = ResponseOptionCheckboxView(responseOption: option, textStyle: textStyle)
            cbv.translatesAutoresizingMaskIntoConstraints = false
            cbv.accessibilityIdentifier = "\(learningResponse.identifier).option\(index + 1)"
            cbv.delegate = self
            optionCheckboxViews.append(cbv)
            addSubview(cbv)
            updateCheckboxStateForOptionAt(index: index, revealAnswer: !learningResponse.isConfirmRequired)
        }
        
        if learningResponse.isConfirmRequired {
            let button = UIButton()
            button.setTitle(NSLocalizedString("Confirm", tableName: "SPCLearningTrails", comment: "Confirm button title"), for: .normal)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
            button.backgroundColor = ResponseLearningBlockStyle.confirmButtonBackgroundColor
            button.setTitleColor(ResponseLearningBlockStyle.confirmButtonTitleColor, for: .normal)
            button.addTarget(self, action: #selector(onConfirmButton), for: .touchUpInside)
            button.layer.cornerRadius = 8
            button.accessibilityIdentifier = "\(learningResponse.identifier).confirm"
            addSubview(button)
            confirmButton = button
            
            let messageLabel = UILabel()
            messageLabel.font = UIFont.preferredFont(forTextStyle: .body)
            messageLabel.adjustsFontForContentSizeCategory = true
            messageLabel.textAlignment = .center
            addSubview(messageLabel)
            confirmMessageLabel = messageLabel
        }

        // Load any saved state and update checkboxes.
        if learningResponse.loadState() {
            ignoreValueChangedEvents = true
            for (index, cbv) in optionCheckboxViews.enumerated() {
                guard index < learningResponse.options.count else { break }
                cbv.isSelected = learningResponse.options[index].isSelected
                if !learningResponse.isConfirmRequired && cbv.isSelected {
                    revealFeedbackForOptionAt(index: index)
                    if !learningResponse.isConfirmRequired {
                        onOptionSelectedAt(index: index, fromUserInteraction: false)
                    }
                }
            }
            ignoreValueChangedEvents = false
            if learningResponse.isConfirmRequired && learningResponse.isConfirmed {
                onConfirmation(saveResults: false, fromUserInteraction: false)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        var y = directionalLayoutMargins.top
        var textSize = CGSize(width: bounds.width, height: 0.0)
        if promptTextView.attributedText.length > 0 {
            textSize = promptTextView.sizeThatFits(CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude))
        }
        promptTextView.frame = CGRect(x: 0, y: y, width: bounds.width, height: textSize.height)
        y = promptTextView.frame.maxY
        y += textSize.height > 0 ? padding : 0

        let x = promptTextView.textContainer.lineFragmentPadding // Line up with start of prompt text.
        let availableWidth = bounds.width - x
        
        for cbv in optionCheckboxViews {
            let h = cbv.sizeThatFits(CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)).height
            cbv.frame = CGRect(x: x, y: y, width: availableWidth, height: h)
            y += h
            y += (cbv != optionCheckboxViews.last) ? padding : 0.0
        }
        
        if let button = confirmButton {
            y += padding
            var buttonSize = button.sizeThatFits(CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude))
            buttonSize.width *= 1.5
            buttonSize.height = max(confirmButtonHeight, buttonSize.height)
            button.frame = CGRect(x: x, y: y, width: buttonSize.width, height: buttonSize.height)
            if let messageLabel = confirmMessageLabel {
                messageLabel.frame = CGRect(x: button.frame.maxX + 20, y: y, width: bounds.width - button.frame.size.width - 20, height: buttonSize.height)
            }
        }
    }
    
    // MARK: Actions

    @objc
    func onConfirmButton(_ button: UIButton) {
        onConfirmation(saveResults: true, fromUserInteraction: true)
    }
    
    // MARK: Private
    
    private func revealFeedbackForOptionAt(index: Int) {
        guard let learningResponse = learningResponse, index < learningResponse.options.count  else { return }
        let option = learningResponse.options[index]
        let checkboxButtonView = optionCheckboxViews[index]
        if option.hasFeedback {
            checkboxButtonView.isFeedbackVisible = true
        }
        checkboxButtonView.isSelected = true
        
        // Once an option has been selected and feedback revealed, it can no longer be changed.
        checkboxButtonView.isEnabled = false

        delegate?.responseBlockView(self, didRevealFeedbackForOption: index)
    }

    private func updateCheckboxStateForOptionAt(index: Int, revealAnswer: Bool) {
        guard let learningResponse = learningResponse, index < learningResponse.options.count  else { return }
        let option = learningResponse.options[index]
        let checkboxButtonView = optionCheckboxViews[index]
        
        switch option.type {
        case .unspecified:
            checkboxButtonView.stateForSelected = .chosen
        case .correct:
            checkboxButtonView.stateForSelected = revealAnswer ? .correct : .chosen
        case .wrong:
            checkboxButtonView.stateForSelected = revealAnswer ? .wrong : .chosen
        }
    }
    
    private func setMessage(text: String) {
        guard let textStyle = textStyle else { return }
        confirmMessageLabel?.attributedText = NSAttributedString(xml: "<text><message>\(text)</message></text>", style: textStyle)
    }

    // Assess the user response and display feedback after an option is selected.
    private func onOptionSelectedAt(index: Int, fromUserInteraction: Bool) {
        guard let learningResponse = learningResponse, !learningResponse.isConfirmRequired else { return }
        
        // Reveal the feedback for the selected option.
        revealFeedbackForOptionAt(index: index)
        
        if learningResponse.isAnsweredCorrectly {
            // Disable the checkboxes.
            optionCheckboxViews.forEach( { $0.isEnabled = false })
        }
        
        if fromUserInteraction {
            onResponseSubmitted(learningResponse: learningResponse)
        }
    }

    // Assess the user response and display feedback after the confirm button is pressed.
    private func onConfirmation(saveResults: Bool, fromUserInteraction: Bool) {
        guard let confirmButton = confirmButton, let learningResponse = learningResponse, learningResponse.isConfirmRequired else { return }
        
        learningResponse.isConfirmed = true
        
        let isAnsweredCorrectly = learningResponse.isAnsweredCorrectly
        
        for (index, option) in learningResponse.options.enumerated() {
            
            if learningResponse.responseType == .singlechoice {
                if isAnsweredCorrectly && option.isSelectedAndCorrect {
                    updateCheckboxStateForOptionAt(index: index, revealAnswer: true)
                    revealFeedbackForOptionAt(index: index)
                } else {
                    if option.isSelectedAndWrong {
                        // Reveal responses for any wrong answers that have been selected.
                        updateCheckboxStateForOptionAt(index: index, revealAnswer: true)
                        revealFeedbackForOptionAt(index: index)
                    }
                }
            } else if learningResponse.responseType == .multiplechoice {
                if option.isSelected {
                    // Reveal responses for any answers that have been selected.
                    updateCheckboxStateForOptionAt(index: index, revealAnswer: true)
                    revealFeedbackForOptionAt(index: index)
                }
            }
        }
        
        if isAnsweredCorrectly {
            // Disable all the checkboxes.
            optionCheckboxViews.forEach( { $0.isEnabled = false })

            setMessage(text: NSLocalizedString("Well Done!", tableName: "SPCLearningTrails", comment: "Confirm button success"))
            confirmButton.setTitleColor(ResponseLearningBlockStyle.confirmButtonTitleColorCorrect, for: .disabled)
            confirmButton.backgroundColor = ResponseLearningBlockStyle.confirmButtonDisabledBackgroundColor
            confirmButton.isEnabled = false
        } else {
            if learningResponse.responseType == .singlechoice {
                setMessage(text: NSLocalizedString("Try Again!", tableName: "SPCLearningTrails", comment: "Confirm button try again"))
            } else if learningResponse.responseType == .multiplechoice {
                setMessage(text: NSLocalizedString("Keep Going!", tableName: "SPCLearningTrails", comment: "Confirm button keep going"))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.setMessage(text: "")
            }
        }
        
        if fromUserInteraction {
            learningResponse.saveState()
            onResponseSubmitted(learningResponse: learningResponse)
        }
    }
    
    // Called whenever the user has entered a response.
    // If confirm is not required, this is called immediately they choose an option
    // If confirm is required, this is called after the confirm button is pressed.
    private func onResponseSubmitted(learningResponse: LearningResponse) {
        
        // Notify delegate.
        DispatchQueue.main.async {
            self.delegate?.responseBlockView(self, didSubmitResponseFor: learningResponse)
        }
    }
}

// MARK: ResponseOptionContainerDelegate
extension ResponseLearningBlockView: ResponseOptionContainerDelegate {

    func didPickResponseOption(_ sender: ResponseOptionContainer) {
        guard
            !ignoreValueChangedEvents,
            let learningResponse = learningResponse,
            let checkboxView = sender as? ResponseOptionCheckboxView,
            let index = optionCheckboxViews.firstIndex(of: checkboxView)
            else { return }
                
        learningResponse.options[index].isSelected = sender.isSelected
        
        // Unselect other options if single choice.
        if learningResponse.responseType == .singlechoice {
            if checkboxView.isSelected {
                for (index, cbv) in optionCheckboxViews.enumerated() {
                    if cbv != checkboxView && cbv.isEnabled {
                        cbv.isSelected = false
                        learningResponse.options[index].isSelected = false
                    }
                }
            }
        }
        
        learningResponse.saveState()
        
        delegate?.responseBlockView(self, didSelectOption: index)
        
        if !learningResponse.isConfirmRequired {
            onOptionSelectedAt(index: index, fromUserInteraction: true)
        }

    }
    
    func didTapLink(_ container: ResponseOptionContainer, url: URL, linkRect: CGRect) {
        delegate?.didTapLink(blockView: self, url: url, linkRect: linkRect)
    }
}

// MARK: LTTextViewDelegate
extension ResponseLearningBlockView: LTTextViewDelegate {
    
    public func didTapLink(_ ltTextView: LTTextView, url: URL, linkRect: CGRect) {
        delegate?.didTapLink(blockView: self, url: url, linkRect: linkRect)
    }
}

// MARK: LearningBlockViewable
extension ResponseLearningBlockView: LearningBlockViewable {
    func load(learningBlock: LearningBlock, style: LearningBlockStyle, textStyle: AttributedStringStyle? = TextAttributedStringStyle.shared) {
        self.learningBlock = learningBlock
        self.style = style
        self.textStyle = textStyle
        
        defer { self.setNeedsLayout() }
        
        directionalLayoutMargins = style.margins
        backgroundColor = style.backgroundColor
        
        let xmlContent = learningBlock.xmlPackagedContent(.linesLeftTrimmed)

        guard let textStyle = textStyle else { return }
        guard let learningResponse = LearningResponse(identifier: learningBlock.accessibilityIdentifier, xml: xmlContent, attributes: learningBlock.attributes) else { return }
        load(learningResponse: learningResponse, style: style, textStyle: textStyle)
    }
}
