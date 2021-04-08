//
//  Label.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import SPCCore

/// A Label is a type of Graphic that displays text. The Label's color, name, font, and size can be customized.
/// - localizationKey: Label
open class Label: BaseGraphic, TextProtocol, Actionable, Emittable {
    fileprivate static var defaultNameCount = 1
    
    /// Creates a Label with a specified text, color, name, font, and size.
    /// Example usage:
    /// ```
    /// var scoreLabel = Label(text:\"SCORE: 0\", color: .black, name: \"score\", font: Font.Menlo, size: 70)
    /// ```
    /// - Parameter text: The text displayed on the label.
    /// - Parameter color: The color of the text.
    /// - Parameter name: A name you give to the label.
    /// - Parameter font: The font you choose for the text.
    /// - Parameter size: The size of the text.
    ///
    /// - localizationKey: Label(text:color:name:font:size:)
    public init(text: String, color: Color, font: Font = Font.SystemFontRegular, size: Int = 30, name: String = "") {
        super.init()
        graphicType = .label
        
        if name == "" {
            self.name = "label" + String(Label.defaultNameCount)
            Label.defaultNameCount += 1
        } else {
            self.name = name
        }
        self.textColor = color
        self.text = text
        self.fontSize = size
        self.fontName = font.rawValue
    }
    
    public var font: Font = .SystemFontRegular {
        didSet {
            fontName = font.rawValue
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
