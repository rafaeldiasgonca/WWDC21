//
//  ComponentExtensions.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import SpriteKit
import SPCCore
import SPCAudio


extension AudioPlaying where Self: InternalGraphic {
    func addAudio(_ sound: Sound, positional: Bool, looping: Bool, volume: Double) {
        _addAudio(sound, positional: positional, looping: looping, volume: volume)
    }
    
    func removeAudio() {
        _removeAudio()
    }
    
    func setIsAudioPositional(isAudioPositional: Bool) {
        _setIsPositionalAudio(isAudioPositional)
    }
    
    func playAudio() {
        _playAudio()
    }
    
    func stopAudio() {
        _stopAudio()
    }
}

public extension Collidable where Self: InternalGraphic {
    var interactionCategory: InteractionCategory {
        get {
            return _interactionCategory
        } set {
            _interactionCategory = newValue
        }
    }
    
    func setCollisionCategories(collisionCategories: InteractionCategory) {
        _collisionCategories = collisionCategories
    }
    
    func setContactCategories(contactCategories: InteractionCategory) {
        _contactCategories = contactCategories
    }
    
    func setOnCollisionHandler(_ handler: @escaping (Collision)->Void) {
        _setOnCollisionHandler(handler)
    }
}

extension ImageProtocol where Self: InternalGraphic {
    func setImage(image: Image) {
        _setImage(image: image)
    }
    
    func setTiledImage(image: Image?, columns: Int?, rows: Int?, isDynamic: Bool?) {
        _setTiledImage(image: image, columns: columns, rows: rows, isDynamic: isDynamic)
    }
}

public extension TextProtocol where Self: InternalGraphic {
    var text: String {
        get {
            return _text ?? ""
        }
        set {
            _setText(newValue)
        }
    }
    
    var textColor: Color {
        get {
            return _textColor ?? UIColor.black
        }
        set {
            _setTextColor(newValue)
        }
    }
    
    var fontSize: Int {
        get {
            return _fontSize ?? 0
        }
        set {
            _setFontSize(newValue)
        }
    }
    
    var fontName: String {
        get {
            return _fontName ?? ""
        } set {
            _setFontName(newValue)
        }
    }
}

public extension ShapeProtocol where Self: InternalGraphic {
    var shape: BaseShape {
        get {
            if let shape = self.shape {
                return shape
            } else {
                return BaseShape(path: CGPath(rect: .null, transform: nil))
            }
        }
        set {
            _setShape(newValue)
        }
    }

    func updateShape(shape: BaseShape, color: Color? = nil, colors: [Color]? = nil) {

        if let backgroundColor = color {
            shape.backgroundColor = backgroundColor
        }

        if let backgroundColors = colors {
            shape.backgroundColors = backgroundColors
        }

        self.shape = shape
    }
    
    var backgroundColor: Color {
        get {
            if let shape = self.shape {
                return shape.backgroundColor
            } else {
                return .clear
            }
        }
        set (newColor) {
            self.shape?.backgroundColor = newColor
            if let shape = self.shape {
                updateShape(shape: shape, color: newColor, colors: nil)
            }
            
        }
    }
    
    /// An array of colors used to make a gradient. Must be more than two colors.
    var backgroundColors: [Color] {
        get {
            if let unwrappedShape = self.shape {
                return unwrappedShape.backgroundColors
            } else {
                return [.clear, .clear]
            }

        }
        set (newGradient) {
            guard newGradient.count >= 2 else {
                
                print(NSLocalizedString("The backgroundColors array must have two or more elements in it", comment: "Error message for assigning a color array of size < 2"))
                return
            }
            self.shape?.backgroundColors = newGradient
            
            if let shape = self.shape {
                updateShape(shape: shape, color: nil, colors: newGradient)
            }
        }
    }
    
    var strokeColor: Color {
        get {
            if let shape = self.shape {
                return shape.strokeColor
            } else {
                return Color.clear
            }
        }
        set (newColor) {
            if let shape = self.shape {
                self.shape?.strokeColor = newColor
                updateShape(shape: shape, color: nil, colors: nil)
            }
        }
    }
    
    var strokeColors: [Color] {
        get {
            if let shape = self.shape {
                return shape.strokeColors
            } else {
                return [.clear, .clear]
            }
        }
        set (newGradient) {
            if let shape = self.shape {
                self.shape?.strokeColors = newGradient
                updateShape(shape: shape, color: nil, colors: nil)
            }
        }
    }
    
    var strokeWidth: Double {
        get {
            if let shape = self.shape {
                return Double(shape.strokeWidth)
            } else {
                return 0.0
            }
        }
        set {
            if let _ = self.shape {
                self.shape?.strokeWidth = newValue.cgFloat
                updateShape(shape: self.shape!)
            }
        }
    }
 }

public extension Physicable where Self: InternalGraphic {
    func setAffectedByGravity(gravity: Bool) {
        _setAffectedByGravity(gravity: gravity)
    }
    
    func setIsDynamic(dynamic: Bool) {
        _setIsDynamic(dynamic: dynamic)
    }
    
    func setAllowsRotation(rotation: Bool) {
        _setAllowsRotation(rotation: rotation)
    }
    
    func setVelocity(velocity: CGVector) {
        _setVelocity(velocity: velocity)
    }
    
    func setRotationalVelocity(rotationalVelocity: Double) {
        _setRotationalVelocity(rotationalVelocity: rotationalVelocity)
    }
    
    func setBounciness(bounciness: Double) {
        _setBounciness(bounciness: bounciness)
    }
    
    func setFriction(friction: Double) {
        _setFriction(friction: friction)
    }
    
