/// /*#-localizable-zone(spritePlayground1)*/A sandbox to play with shape sprites in a physics world./*#-end-localizable-zone*/
public class SpritePlayground {
    public init() {
        // /*#-localizable-zone(spriteSetup)*/Sets up the scene for physics./*#-end-localizable-zone*/
        scene.setBorderPhysics(hasCollisionBorder: true)
        scene.verticalGravity = -12.0
        
        setupScene()
        createMeasurement()
    }
    
    /// /*#-localizable-zone(spritePlayground2)*/Sets up the sandbox./*#-end-localizable-zone*/
    func setupScene() {
        let spriteCannon = Graphic(image: "🕳".image())
        spriteCannon.scale = 1.5
        spriteCannon.rotation = 90
        scene.place(spriteCannon, at: Point(x: 430, y: 300))
        
        let platform = Sprite.rectangle(width: 400, height: 25, cornerRadius: 10, color: #colorLiteral(red: 0.3248277307, green: 0.8369095325, blue: 0.9915711284, alpha: 1.0), colors: [#colorLiteral(red: 0.7202869057655334, green: 0.5427941679954529, blue: 1.0240224599838257, alpha: 1.0), #colorLiteral(red: 0.3681973815, green: 0.186875701, blue: 0.9226484895, alpha: 1.0)])
        platform.allowsRotation = true
        platform.physicsBody?.mass = 30
        platform.physicsBody?.friction = 0.50
        scene.place(platform, at: Point(x: 0, y: -250))
        
        let anchor = Sprite.circle(radius: 3, color: .clear)
        anchor.isDynamic = false
        scene.place(anchor, at: platform.location)
        

        let joint = Joint.pin(from: anchor, to: platform, around: anchor.location)
        joint.shouldEnableLimits = true
        joint.lowerAngleLimit = -0.4
        joint.upperAngleLimit = 0.4
        joint.frictionTorque = 3
        scene.add(joint: joint)
        
        spriteCannon.setOnTouchHandler { [self] _ in
            playSound(ShapesSound.pop1)
            spriteCannon.pulse()
            generateRandomSpriteShape(at: spriteCannon.location)
        }
        
    }
    
    /// /*#-localizable-zone(spritePlayground4)*/Creates a measurement line. Used to see how high you can stack sprites./*#-end-localizable-zone*/
    func createMeasurement() {
        var linePosition = -225
        for i in 1...7 {
            let line = Graphic.line(start: Point(x: 0, y: linePosition), end: Point(x: 0, y: linePosition + 50), thickness: 1, color: #colorLiteral(red: 0.5764705882352941, green: 0.5764705882352941, blue: 0.5764705882352941, alpha: 1.0))
            linePosition += 100
            line.zPosition = -2
            scene.place(line)
            
            
            let height = i * 100
            let label = Label(text: "\(height)", color: #colorLiteral(red: 0.5764705882352941, green: 0.5764705882352941, blue: 0.5764705882352941, alpha: 1.0))
            scene.place(label, at: Point(x: 0, y: (-250) + height))
        }
    }
    
    /// /*#-localizable-zone(spritePlayground5)*/Creates a random sprite shape./*#-end-localizable-zone*/
    func generateRandomSpriteShape(at point: Point) {
        let randomSpriteType = Int.random(in: 0...2)
        var sprite: Sprite
        switch randomSpriteType {
        case 0:
            sprite = Sprite.rectangle(width: Int.random(in: 50...150), height: Int.random(in: 50...150), cornerRadius: 0, color: Color.random())
        case 1:
            sprite = Sprite.rectangle(width: Int.random(in: 25...75), height: Int.random(in: 25...150), cornerRadius: 0, color: Color.random())
        case 2:
            sprite = Sprite.polygon(radius: Int.random(in: 40...75), sides: Int.random(in: 3...8), color: Color.random())
        default:
            sprite = Sprite.circle(radius: 5, color: .black)
        }
        sprite.isAffectedByGravity = true
        sprite.allowsRotation = true
        sprite.isDraggable = true
        sprite.physicsBody?.friction = 0.75
        
        scene.place(sprite, at: point)
        sprite.applyImpulse(x: Double.random(in: -300 ... -100), y: Double.random(in: 40...90))
    }
    
}
