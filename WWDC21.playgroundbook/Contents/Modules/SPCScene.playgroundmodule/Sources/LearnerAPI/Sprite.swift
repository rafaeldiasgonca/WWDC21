//
//  Sprite.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import SpriteKit
import SPCCore

/// A Sprite is a type of graphic object, made from an image or a shape, that can be placed on the scene.
/// - localizationKey: Sprite
open class Sprite: BaseGraphic, AudioPlaying, ImageProtocol, TextProtocol, ShapeProtocol, Scaleable, Actionable, Emittable, Physicable, Collidable, TouchInteractable  {
    static var defaultNameCount = 1
    
    public var velocity: Vector = Vector(dx: 0.0, dy: 0.0)
    public var rotationalVelocity: Double = 0.0
    
    public init(image: Image, name: String) {
        super.init()
        self.graphicType = .sprite
        self.name = name
        self.image = image
    }
    
    public init(graphicType: GraphicType, name: String) {
        super.init()
        self.graphicType = graphicType
        self.name = name
    }
    
    /// Creates a tiled Sprite with a specified image, name, and number of columns and rows.
    /// Example usage:
    /// ````
    /// let wall = Sprite(image: #imageLiteral(resourceName: \"wall1.png\"), name: \"wall\", columns: \"12\", rows: \"1\")
    /// ````
    /// - Parameter image: An image you choose for the Sprite.
    /// - Parameter name: A name you give to the Sprite.
    /// - Parameter columns: How many columns of sprites you want.
    /// - Parameter rows: How many rows of sprites you want.
    /// - Parameter isDynamic: An optional Boolean value that indicates if the Sprite should move in response to the physics simulation. The default is `false` (the sprite won’t move).
    ///
    /// - localizationKey: Sprite(image:name:columns:rows:isDynamic:)
    public convenience init(image: Image, columns: Int, rows: Int, isDynamic: Bool = false, name: String = "") {
        if name == "" {
            self.init(graphicType: .sprite, name: "surface" + String(Sprite.defaultNameCount))
            Sprite.defaultNameCount += 1
        } else {
            self.init(graphicType: .sprite, name: name)
        }

        self.image = image
        setTiledImage(image: image, columns: columns, rows: rows, isDynamic: isDynamic)

    }
    
    public convenience init (shape: BaseShape, color: Color, colors: [Color]?, name: String = "") {
        if name == "" {
            self.init(graphicType: .sprite, name: "sprite" + String(Sprite.defaultNameCount))
            Sprite.defaultNameCount += 1
        } else {
            self.init(graphicType: .sprite, name: name)
        }
        
        updateShape(shape: shape, color: color, colors: colors)
        
        updateSize()
    }
    
    public class func circle(radius: Int, color: Color, colors: [Color]? = nil) -> Sprite {
        return Sprite(shape: CircleShape(radius: radius), color: color, colors: colors)
    }
    
    public class func rectangle(width: Int, height: Int, cornerRadius: Double, color: Color, colors: [Color]? = nil) -> Sprite {
        return Sprite(shape: RectangleShape(width: width, height: height, cornerRadius: cornerRadius), color: color, colors: colors)
    }
    
    public class func polygon(radius: Int, sides: Int, color: Color, colors: [Color]? = nil) -> Sprite {
        return Sprite(shape: PolygonShape(radius: radius, sides: sides), color: color, colors: colors)
    }
    
    public class func star(radius: Int, points: Int, sharpness: Double, color: Color, colors: [Color]? = nil) -> Sprite {
        return Sprite(shape: StarShape(radius: radius, points: points, sharpness: sharpness), color: color, colors: colors)
    }
    
    public class func customShape(path: CGPath, color: Color, colors: [Color]? = nil) -> Sprite {
        return Sprite(shape: BaseShape(path: path), color: color, colors: colors)
    }
    
    public var allowsRotation: Bool = false {
        didSet{
            setAllowsRotation(rotation: allowsRotation)
        }
    }
    
    public var isAffectedByGravity: Bool = false {
        didSet {
            setAffectedByGravity(gravity: isAffectedByGravity)
        }
    }
    
    public func setVelocity(x: Double, y: Double) {
        setVelocity(velocity: CGVector(dx: x, dy: y))
    }
    
    public func applyImpulse(x: Double, y: Double) {
        applyImpulse(vector: CGVector(dx: x, dy: y))
    }
    
    func updateMotionState(from newSprite: Sprite) {
        assert(newSprite.id == self.id, "*** You can only update using a sprite instance with a matching ID.")
        
        self.suppressMessageSending = true
        
        self.position = newSprite.position
        self.velocity = newSprite.velocity
        self.rotationalVelocity = newSprite.rotationalVelocity
        
        self.suppressMessageSending = false
    }
    
    public func setOnTouchHandler(_ handler: @escaping (Touch)->Void) {
        allowsTouchInteraction = true 
        setHandler(for: .touch, handler: handler)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
