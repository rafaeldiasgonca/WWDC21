//
//  Player.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import SpriteKit
import SPCCore
import SPCScene

public typealias Action = SKAction

/// An enumeration of types of players, including: alien, codeMachine, giraffe, elephant, and piranha.
///
/// - localizationKey: PlayerType
public enum PlayerType: String {
    case alien
    case codeMachine
    case giraffe
    case elephant
    case piranha
}

/// An enumeration of the available animations, a few examples are: greenButton, redButton, and springExtend.
///
public extension String {
    static let greenButton = "greenButton"
    static let redButton = "redButton"
    static let springExtend = "springExtend"
    static let throwSwitchLeft = "throwSwitchLeft"
    static let throwSwitchRight = "throwSwitchRight"
    static let balloon1Pop = "balloon1Pop"
    static let balloon2Pop = "balloon2Pop"
    static let bombIdle = "bombIdle"
    static let bombExplode = "bombExplode"
    static let tree1Idle = "tree1Idle"
    static let tree2Idle = "tree2Idle"
}

/// A Player is a type of Sprite that has additional methods for animating sprite movements.
///
/// - localizationKey: Player
public class Player: Sprite {
    
    /// Some Player animations include: walk, duck, jump, and idle.
    ///
    /// - localizationKey: Player.PlayerAnimation
    public enum PlayerAnimation: String {
        case walk
        case duck
        case jump
        case idle
    }
    
    fileprivate static var defaultNameCount: Int = 1
    
    var facingForward = true
    
    /// An attribute of the Player that identifies its character type, including: alien, codeMachine, giraffe, elephant, or piranha.
    ///
    /// - localizationKey: Player.characterType
    var characterType: PlayerType = .alien
    
    /// Runs an animation on the given Player.
    ///
    /// - Parameter animation: An enumeration specifying the animation to run.
    /// - Parameter timePerFrame: The amount of time between images in the animation sequence.
    /// - Parameter numberOfTimes: The number of times to repeat the animation. Setting this value to `-1` repeats the animation indefinitely.
    ///
    ///- localizationKey: Player.runAnimation(_:timePerFrame:numberOfTimes:)
    public func runAnimation(_ animation: PlayerAnimation, timePerFrame: Double = 0.05, numberOfTimes: Int = 1) {
        let characterAnimation = characterType.rawValue + "." + animation.rawValue
        super.runAnimation(characterAnimation, duration: timePerFrame, numberOfTimes: numberOfTimes)
    }
    
//    @available(*, unavailable, message: "Player uses it’s own implementation of `runAnimation` and does not use the base class implementation.")
//    override open func runAnimation(_ animation: String, timePerFrame: Double, numberOfTimes: Int) {
//        // Use player-specific run animation instead.
//    }
    
    /// Creates a Player with a specified type and name.
    ///
    /// - Parameter type: The type of Player you want.
    /// - Parameter name: A name you give to your Player.
    ///
    /// - localizationKey: Player(type:name:)
    public init(type: PlayerType, name: String = "") {
        let img:Image
        switch type {
        case .alien:
            img = Image(imageLiteralResourceName: "Character3STATIC.00000@2x.png")
        case .codeMachine:
            img = Image(imageLiteralResourceName: "Character1STATIC.00000@2x.png")
        case .giraffe:
            img = Image(imageLiteralResourceName: "animal3STATIC.00000@2x.png")
        case .elephant:
            img = Image(imageLiteralResourceName:
                "animal1STATIC.00000@2x.png")
        case .piranha:
            img = Image(imageLiteralResourceName: "animal2STATIC.00000@2x.png")
        }
        
        if name == "" {
            super.init(image: img, name: "character" + String(Player.defaultNameCount))
            Player.defaultNameCount += 1
        } else {
            super.init(image: img, name: name)
        }
        
        self.characterType = type
        
        /*
         Manually sending a message here, as setting a property on a struct
         from within one of its own initializers won’t trigger the didSet property.
         */
        //SceneProxy().setImage(id: id, image: image)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// `jump` makes a Player do a front flip.
    ///
    /// - Parameter x: How far a Player jumps on the x-axis.
    /// - Parameter y: How far a Player jumps on the y-axis.
    ///
    /// - localizationKey: Player.jump(x:y:)
    public func jump(x: Double, y: Double) {
        let vector = CGVector(dx: CGFloat(x), dy: CGFloat(y))
        let jumpLength = 0.09
        runAnimation(.jump, timePerFrame: jumpLength, numberOfTimes: 1)
        let rotate = SKAction.rotate(byAngle: CGFloat(-360.0 * Double.pi / 180.0), duration: 0.4)
        //SceneProxy().runAction(id: id, action: rotate, name: "rotate")
        //SceneProxy().applyImpulse(id: id, vector: vector)
        self.rotation = 0
    }
    
    /// `dash` makes a Player move on the x-axis at the speed you determine.
    ///
    /// - Parameter speed: How fast the Player dashes.
    ///
    /// - localizationKey: Player.dash(speed:)
    public func dash(speed: Double) {
        if speed >= 0 {
            xScale = CGFloat(self.scale)
            facingForward = true
        } else {
            xScale = CGFloat(-self.scale)
            facingForward = false
        }

        runAnimation(.walk, timePerFrame: 0.05, numberOfTimes: 1)
        applyImpulse(vector: CGVector(dx: speed, dy: 0))
        
        
    }
        
    /// `duck` makes a Player duck down.
    ///
    /// - Parameter duration: How long the Player ducks down.
    ///
    /// - localizationKey: Player.duck(duration:)
    public func duck(duration: Double) {
        runAnimation(.duck, timePerFrame: duration, numberOfTimes: 1)
        let scaleTo = Action.scaleX(by: 1, y: 0.5, duration: duration)
        let scaleBack = Action.scaleX(by: 1, y: 2, duration: duration)
        let sequence = Action.sequence([scaleTo,scaleBack])
        self.run(sequence)
    }
}

