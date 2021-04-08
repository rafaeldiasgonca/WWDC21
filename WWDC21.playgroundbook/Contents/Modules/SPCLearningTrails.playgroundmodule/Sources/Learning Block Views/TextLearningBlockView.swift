//
//  TextLearningBlockView.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

public class TextLearningBlockView: LTTextView {
    public var learningBlock: LearningBlock?
    public var style: LearningBlockStyle?
    public var textStyle: AttributedStringStyle?
    
    public var blockViewDelegate: LearningBlockViewDelegate?
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        ltTextViewDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TextLearningBlockView: LTTextViewDelegate {
    
    public func didTapLink(_ ltTextView: LTTextView, url: URL, linkRect: CGRect) {
        blockViewDelegate?.didTapLink(blockView: self, url: url, linkRect: linkRect)
    }
}

extension TextLearningBlockView: LearningBlockViewable {
    
    public func load(learningBlock: LearningBlock, style: LearningBlockStyle, textStyle: AttributedStringStyle? = TextAttributedStringStyle.shared) {
        self.learningBlock = learningBlock
        self.style = style
        self.textStyle = textStyle
        
        accessibilityIdentifier = learningBlock.accessibilityIdentifier

        backgroundColor = style.backgroundColor
        directionalLayoutMargins = style.margins
        textContainerInset = layoutMargins
        
        let xmlContent = learningBlock.content.linesLeftTrimmed()
        
        guard let textStyle = textStyle else { return }
        self.attributedText = NSAttributedString(xml: xmlContent, style: textStyle)
        
        self.setNeedsLayout()
    }
}

