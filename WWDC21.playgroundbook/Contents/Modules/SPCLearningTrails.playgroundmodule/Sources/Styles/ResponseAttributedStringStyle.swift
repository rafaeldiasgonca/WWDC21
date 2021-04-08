//
//  ResponseAttributedStringStyle.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

public struct ResponseAttributedStringStyle: AttributedStringStyle {
    
    private var correctResponseAttributes: [NSAttributedString.Key: Any] {
        return [
            .foregroundColor: #colorLiteral(red: 0.003921568627, green: 0.7215686275, blue: 0.003921568627, alpha: 1)
        ]
    }
    
    private var wrongResponseAttributes: [NSAttributedString.Key: Any] {
        return [
            .foregroundColor: #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
        ]
    }
    
    private var messageAttributes: [NSAttributedString.Key: Any] {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let boldDescriptor = descriptor.withSymbolicTraits(.traitBold)!
        let sizeDescriptor = boldDescriptor.withSize(19)
        let font = UIFont(descriptor: sizeDescriptor, size: 0.0)
        return [
            .font : UIFontMetrics.default.scaledFont(for: font),
            .foregroundColor: UIColor.mainTextColorLT.withAlphaComponent(0.7)
        ]
    }
    
    // MARK: Public
    
    public static var shared: AttributedStringStyle = ResponseAttributedStringStyle()
    
    public var fontSize: CGFloat = TextAttributedStringStyle.defaultSize
    
    public var tintColor: UIColor = UIColor.red
    
    public var attributes: [String : [NSAttributedString.Key : Any]] {
        var styleAttributes = TextWithCodeAttributedStringStyle.shared.attributes
        styleAttributes["cv"]?.removeValue(forKey: .foregroundColor)
        // Add additional style tags.
        styleAttributes["correct"] = correctResponseAttributes
        styleAttributes["wrong"] = wrongResponseAttributes
        // A spacer paragraph is used between option and correct/wrong feedback.
        if let ps = styleAttributes["text"]?[.paragraphStyle] as? NSParagraphStyle {
            let psModified = NSMutableParagraphStyle()
            psModified.setParagraphStyle(ps)
            psModified.lineHeightMultiple = 0.4
            styleAttributes["spacer"] = styleAttributes["text"]
            styleAttributes["spacer"]?[.paragraphStyle] = psModified
        }
        styleAttributes["message"] = messageAttributes
        return styleAttributes
    }
}

