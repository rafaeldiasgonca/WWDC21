//
//  GroupAttributedStringStyle.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

public struct GroupAttributedStringStyle: AttributedStringStyle {
    
    private var groupTitleAttributes: [NSAttributedString.Key: Any] {
        return [
            .font : UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor : tintColor
        ]
    }
    
    // MARK: Public
    
    public static var shared: AttributedStringStyle = GroupAttributedStringStyle()
    
    public var fontSize: CGFloat = TextAttributedStringStyle.defaultSize
    
    public var tintColor: UIColor = UIColor.red
    
    public var attributes: [String : [NSAttributedString.Key : Any]] {
        var styleAttributes = TextWithCodeAttributedStringStyle.shared.attributes
        if let textAttributes = styleAttributes["text"] {
            styleAttributes["cv"]?.removeValue(forKey: .foregroundColor)
            styleAttributes["title"] = textAttributes.merging(groupTitleAttributes, uniquingKeysWith: { (_, new) in new })
        }
        return styleAttributes
    }
}
