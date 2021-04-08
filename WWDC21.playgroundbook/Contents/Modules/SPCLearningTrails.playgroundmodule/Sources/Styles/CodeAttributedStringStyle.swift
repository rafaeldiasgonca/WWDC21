//
//  CodeAttributedStringStyle.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

public struct CodeAttributedStringStyle: AttributedStringStyle {
    
    public static let defaultSize: CGFloat = 14
    
    public static let indentInset: CGFloat = 20.0
    public static let wrapInset: CGFloat = 10.0
    
    public static let codeFontName = "SFMono-Regular"
    public static let codeFontExtension = FontFileExtension.otf
    
    public static let CodeAttribute = NSAttributedString.Key("CodeAttribute.Key")
        
    private var paragraphStyle: NSMutableParagraphStyle {
        let ps = NSMutableParagraphStyle()
        ps.headIndent = CodeAttributedStringStyle.wrapInset
        ps.lineHeightMultiple = 1.25
        ps.alignment = .left
        return ps
    }
    
    private var codeFont: UIFont {
        return UIFont(name: CodeAttributedStringStyle.codeFontName, size: fontSize) ?? UIFont(name: "Menlo", size: fontSize)!
    }
    
    private var codeAttributes: [NSAttributedString.Key: Any] {
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        return [
            .font : fontMetrics.scaledFont(for: codeFont),
            .foregroundColor : UIColor.mainTextColorLT,
            .paragraphStyle : paragraphStyle,
            CodeAttributedStringStyle.CodeAttribute : true // Custom attribute to mark <code>.
        ]
    }
    
    private var keywordAttributes: [NSAttributedString.Key: Any] {
        return [
            .foregroundColor : UIColor.keywordLT
        ]
    }

    private var stringAttributes: [NSAttributedString.Key: Any] {
        return [
            .foregroundColor : UIColor.stringLT
        ]
    }
    
    private var numberAttributes: [NSAttributedString.Key: Any] {
        return [
            .foregroundColor : UIColor.numberLT
        ]
    }
    
    private var typeAttributes: [NSAttributedString.Key: Any] {
        return [
            .foregroundColor : UIColor.typeLT
        ]
    }
    
    private var commentAttributes: [NSAttributedString.Key: Any] {
        return [
            .foregroundColor : UIColor.codeCommentLT
        ]
    }
    
    private var literalAttributes: [NSAttributedString.Key: Any] {
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        return [
            .font : fontMetrics.scaledFont(for: codeFont)
        ]
    }
    
    private var placeholderAttributes: [NSAttributedString.Key: Any] {
        return [
            .backgroundColor : UIColor(red: 220.0/255.0, green: 220.0/255.0, blue: 220.0/255.0, alpha: 1.0),
            .foregroundColor : UIColor(red: 128.0/255.0, green: 128.0/255.0, blue: 128.0/255.0, alpha: 1.0),
        ]
    }
    
    private var strikethroughAttributes: [NSAttributedString.Key: Any] {
        return [
            .strikethroughStyle : NSUnderlineStyle.single.rawValue
        ]
    }
    
    // MARK: Public
    
    public static var shared: AttributedStringStyle = CodeAttributedStringStyle()
    
    public var fontSize: CGFloat = CodeAttributedStringStyle.defaultSize
    
    public var tintColor: UIColor = UIColor.red

    public var attributes: [String : [NSAttributedString.Key: Any]] {
        return [
            "code" : codeAttributes,
            "key" : keywordAttributes,
            "str": stringAttributes,
            "num": numberAttributes,
            "type" : typeAttributes,
            // <cmt> needs to be able to stand on its own.
            "cmt": codeAttributes.merging(commentAttributes, uniquingKeysWith: { (_, new) in new }),
            "literal": literalAttributes,
            "placeholder": placeholderAttributes
        ]
    }

    public init(fontSize: CGFloat = CodeAttributedStringStyle.defaultSize) {
        self.fontSize = fontSize
    }
}