    func setDensity(density: Double) {
        _setDensity(density: density)
    }
    
    func setDrag(drag: Double) {
        _setDrag(drag: drag)
    }
    
    func setRotationalDrag(drag: Double) {
        _setRotationalDrag(drag: drag)
    }
    
    func applyImpulse(vector: CGVector) {
        _applyImpulse(vector: vector)
    }
    
    func applyForce(vector: CGVector, duration: Double) {
        _applyForce(vector: vector, duration: duration)
    }
}

extension Scaleable where Self: InternalGraphic {
    func setXScale(scale: Double) {
        
    }
    
    func setYScale(scale: Double) {
            
    }
}

public extension Emittable where Self: InternalGraphic {
    func addParticleEmitter(name: String, duration: Double, color: Color) {
        DispatchQueue.main.async {
            guard let emitter = SKEmitterNode(fileNamed: name), let containerNode = self.parent else { return }
            
            let emitterNode = SKNode()
            emitterNode.zPosition = self.zPosition + 1
            emitterNode.addChild(emitter)
            
            var addEmitter = SKAction()
            let wait = SKAction.wait(forDuration: TimeInterval(duration))
            let removeEmitter = SKAction.run { emitterNode.removeFromParent() }
            
            emitter.particleZPosition = self.zPosition + 1
            emitter.particleColorSequence = nil
            emitter.particleColor = color
            
            let height = self.size.height
            let width = self.size.width
            
            addEmitter = SKAction.run {
                if name == "Explode" {
                    emitterNode.position = self.position
                    containerNode.addChild(emitterNode)
                } else {
                    self.addChild(emitterNode)
                    emitter.targetNode = containerNode
                }
            }
            
            if name == "Explode" {
                emitter.particlePositionRange = CGVector(dx: width, dy: height)
                emitter.numParticlesToEmit = 200
            }
            
            if name == "Tracer" {
                if let image = self.image, let uiImage = UIImage(named: image.path) {
                    emitter.particleTexture = SKTexture(image: uiImage)
                    emitter.particleScale = CGFloat(self.xScale)
                }
            }
            
            if name == "Spark" {
                emitter.particlePositionRange = CGVector(dx: width / 4, dy: height / 4)
                emitter.particleBirthRate = ((width + height) / 2) * 25
                emitter.particleZPosition = -1
            }
            
            if name == "Sparkles" {
                let scaleAdjust = 1.0 / self.xScale
                let scaleAdjustedHeight = height * scaleAdjust
                let scaleAdjustedWidth = width * scaleAdjust
                emitter.particlePositionRange = CGVector(dx: scaleAdjustedWidth, dy: scaleAdjustedHeight)
                let adjustedParticleScale = ((scaleAdjustedWidth + scaleAdjustedHeight) / 2) * 0.0041
                emitter.particleScale = adjustedParticleScale
                emitter.particleBirthRate = ((scaleAdjustedHeight + scaleAdjustedWidth) / 2) * 2.75
            }
            
            let sequence = SKAction.sequence([addEmitter, wait, removeEmitter])
            self.run(sequence)
        }
    }
}

public extension Actionable where Self: InternalGraphic {
    func runAction(_ action: SKAction, name: String? = nil, completion: (()->Void)? = nil) {
        _runAction(action: action, name: name)
        
        if let comp = completion {
            comp()
        }
    }
    
    func removeAction(name: String) {
        _removeAction(name: name)
    }
    
    func removeAllActions() {
        _removeAllActions()
    }
        
    /// Pulsates the Graphic by increasing and decreasing its scale a given number of times, or indefinitely.
    ///
    /// - Parameter period: The period of each pulsation in seconds.
    /// - Parameter count: The number of pulsations; the default (`-1`) is to pulsate indefinitely.
    ///
    /// - localizationKey: Graphic.pulsate(period:count:)
    func pulsate(period: Double = 5.0, count: Int = -1) {
        _runAction(action: SKAction.pulsate(period: period, count: count), name: nil)
    }
    
    func scale(to scale: Double, duration: Double) {
        _runAction(action: SKAction.scale(to: CGFloat(scale), duration: TimeInterval(duration)), name: nil)
    }
    
    func fadeIn(after duration: Double) {
        _runAction(action: .fadeIn(withDuration: duration), name: "fadeIn")
    }
    
    func fadeOut(after duration: Double) {
        _runAction(action: .fadeOut(withDuration: duration), name: "fadeOut")
    }
    
    func rotate(to radians: Double, duration: Double = 0.5) {
        _runAction(action: .rotate(toAngle: radians.cgFloat, duration: duration), name: "rotate")
    }
    
    func rotate(to degrees: Int, duration: Double = 0.5) {
        let rads = (Double(degrees) / 180.0) * pi
        _runAction(action: .rotate(toAngle: rads.cgFloat, duration: duration), name: "rotate")
    }
    
    func touchPulse() {
        let scaleUp = SKAction.scale(to: 1.25, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        let action = SKAction.sequence([scaleUp, scaleDown])
        _runAction(action: action, name: "touchPulse")
        
    }
}

extension TouchInteractable where Self: InternalGraphic {
    public var allowsTouchInteraction: Bool {
        get {
            return _allowsTouchInteraction
        } set {
            _allowsTouchInteraction = newValue
        }
    }
    
    public func setHandler(for type: InteractionType, handler: @escaping (Touch)->Void) {
        self.allowsTouchInteraction = true
        if type == .touchUp {
            _setHandler(for: .touchCancelled, handler: handler as Any)
            _setHandler(for: .touchEnded, handler: handler as Any)
        } else {
            _setHandler(for: type, handler: handler as Any)
        }
        
    }
}
