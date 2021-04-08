//
//  TextAttributedStringStyle.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

public struct TextAttributedStringStyle: AttributedStringStyle {
    
    public static let defaultSize: CGFloat = 17
    
    public struct Key {
        // Name of the attribute
        static let linkAttribute = NSAttributedString.Key(rawValue: "link-attribute")
        static let linkScheme = NSAttributedString.Key(rawValue: "link-scheme")
    }
    
    public init() { }
    
    public static let iconFontName = "SPCIcons"
    public static let iconFontExtension = FontFileExtension.ttf
    
    private var paragraphStyle: NSMutableParagraphStyle {
        let ps = NSMutableParagraphStyle()
        ps.lineHeightMultiple = 1.0
        ps.alignment = .left
        return ps
    }
    
    private var codeFont: UIFont {
        return UIFont(name: CodeAttributedStringStyle.codeFontName, size: fontSize) ?? UIFont(name: "Menlo", size: fontSize)!
    }
    
    private var titleAttributes: [NSAttributedString.Key: Any] {
        let traits = [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title3)
        let boldDescriptor = descriptor.addingAttributes([UIFontDescriptor.AttributeName.traits: traits])
        let sizeDescriptor = boldDescriptor.withSize(24)
        let font = UIFont(descriptor: sizeDescriptor, size: 0.0)
        return [
            .font : UIFontMetrics.default.scaledFont(for: font),
            .foregroundColor : UIColor.mainTextColorLT,
            .paragraphStyle : paragraphStyle
        ]
    }
    
    private var groupTitleAttributes: [NSAttributedString.Key: Any] {
        return [
            .font : UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor : tintColor,
            .paragraphStyle : paragraphStyle
        ]
    }

    private var textAttributes: [NSAttributedString.Key: Any] {
        return [
            .font : UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor : UIColor.mainTextColorLT,
            .paragraphStyle : paragraphStyle
        ]
    }
    
    private var taskAttributes: [NSAttributedString.Key: Any] {
        return [
            .font : UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor : UIColor.mainTextColorLT,
            .paragraphStyle : paragraphStyle
        ]
    }
    
    private var iconAttributes: [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : UIColor.mainTextColorLT,
            .paragraphStyle : paragraphStyle
        ]
        if let font = UIFont(name: TextAttributedStringStyle.iconFontName, size: TextAttributedStringStyle.defaultSize) {
            attributes[.font] = font
        }
        return attributes
    }
    
    private var codeVoiceAttributes: [NSAttributedString.Key: Any] {
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        return [
            .font : fontMetrics.scaledFont(for: codeFont),
            .foregroundColor : UIColor.codeVoiceLT,
            .paragraphStyle : paragraphStyle
        ]
    }
    
    private var boldAttributes: [NSAttributedString.Key: Any] {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let boldDescriptor = descriptor.withSymbolicTraits(.traitBold)!
        let font = UIFont(descriptor: boldDescriptor, size: 0.0)
        return [
            .font : UIFontMetrics.default.scaledFont(for: font)
        ]
    }
    
    private var italicAttributes: [NSAttributedString.Key: Any] {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let italicDescriptor = descriptor.withSymbolicTraits(.traitItalic)!
        let font = UIFont(descriptor: italicDescriptor, size: 0.0)
        return [
            .font : UIFontMetrics.default.scaledFont(for: font)
        ]
    }
    
    private var linkAttributes: [NSAttributedString.Key: Any] {
        return [
            .foregroundColor : tintColor,
            Key.linkAttribute : "href"
        ]
    }
    
    private var rightAlignedAttributes: [NSAttributedString.Key: Any] {
        let ps = paragraphStyle
        ps.alignment = .right
        return [
            .paragraphStyle : ps
        ]
    }
    
    private var centerAlignedAttributes: [NSAttributedString.Key: Any] {
        let ps = paragraphStyle
        ps.alignment = .center
        return [
            .paragraphStyle : ps
        ]
    }
    
    private var commentAttributes: [NSAttributedString.Key: Any] {
        let ps = paragraphStyle
        ps.paragraphSpacingBefore = 5
        return [
            .foregroundColor : UIColor.codeCommentLT,
            .paragraphStyle: ps
        ]
    }
    
    
    private var strikethroughAttributes: [NSAttributedString.Key: Any] {
        return [
            .strikethroughStyle : NSUnderlineStyle.single.rawValue
        ]
    }
    
    // MARK: Public
    
    public static var shared: AttributedStringStyle = TextAttributedStringStyle()
    
    public var fontSize: CGFloat = TextAttributedStringStyle.defaultSize
    
    public var tintColor: UIColor = UIColor.red

    public var attributes: [String : [NSAttributedString.Key: Any]] {
        return [
            "title" : titleAttributes,
            "text" : textAttributes,
            "cv" : codeVoiceAttributes,
            "a" : linkAttributes,
            "b" : boldAttributes,
            "i": italicAttributes,
            "right": rightAlignedAttributes,
            "center": centerAlignedAttributes,
            "cmt": codeVoiceAttributes.merging(commentAttributes, uniquingKeysWith: { (_, new) in new }),
            "st": strikethroughAttributes,
            "task" : taskAttributes,
            "icon" : iconAttributes
        ]
    }
}

/// A text style that combines <text> and <code> styles.
/// It allows a <code> block to be used inside a <text> block.
public struct TextWithCodeAttributedStringStyle: AttributedStringStyle {
    
    // MARK: Public
    public static var shared: AttributedStringStyle = TextWithCodeAttributedStringStyle()
    
    public var fontSize: CGFloat = TextAttributedStringStyle.defaultSize
    
    public var tintColor: UIColor = UIColor.red
       
    // Modifies text attributes.
    public var attributes: [String : [NSAttributedString.Key : Any]] {
        let textAttributes = TextAttributedStringStyle.shared.attributes
        let codeFontSize = TextAttributedStringStyle.shared.fontSize - 2.0
        let codeAttributes = CodeAttributedStringStyle(fontSize: codeFontSize).attributes
        var mergedAttributes = textAttributes.merging(codeAttributes, uniquingKeysWith: { (_, new) in new })
        // <cv> inherits <code> attributes except for:
        //   - foreground color is same as text
        //   - paragraphStyle  is same as text
        if var cvAttributes = codeAttributes["code"] {
            cvAttributes[.foregroundColor] = textAttributes["cv"]?[.foregroundColor]
            cvAttributes[.paragraphStyle] = textAttributes["text"]?[.paragraphStyle]
            mergedAttributes["cv"] = cvAttributes
        }
        return mergedAttributes
    }
}

