//
//  BaseGraphic.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//


import Foundation
import UIKit
import SPCCore
import SPCAccessibility
import SpriteKit

open class BaseGraphic: InternalGraphic {
    
    var _scene: Scene?
    
    fileprivate static var defaultNameCount = 1
    
    public var location: Point {
        didSet {
            self.position = CGPoint(location)
        }
    }
    
    public var suppressMessageSending: Bool = false
            
    /// The scale of the Graphic’s size, where `1.0` is normal, `0.5` is half the normal size, and `2.0` is twice the normal size.
    ///
    /// - localizationKey: Graphic.scale
    public var scale: Double  = 1.0 {
        
        didSet {
            setXScale(scale: scale)
            setYScale(scale: scale)
                        
            self.run(SKAction.scale(to: CGFloat(scale), duration: 0))
        }
    }
    
    /// The angle, in degrees, to rotate the graphic. Changing the angle rotates the graphic counterclockwise around its center. A value of `0.0` (the default) means no rotation. A value of `180.0` rotates the object 180 degrees.
    ///
    /// - localizationKey: Graphic.rotation
    public var rotation: Double {
        get {
            return Double(rotationRadians / CGFloat.pi) * 180.0
        }
        set(newRotation) {
            rotationRadians = (CGFloat(newRotation) / 180.0) * CGFloat.pi
        }
    }
    
    override init() {
        self.location = Point(x: 0, y: 0)

        super.init()
        name = id
    }
    
    public init(name: String = "") {
        self.location = Point(x: 0, y: 0)

        super.init()
        self.name = name
    }
    
    /// Creates a Graphic with the given identifier; for example, reconstructing a graphic.
    ///
    /// - Parameter id: The identifier associated with the Graphic.
    /// - Parameter graphicType: The graphic type associated with the Graphic.
    /// - Parameter name: The name associated with the Graphic.
    ///
    /// - localizationKey: Graphic(id:name:graphicType:)
    public init(id: String, name: String = "") {
        self.location = Point(x: 0, y: 0)
        super.init()
        self.name = name
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var tintTexture: SKTexture? {
        guard let image = self.image else { return nil }
        var tintTexture: SKTexture? = nil
        
        if let tintColor = tintColor, let uiImage = UIImage(named: image.path), let tintImage = uiImage.colorize(color: tintColor, blend: CGFloat(tintColorBlend)) {
            tintTexture = SKTexture(image: tintImage)
        }
        
        return tintTexture
    }
    
    private var tintColor: UIColor? = nil
    private var tintColorBlend: Double = 0.5

    /// Sets the Graphic tint color.
    ///
    /// - Parameter color: The color with which the Graphic is tinted.
    /// - Parameter blend: The degree to which the color is blended with the Graphic image from 0.0 to 1.0. The default is '0.5'.
    ///
    /// - localizationKey: Graphic.setTintColor(color:blend:)
    public func setTintColor(_ color: UIColor?, blend: Double = 0.5) {
        tintColor = color
        tintColorBlend = blend
        
        if blend > 0.0 && tintColor != nil {
            guard let tintTexture = tintTexture else { return }
            
            self.texture = tintTexture
        } else {
            applyImage()
        }

    }
    
    /// Changes the graphic image to the desired color.
    ///
    /// - Parameter color: The color applied to the image.
    ///
    /// - localizationKey: Graphic.setImageColor(to:)
    public func setImageColor(to color: Color) {
        if image != nil {
            self.image = self.image?.tinted(with: color)
        }
    }
    
    public func remove() {
        _scene?.removeGraphic(id: self.id)
    }
    
    public func makeAccessible(label: String, customLabel: Bool = false, select: Bool = false) {
        accessibilityHints = AccessibilityHints(makeAccessibilityElement: true, usesCustomAccessibilityLabel: customLabel, accessibilityLabel: label, selectImmediately: select, needsUpdatedValue: select)
    }
}
