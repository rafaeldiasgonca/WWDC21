//
//  Button.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import SPCCore
import SpriteKit

public class Button: BaseGraphic, TextProtocol, Actionable, ImageProtocol, TouchInteractable {
    
    /// An enumeration of the different button shapes: red or green.
    ///
    /// - localizationKey: ButtonType
    public enum ButtonType {
        
        /// Red is one of the buttons you can choose from.
        ///
        /// - localizationKey: ButtonType.red
        case red
        
        /// Green is one of the buttons you can choose from.
        ///
        /// - localizationKey: ButtonType.green
        case green
        
        /// Rectangular red is one of the buttons you can choose from.
        ///
        /// - localizationKey: ButtonType.rectangularRed
        case rectangularRed
    }
    
    var buttonType: ButtonType
    public var font: Font = .SystemFontRegular {
        didSet {
            fontName = font.rawValue
        }
    }
    
    fileprivate static var defaultNameCount = 1
    
    /// Creates a Button with a ButtonType, text, and name.
    /// Example usage:
    ///
    /// `let restart = Button(type: .red, text: \"Try Again\", name: \"restart\")`
    ///
    /// - Parameter type: ButtonType, red or green.
    /// - Parameter text: Any text you want displayed on the button.
    /// - Parameter name: A name associated with the button.
    ///
    /// - localizationKey: Button(type:text:name:)
    public init(type: ButtonType, text: String = "", name: String = "") {
        
        buttonType = type
        super.init()
        var image: Image = Image(imageLiteralResourceName: "button")
        
        if name == "" {
            self.name = "button" + String(Button.defaultNameCount)
            Button.defaultNameCount += 1
        } else {
            self.name = name
        }
        self.graphicType = .button
        self.text = text
        self.fontSize = 20
        self.fontName = font.rawValue
        self.textColor = Color.systemBlue
        
        switch type {
        case .red:
                image = Image(imageLiteralResourceName: "button_red")
        case .green:
                image = Image(imageLiteralResourceName: "button_green")
        case .rectangularRed:
                image = Image(imageLiteralResourceName: "button_redRectangular")
        }
        setImage(image: image)
        
        allowsTouchInteraction = true
        commonInit()
    }
    
    /*
     For some reason if a button has an image and text in it without this call you can only get the image or the text. Calling this gets both
     */
    private func commonInit() {
        let dummy = self.textColor
        self.textColor = dummy
    }
    
    public func setOnPressHandler(_ handler: @escaping ((Touch) -> Void)) {
        setHandler(for: .touch, handler: handler)
    }
    
    public func setTexture() {
        DispatchQueue.main.async {
            self.texture = SKTexture(image: Image(imageLiteralResourceName: "button_green").uiImage)
        }
    }
    
    func buttonPressAnimation(duration: Double) {
        if let originalTexture = self.texture,
            let highlightTexture = self.buttonHighlightTexture {
            let textures = [highlightTexture, originalTexture]
            let press = SKAction.animate(with: textures, timePerFrame: duration)
            
            self.run(press)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
