//
//  Joint.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import SPCCore
import SPCIPC
import SpriteKit

/// A joint, used to connect two sprites (or one sprite with the scene).
///
/// - localizationKey: Joint
public class Joint {
    fileprivate static var defaultNameCount = 0
    
    /// The name of the joint.
    ///
    /// - localizationKey: Joint.name
    public var name: String
    
    /// An id, used to identify a Joint. Read-only.
    ///
    /// - localizationKey: Joint.id
    public let id = UUID().uuidString
        
        
    fileprivate init(name: String, from firstSprite: Sprite, to secondSprite: Sprite?) {
        if name.isEmpty {
            Joint.defaultNameCount += 1
            self.name = "\(type(of:self))\(Joint.defaultNameCount)"
        }
        else {
            self.name = name
        }
    }
    
    /// Creates a joint that fuses two sprites together at a reference point.
    ///
    /// - parameter name: The joint’s name. If this is empty, the system assigns a name.
    /// - parameter firstSprite: The first sprite.
    /// - parameter secondSprite: The second sprite. If this value is `nil`, the system attaches `firstSprite` to the scene.
    /// - parameter anchor: The location of the connection between the two sprites.
    ///
    /// - localizationKey: Joint.fixed(name:from:to:at:)
    public static func fixed(from firstSprite: Sprite, to secondSprite: Sprite, at anchor: Point) -> FixedJoint {
        guard let bodyA = firstSprite.physicsBody, let bodyB = secondSprite.physicsBody, let parentNode = firstSprite.parent, let scene = parentNode.parent else { return SKPhysicsJointFixed() }
        
        // Places the anchor point relative to scene's coordinate system.
        let anchorPointInParent = scene.convert(anchor.cgPoint, from: parentNode)
        let joint = SKPhysicsJointFixed.joint(withBodyA: bodyA, bodyB: bodyB, anchor: anchorPointInParent)
        
        return joint
    }
    
    /// Creates a joint that imposes a maximum distance between two sprites, as if they were connected by a rope.
    ///
    /// - parameter name: The joint’s name. If this is empty, the system assigns a name.
    /// - parameter firstSprite: The first sprite.
    /// - parameter firstAnchor: The connection for `firstSprite `.
    /// - parameter secondSprite: The second sprite. If this value is `nil`, the system attaches `firstSprite` to the scene.
    /// - parameter secondAnchor: The connection for `secondSprite`.
    ///
    /// - localizationKey: Joint.limit(name:from:at:to:at:)
    public static func limit(from firstSprite: Sprite, at firstAnchor: Point, to secondSprite: Sprite,  at secondAnchor: Point) -> LimitJoint {
        guard let bodyA = firstSprite.physicsBody, let bodyB = secondSprite.physicsBody, let parentNode = firstSprite.parent, let scene = parentNode.parent else { return SKPhysicsJointLimit() }

        let firstAnchorPointInParent = scene.convert(firstAnchor.cgPoint, from: parentNode)
        let secondAnchorPointInParent = scene.convert(secondAnchor.cgPoint, from: parentNode)

        let joint = SKPhysicsJointLimit.joint(withBodyA: bodyA, bodyB: bodyB, anchorA: firstAnchorPointInParent, anchorB: secondAnchorPointInParent)
        
        return joint
    }
    
    /// Creates a joint that pins together two sprites, allowing independent rotation.
    ///
    /// - parameter name: The joint’s name. If this is empty, the system assigns a name.
    /// - parameter firstSprite: The first sprite.
    /// - parameter secondSprite: The second sprite. If this value is `nil`, the system attaches `firstSprite` to the scene.
    /// - parameter axle: The location of the connection between the two sprites; the sprites rotate around this point.
    ///
    /// - localizationKey: Joint.pin(name:from:to:around:)
    public static func pin(from firstSprite: Sprite, to secondSprite: Sprite, around axle: Point) -> PinJoint {
        guard let bodyA = firstSprite.physicsBody, let bodyB = secondSprite.physicsBody, let parentNode = firstSprite.parent, let scene = parentNode.parent else { return SKPhysicsJointPin() }
        
        let anchorPointInParent = scene.convert(axle.cgPoint, from: parentNode)
        let joint = SKPhysicsJointPin.joint(withBodyA: bodyA, bodyB: bodyB, anchor: anchorPointInParent)
        
        
        return joint
    }
    
    /// Creates a joint that allows two sprites to slide along an axis.
    ///
    /// - parameter name: The joint’s name. If this is empty, the system assigns a name.
    /// - parameter firstSprite: The first sprite.
    /// - parameter secondSprite: The second sprite. If this value is `nil`, the system attaches `firstSprite` to the scene.
    /// - parameter anchor: The location of the connection between the two sprites.
    /// - parameter axis: A vector that defines the direction that the joint is allowed to slide.
    ///
    /// - localizationKey: Joint.sliding(name:from:to:at:axis:)
    public static func sliding(from firstSprite: Sprite, to secondSprite: Sprite, at anchor: Point, axis: Vector) -> SlidingJoint {
        guard let bodyA = firstSprite.physicsBody, let bodyB = secondSprite.physicsBody, let parentNode = firstSprite.parent, let scene = parentNode.parent else { return SKPhysicsJointSliding() }

        let anchorPointInParent = scene.convert(anchor.cgPoint, from: parentNode)
        let joint =  SKPhysicsJointSliding.joint(withBodyA: bodyA, bodyB: bodyB, anchor: anchorPointInParent, axis: CGVector(dx: axis.dx, dy: axis.dy))
        
        return joint
    }
    
    
    /// Creates a joint that simulates a spring connecting two sprites.
    ///
    /// - parameter name: The joint’s name. If this is empty, the system assigns a name.
    /// - parameter firstSprite: The first sprite.
    /// - parameter firstAnchor: The connection for `firstSprite `.
    /// - parameter secondSprite: The second sprite. If this value is `nil`, the system attaches `firstSprite` to the scene.
    /// - parameter secondAnchor: The connection for `secondSprite`.
    ///
    /// - localizationKey: Joint.spring(name:from:at:to:at:)
    public static func spring(from firstSprite: Sprite, at firstAnchor: Point, to secondSprite: Sprite, at secondAnchor: Point) -> SpringJoint {
        guard let bodyA = firstSprite.physicsBody, let bodyB = secondSprite.physicsBody, let parentNode = firstSprite.parent, let scene = parentNode.parent else { return SKPhysicsJointSpring() }
        
        let firstAnchorPointInParent = scene.convert(firstAnchor.cgPoint, from: parentNode)
        let secondAnchorPointInParent = scene.convert(secondAnchor.cgPoint, from: parentNode)
        let joint = SKPhysicsJointSpring.joint(withBodyA: bodyA, bodyB: bodyB, anchorA: firstAnchorPointInParent, anchorB: secondAnchorPointInParent)
        
        return joint
    }
}

extension Joint: Hashable, Equatable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    public static func ==(lhs: Joint, rhs: Joint) -> Bool {
        return lhs.id == rhs.id
    }
}

public typealias FixedJoint = SKPhysicsJointFixed
public typealias LimitJoint = SKPhysicsJointLimit
public typealias PinJoint = SKPhysicsJointPin
public typealias SlidingJoint = SKPhysicsJointSliding
public typealias SpringJoint = SKPhysicsJointSpring
