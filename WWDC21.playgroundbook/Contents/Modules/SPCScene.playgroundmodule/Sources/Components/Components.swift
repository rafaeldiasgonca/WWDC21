//
//  Components.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import SpriteKit
import SPCCore
import SPCAudio

protocol AudioPlaying: class {
    /// Adds a sound to the graphic.
    ///
    /// - Parameter sound: The sound to add.
    /// - Parameter positional: Whether the sound changes based on the position of the graphic. The default is `true`.
    /// - Parameter looping: Whether the sound should loop. The default is `true`.
    /// - Parameter volume: The volume at which the sound is played (ranging from `0` to `100`). The default is `100`: full volume.
    ///
    /// - localizationKey: BaseGraphic.addAudio(_:positional:looping:volume:)
    func addAudio(_ sound: Sound, positional: Bool, looping: Bool, volume: Double)
    
    /// Removes the current audio being played.
    ///
    /// - localizationKey: BaseGraphic.removeAudio()
    func removeAudio()
    
    /// Sets whether or not audio should be played based on the position of the BaseGraphic.
    ///
    /// - Parameter isAudioPositional: Whether the audio is to be played positionally.
    ///
    /// - localizationKey: BaseGraphic.setIsAudioPositional(isAudioPositional:)
    func setIsAudioPositional(isAudioPositional: Bool)
    
    /// Begins audio playback.
    ///
    /// - localizationKey: BaseGraphic.playAudio()
    func playAudio()
    
    /// Stops audio playback.
    ///
    /// - localizationKey: BaseGraphic.stopAudio()
    func stopAudio()
}

public protocol Collidable: class {
    var interactionCategory: InteractionCategory {get set}
    func setCollisionCategories(collisionCategories: InteractionCategory)
    func setContactCategories(contactCategories: InteractionCategory)
    func setOnCollisionHandler(_ handler: @escaping (Collision)->Void)
}

protocol ToneSensing: class {
    
}

protocol LightSensing: class {
    
}

protocol MotionSensing: class {
    
}

protocol ImageProtocol: class {
    ///
    func setImage(image: Image)
    func setTiledImage(image: Image?, columns: Int?, rows: Int?, isDynamic: Bool?)
}

public protocol TextProtocol: class {
    var text: String { get set }
    var textColor: Color { get set}
    var fontName: String { get set}
    var fontSize: Int { get set }
}

public protocol ShapeProtocol: class {
    var shape: BaseShape { get set }
}

public protocol Physicable: class {
    func setAffectedByGravity(gravity: Bool)
    func setIsDynamic(dynamic: Bool)
    func setAllowsRotation(rotation: Bool)
    func setVelocity(velocity: CGVector)
    func setRotationalVelocity(rotationalVelocity: Double)
    func setBounciness(bounciness: Double)
    func setFriction(friction: Double)
    func setDensity(density: Double)
    func setDrag(drag: Double)
    func setRotationalDrag(drag: Double)
    func applyImpulse(vector: CGVector)
    func applyForce(vector: CGVector, duration: Double)
}

protocol Scaleable: class {
    func setXScale(scale: Double)
    func setYScale(scale: Double)
}

public protocol Emittable: class {
    func addParticleEmitter(name: String, duration: Double, color: Color)
}

public protocol Actionable: class {
    func runAction(_ action: SKAction, name: String?, completion: (()->Void)?)
    func removeAction(name: String)
    func removeAllActions()
}

protocol Joinable: class {}

public protocol TouchInteractable: class {
    var allowsTouchInteraction: Bool {get set}
    func setHandler(for type: InteractionType, handler: @escaping (Touch)->Void)
}
