//
//  Sprite+AnimationExtension.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import SPCCore
import SPCScene
import SpriteKit

extension Sprite {
    public func runAnimation(_ animation: String, duration: Double, numberOfTimes: Int) {
        DispatchQueue.main.async {
            let characterMap: [String:String] = ["alien":"Character3",
                                                 "codeMachine":"Character1",
                                                 "giraffe":"animal3",
                                                 "elephant":"animal1",
                                                 "piranha":"animal2"]
            var resourceNames: [String] = []
            var animationCycle: SKAction = SKAction()
            
            if animation == "springExtend" {
                resourceNames.append("springUnloaded@2x")
                resourceNames.append("springLoaded@2x")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "balloon1Pop" {
                for i in 0...5 {
                    resourceNames.append("balloonPOP/balloonPOP.0000" + String(i))
                }
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "balloon2Pop" {
                for i in 1...6 {
                    resourceNames.append("balloonPOP2/balloonPOP2.0000" + String(i))
                }
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "bombExplode" {
                for i in 0...8 {
                    resourceNames.append("bombEXPLODE/bombEXPLODE.0000" + String(i))
                }
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
                
            } else if animation == "bombIdle" {
                for i in 0...9 {
                    resourceNames.append("bombIDLE/bombIDLE.0000" + String(i))
                }
                resourceNames.append("bombIDLE/bombIDLE.00010")
                resourceNames.append("bombIDLE/bombIDLE.00011")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "throwSwitchLeft" {
                resourceNames.append("switchMid@2x")
                resourceNames.append("switchLeft@2x")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "throwSwitchRight" {
                resourceNames.append("switchMid@2x")
                resourceNames.append("switchRight@2x")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "tree1Idle" {
                for i in 0...6 {
                    resourceNames.append("tree1WALK/tree1WALK.0000" + String(i))
                }
                resourceNames.append("tree1@2x")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "tree2Idle" {
                for i in 0...6 {
                    resourceNames.append("tree2WALK/tree2WALK.0000" + String(i))
                }
                resourceNames.append("tree2@2x")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation == "greenButton" {
                if let originalTexture = self.texture,
                    let highlightTexture = self.buttonHighlightTexture {
                    let textures = [highlightTexture, originalTexture]
                    animationCycle = SKAction.animate(with: textures, timePerFrame: duration)
                }
            } else if animation == "redButton" {
                if let originalTexture = self.texture,
                    let highlightTexture = self.buttonHighlightTexture {
                    let textures = [highlightTexture, originalTexture]
                    animationCycle = SKAction.animate(with: textures, timePerFrame: duration)
                }
            } else if animation.contains(".idle") {
                let characterName = animation.replacingOccurrences(of: ".idle", with: "", options: .literal, range: nil)
                let resourceName = characterMap[characterName]! + "IDLE"
                for i in 0...9 {
                    resourceNames.append("\(resourceName)/\(resourceName).0000" + String(i))
                }
                resourceNames.append("\(resourceName)/\(resourceName).00010")
                resourceNames.append("\(resourceName)/\(resourceName).00011")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation.contains(".walk") {
                let characterName = animation.replacingOccurrences(of: ".walk", with: "", options: .literal, range: nil)
                let resourceName = characterMap[characterName]! + "WALK"
                for i in 0...5 {
                    resourceNames.append("\(resourceName)/\(resourceName).0000" + String(i))
                }
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation.contains(".jump") {
                let characterName = animation.replacingOccurrences(of: ".jump", with: "", options: .literal, range: nil)
                let resourceName = characterMap[characterName]! + "JUMP"
                let staticResourceName = characterMap[characterName]! + "STATIC"
                for i in 0...5 {
                    resourceNames.append("\(resourceName)/\(resourceName).0000" + String(i))
                }
                resourceNames.append("\(staticResourceName).00000@2x")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            } else if animation.contains(".duck") {
                let characterName = animation.replacingOccurrences(of: ".duck", with: "", options: .literal, range: nil)
                let resourceName = characterMap[characterName]! + "DUCK"
                let staticResourceName = characterMap[characterName]! + "STATIC"
                resourceNames.append("\(resourceName).00000")
                resourceNames.append("\(staticResourceName).00000")
                animationCycle = SKAction.createAnimation(fromResourceURLs: resourceNames, timePerFrame: duration)
            }
            
            var animationAction: SKAction?
            
            if numberOfTimes == 1 {
                animationAction = animationCycle
            } else if numberOfTimes == -1 {
                animationAction = SKAction.repeatForever(animationCycle)
            } else if numberOfTimes > 1 {
                animationAction = SKAction.repeat(animationCycle, count: numberOfTimes)
            }
            
            if let animationAction = animationAction {
                self.run(animationAction)
            }
        }
    }
    
    public func runCustomAnimation(animationSequence: [String], duration: Double, numberOfTimes: Int) {
        DispatchQueue.main.async {
            let animation = SKAction.createAnimation(fromResourceURLs: animationSequence, timePerFrame: duration)
            if numberOfTimes == 0 {
                return
            } else if numberOfTimes == 1 {
                self.run(animation)
            } else if numberOfTimes == -1 {
                let runForever = SKAction.repeatForever(animation)
                self.run(runForever)
            } else if numberOfTimes > 1 {
                let runMultiple = SKAction.repeat(animation, count: numberOfTimes)
                self.run(runMultiple)
            } else {
                return
            }
            
        }
        
    }
}
