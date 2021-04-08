//
//  LTTextView.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

public protocol LTTextViewDelegate {
    func didTapLink(_ ltTextView: LTTextView, url: URL, linkRect: CGRect)
}

public class LTTextView: UITextView {

    var ltTextViewDelegate: LTTextViewDelegate?
        
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        backgroundColor = UIColor.systemBackgroundLT
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        isEditable = false
        isSelectable = true
        isScrollEnabled = false
        dataDetectorTypes = .link
        linkTextAttributes = [:]
        delaysContentTouches = false
        adjustsFontForContentSizeCategory = true
        
        isAccessibilityElement = true
        accessibilityTraits = .staticText

        delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer is UILongPressGestureRecognizer {
            gestureRecognizer.isEnabled = false
        }
        if let tapGestureRecognizer = gestureRecognizer as? UITapGestureRecognizer {
            tapGestureRecognizer.numberOfTapsRequired = 1
        }
        super.addGestureRecognizer(gestureRecognizer)
    }
    
    private func boundingRectForCharacterRange(_ range: NSRange) -> CGRect? {
        var glyphRange = NSRange()
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
}

extension LTTextView: UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let rangeBounds = boundingRectForCharacterRange(characterRange) ?? CGRect.zero
        let absoluteRect = textView.convert(rangeBounds, to: nil)
        ltTextViewDelegate?.didTapLink(self, url: URL, linkRect: absoluteRect)
        return false
    }
}

