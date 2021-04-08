//
//  InternalGraphic.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import SpriteKit
import SPCCore
import SPCAudio
import SPCAccessibility

open class InternalGraphic: SKSpriteNode, Comparable {
    
    public static func < (lhs: InternalGraphic, rhs: InternalGraphic) -> Bool {
        if let leftName = lhs.name, let rightName = rhs.name, rightName != leftName {
            return leftName < rightName
        } else {
            return lhs.id < rhs.id
        }
    }
    
    // MARK: Static properties
    static var cachedTextures = [Image : SKTexture]()
    static var cachedDisabledTextures = [Image : SKTexture]()
    static var cachedPaths = [Image : CGPath]()
    static var cachedSizes = [Image: CGSize]()
    
    static var tileSizes: [String: String] = {
        guard let tileSizesURL = Bundle(for: InternalGraphic.self).url(forResource: "TileSizes", withExtension: "plist"),
            let plist = NSDictionary(contentsOf: tileSizesURL) as? [String: String] else {
                NSLog("Failed to find TileSizes.plist")
                return [:]
        }
        return plist
    }()

    static var graphicsPaths: [String: [String]] = {
        guard let graphicsPathsURL = Bundle(for: InternalGraphic.self).url(forResource: "GraphicsPaths", withExtension: "plist"),
            let plist = NSDictionary(contentsOf: graphicsPathsURL) as? [String: [String]] else {
                NSLog("Failed to find GraphicsPaths.plist")
                return [:]
        }
        
        return plist
    }()
        
    // MARK: Static methods
    class func texture(for image: Image, type: TextureType = .graphic) -> SKTexture {
        
        if let texture = cachedTextures[image] {
            return texture
        }
        
        var uiImage = image.uiImage
        
        // clamp image to maxTextureSize
        let maxSize = type.maximumSize
        if (uiImage.size.width > maxSize.width ||
            uiImage.size.height  > maxSize.height) {
            uiImage = uiImage.resized(to: uiImage.size.fit(within: maxSize))
        }
        
        let texture = SKTexture(image: uiImage)
        cachedTextures[image] = texture
        return texture
    }
    
    static private func size(for image: Image) -> CGSize? {
        if let size = cachedSizes[image] { return size }
        guard let stringSize = tileSizes[image.description] else {
            return nil
        }
        
        let size = NSCoder.cgSize(for: stringSize)
        
        cachedSizes[image] = size
        return size
    }
    
    private func path(for image: Image) -> CGPath? {
        if let path = InternalGraphic.cachedPaths[image] { return path }
        guard let stringPoints = InternalGraphic.graphicsPaths[image.description] else {
            return nil
        }
        
        let points = stringPoints.map(NSCoder.cgPoint)
        let path = createOffsetPath(from: points)
        
        InternalGraphic.cachedPaths[image] = path
        return path
    }
    
    private func createOffsetPath(from points: [CGPoint]) -> CGPath {
        let offsetX = self.size.width * self.anchorPoint.x
        let offsetY = self.size.height * self.anchorPoint.y
        
        let path = CGMutablePath()
        for (index, oldPoint) in points.enumerated() {
            var newPoint = oldPoint
            newPoint.x -= offsetX
            newPoint.y -= offsetY
            if index == 0 {
                path.move(to: newPoint)
            } else {
                path.addLine(to: newPoint)
            }
        }
        path.closeSubpath()
        return path
    }
    
    init() {
        graphicType = .graphic
        _allowsTouchInteraction = false
        id = UUID().uuidString
        
        super.init(texture: nil, color: .clear, size: CGSize.zero)
        self.name = id
        
        NotificationCenter.default.addObserver(forName: Notification.shapeChanged, object: nil, queue: .main) { notification in
            if let id = notification.object as? String, self.shape?.shapeID == id {
                self.updateShapeImage()
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Base Properties
    /// An id, used to identify a Graphic. Read-only.
    ///
    /// - localizationKey: Graphic.id
    public let id: String
    
    public var disablesOnDisconnect = false
    
    public var axElement: UIAccessibilityElement?
    
    // Internal only representation of the rotation in radians.
    var rotationRadians: CGFloat = 0 {
       
        didSet {
            self.run(SKAction.rotate(toAngle: rotationRadians, duration: 0, shortestUnitArc: false))
        }
    }
    
    private var disabledTexture: SKTexture? {
        guard let image = self.image else { return nil }
        
        if let texture = InternalGraphic.cachedDisabledTextures[image] {
            return texture
        }
        
        if let uiImage = UIImage(named: image.path), let monoImage = uiImage.disabledImage(alpha: 0.5) {
            let disabledTexture = SKTexture(image: monoImage)
            InternalGraphic.cachedDisabledTextures[image] = disabledTexture
            return disabledTexture
        }
        
        return nil
    }
    
    public var accessibilityHints: AccessibilityHints?
    
    /*
     A remnant of the IPC AX system we still need
     */
    var graphic: Graphic {
        var newName = ""
        if let name = self.name {
            newName = name
        }
        let _graphic = Graphic(id: id, name: newName)
        _graphic.suppressMessageSending = true
        _graphic.text = _text ?? ""
        _graphic.alpha = alpha
        _graphic.position = position
        _graphic.isHidden = isHidden
        _graphic.rotationRadians = rotationRadians
        _graphic.xScale = xScale
        _graphic.yScale = yScale
        _graphic.image = image
        _graphic.name = name
        _graphic.size = self.size
        
        if let color = _textColor {
            _graphic.textColor = color
        }
        
        if let name = _fontName, let liveGraphicFontName = Font(rawValue: name) {
            _graphic.fontName = liveGraphicFontName.rawValue
        }
        
        return _graphic
    }
    
    // MARK: Base methods
    
    func setDisabledAppearance(_ disabled: Bool) {
        if disabled {
            if let physicsBody = self.physicsBody {
                physicsBody.velocity = CGVector(dx: 0, dy: 0)
                physicsBody.angularVelocity = 0
            }
            self.removeAllActions()
            
            // Stop playing any audio.
            let audioNodes = self.children.filter({ return $0 is SKAudioNode })
            
            audioNodes.forEach { $0.run(SKAction.stop()) }
            
            guard let disabledTexture = disabledTexture else { return }
            self.texture = disabledTexture
            updateTextImage(useDisabled: true)
        } else {
            applyImage()
        }
    }
    
    func applyImage() {
        guard
            let image = image else {
                self.texture = nil
                return
        }
        
        let texture = InternalGraphic.texture(for: image)
        updateBackingNode(texture: texture)
    }
    
    
    public func updateSize() {
        var baseSize = CGSize.zero
        
        if let image = image {
            baseSize = image.size
        } else if let shape = shape {
            baseSize = shape.size
        }
        
        size = Size(width: baseSize.width * xScale, height: baseSize.height * yScale).cgSize
    }
    
    func setXScale(scale: Double) {
        self.xScale = CGFloat(scale)
    }
    
    func setYScale(scale: Double) {
        self.yScale = CGFloat(scale)
    }
    
    // MARK: Audio Properties
    // Returns the attached audio node, if there is on.
    public var audioNode: SKAudioNode? {
        return self.children.filter({$0 is SKAudioNode}).first as? SKAudioNode
    }
    
    // MARK: Image properties
    public var columns: Int = 1
    public var rows: Int = 1
    
    public var isTiled: Bool {
        guard (columns > 0) && (rows > 0) else { return false }
        return (columns > 1) || (rows > 1)
    }
    
    public var image: Image? {
        didSet {
            self.applyImage()
        }
    }
    var graphicType: GraphicType
    public var isDynamic = false {
        didSet {
            _setIsDynamic(dynamic: isDynamic)
        }
    }
    
    // MARK: Text Properties
    var _text: String? = nil
    var _fontName: String? = nil
    var _fontSize: Int? = nil
    var _textColor: UIColor? = nil
    
    public var buttonHighlightTexture: SKTexture?
    
    // MARK: Shape Properties
    var shape: BaseShape? = nil {
        didSet {
            self.updateShapeImage()
        }
    }
    
    //MARK: Touch Properties
    var _allowsTouchInteraction: Bool
    var handlers = [InteractionType: Any]()
    
    //MARK: Collision Properties
    var collisionHandler: ((Collision)->Void)?
    
    public var _interactionCategory: InteractionCategory = InteractionCategory.all{
        didSet {
            if let physicsBody = self.physicsBody {
                physicsBody.categoryBitMask = _interactionCategory.rawValue
            }
        }
    }
    
    public var _collisionCategories: InteractionCategory = InteractionCategory.all {
        didSet {
            if let physicsBody = self.physicsBody {
                physicsBody.collisionBitMask = _collisionCategories.rawValue
            }
        }
    }
    
    public var _contactCategories: InteractionCategory = InteractionCategory.all {
        didSet {
            if let physicsBody = self.physicsBody {
                physicsBody.contactTestBitMask = _contactCategories.rawValue
            }
        }
    }
}

// MARK: Audio Protocol
extension InternalGraphic {
    func _addAudio(_ sound: Sound, positional: Bool, looping: Bool, volume: Double) {
        let audioNodes = self.children.filter({ return $0 is SKAudioNode })
        
        audioNodes.forEach { $0.removeFromParent() }
        
        let audioNode = SKAudioNode(fileNamed: sound)
        audioNode.autoplayLooped = looping
        audioNode.isPositional = positional
        addChild(audioNode)
        if volume != 100.0 {
            let initialVolume = Float(volume/100)
            audioNode.run(SKAction.changeVolume(to: initialVolume, duration: 0))
        }
    }
    
    func _removeAudio() {
            if let node = self.audioNode {
                node.removeFromParent()
            }
    }
    
    func _setIsPositionalAudio(_ positional: Bool) {
            if let node = self.audioNode {
                node.isPositional = positional
            }
    }
    
    func _playAudio() {
            if let node = self.audioNode {
                node.run(SKAction.play())
            }
    }
    
    func _stopAudio() {
            if let node = self.audioNode {
                node.run(SKAction.stop())
            }
    }
}

// MARK: Image Protocol
extension InternalGraphic {
    
    func _setImage(image: Image) {
            self.rows = 1
            self.columns = 1
            self.image = image
    }
    
    func _setTiledImage(image: Image?, columns: Int?, rows: Int?, isDynamic: Bool?) {
            self.columns = columns ?? 1
            self.rows = rows ?? 1
            self.image = image
            if let isDynamic = isDynamic {
                self.isDynamic = isDynamic
            }
            guard let image = image else {
                    self.texture = nil
                    return
            }
            
            let texture = InternalGraphic.texture(for: image)
            self.updateBackingNode(texture: texture)
    }
    
    
    private func updateBackingNode(texture: SKTexture) {
        if isTiled {
            children.forEach { $0.removeFromParent() }  // Remove any previous tile map node.
            
            let tileDefinition = SKTileDefinition(texture: texture)
            let tileGroup = SKTileGroup(tileDefinition: tileDefinition)
            let tileSet = SKTileSet(tileGroups: [tileGroup], tileSetType: .grid)
            let tileSize: CGSize
            if let image = image, let size = InternalGraphic.size(for: image) {
                tileSize = size
            } else {
                tileSize = tileSet.defaultTileSize // Texture size
            }
            let tileMapNode = SKTileMapNode(tileSet: tileSet, columns: columns, rows: rows, tileSize: tileSize)
            tileMapNode.fill(with: tileGroup)
            tileMapNode.name = self.name
            addChild(tileMapNode)
            size = tileMapNode.mapSize
        } else {
            self.texture = texture
            let textureSize = texture.size()
            size = CGSize(width: textureSize.width * CGFloat(xScale), height: textureSize.height * CGFloat(yScale))
        }
        guard graphicType == .sprite || graphicType == .character else { return }
        // Sprite => set up physics body.
        let physicsBody: SKPhysicsBody
        if isTiled {
            physicsBody = SKPhysicsBody(rectangleOf: self.size)
            physicsBody.isDynamic = self.isDynamic
        } else if let image = image, let polygonPath = path(for: image) {
            physicsBody = SKPhysicsBody(polygonFrom: polygonPath)
        } else if let shape = shape {
            switch shape {
            case let circle as CircleShape:
                physicsBody = SKPhysicsBody(circleOfRadius: CGFloat(circle.radius))
            case let rectangle as RectangleShape:
                let rect = CGRect(x: 0, y: 0, width: rectangle.width, height: rectangle.height)
                let roundedRectanglePoints = UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(rectangle.cornerRadius)).cgPath.points()
                physicsBody = SKPhysicsBody(polygonFrom: createOffsetPath(from: roundedRectanglePoints))
            case let polygon as PolygonShape:
                let rect = CGRect(x: 0, y: 0, width: polygon.radius * 2, height: polygon.radius * 2)
                let polygonPoints = UIBezierPath(polygonIn: rect, sides: polygon.sides).cgPath.points()
                physicsBody = SKPhysicsBody(polygonFrom: createOffsetPath(from: polygonPoints))
            case is StarShape:
                physicsBody = SKPhysicsBody(texture: texture, alphaThreshold: 0.75, size: texture.size())
            default:
                let mirror = CGAffineTransform(scaleX: 1, y: -1)
                let bezierPath = UIBezierPath(cgPath: createOffsetPath(from: shape.path.points()))
                bezierPath.apply(mirror)
                physicsBody = SKPhysicsBody(polygonFrom: bezierPath.cgPath)
            }
        } else {
            physicsBody = SKPhysicsBody(circleOfRadius: max(size.width / 2, size.height / 2))
        }
        
        // We reset the scale here so that the new physics body will scale with the sprite.
        let currentXScale = xScale
        let currentYScale = yScale
        yScale = 1
        xScale = 1
        
        if let body = self.physicsBody {
            // Existing physics body => replicate its properties.
            physicsBody.affectedByGravity = body.affectedByGravity
            physicsBody.allowsRotation = body.allowsRotation
            physicsBody.contactTestBitMask = body.contactTestBitMask
            physicsBody.collisionBitMask = body.collisionBitMask
            physicsBody.categoryBitMask = body.categoryBitMask
            physicsBody.isDynamic = body.isDynamic
            physicsBody.friction = body.friction
            physicsBody.angularDamping = body.angularDamping
            physicsBody.restitution = body.restitution
            physicsBody.angularVelocity = body.angularVelocity
            physicsBody.velocity = body.velocity
            
        } else {
            // New physics body.
            physicsBody.affectedByGravity = false
            physicsBody.allowsRotation = false
            physicsBody.contactTestBitMask = 0xFFFFFFFF
        }
            
        physicsBody.usesPreciseCollisionDetection = true
        
        // Set the scale to what it was before creating the new physics body.
        self.physicsBody = physicsBody
        xScale = currentXScale
        yScale = currentYScale
    }
}


// MARK: Text Protocol
extension InternalGraphic {
    func _setText(_ text: String?) {
        self._text = text
            self.updateTextImage()
    }
    
    func _setTextColor(_ color: Color) {
        self._textColor = color
            self.updateTextImage()
    }
    
    func _setFontSize(_ size: Int) {
        self._fontSize = size
            self.updateTextImage()
    }
    
    func _setFontName(_ name: String) {
        self._fontName = name
            self.updateTextImage()
    }
    
    func updateTextImage(useDisabled: Bool = false) {
        guard let textImage = createTextImage() else { return }
        var compositeImage = textImage
        
        if graphicType == .button {
            guard let image = image else {
                return
            }
            
            var uiImage = Image(imageLiteralResourceName: image.path).uiImage
            let maxSize = TextureType.graphic.maximumSize
            if (uiImage.size.width > maxSize.width ||
                uiImage.size.height  > maxSize.height) {
                uiImage = uiImage.resized(to: uiImage.size.fit(within: maxSize))
            }
            
            if useDisabled {
                let monoImage = uiImage.disabledImage(alpha: 1.0) ?? uiImage
                compositeImage = InternalGraphic.compositeImage(from: textImage, overlaidOn: monoImage)
            } else {
                compositeImage = InternalGraphic.compositeImage(from: textImage, overlaidOn: uiImage)
                updateButtonHighlight(image: image, textImage: textImage)
            }
        }
        
        let texture = SKTexture(image: compositeImage)
        self.texture = texture
        let textureSize = texture.size()
        self.size = CGSize(width: textureSize.width * CGFloat(xScale), height: textureSize.height * CGFloat(yScale))
    }
    
    func createTextImage() -> UIImage? {
        guard
            let text = _text,
            let textColor = _textColor,
            let fontName = _fontName,
            let fontSize = _fontSize
            else { return nil }
        
        var font: UIFont
        if fontName.starts(with: "System") {
            let weightString = fontName.replacingOccurrences(of: "System", with: "", options: .literal, range: nil)
            if weightString == "Italic" {
                font = UIFont.italicSystemFont(ofSize: CGFloat(fontSize))
            } else if weightString == "BoldItalic" {
                font = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: UIFont.Weight.regular).boldItalic
            } else if weightString == "HeavyItalic" {
                font = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: UIFont.Weight.heavy).italic
            } else {
                if let weight = Double(weightString) {
                    font = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: UIFont.Weight(rawValue: CGFloat(weight)))
                } else {
                    font = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: UIFont.Weight.regular)
                }
            }
            
        } else {
            if let unwrappeFont = UIFont(name: fontName, size: CGFloat(fontSize)) {
                font = unwrappeFont
            } else {
                font = UIFont.systemFont(ofSize: CGFloat(fontSize), weight: UIFont.Weight.regular)
            }
        }
        
        return InternalGraphic.image(from: text, textColor: textColor, font: font)
    }
    
    class func image(from text: String, textColor: UIColor, font: UIFont) -> UIImage? {
        let text = text as NSString
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font : font,
            .foregroundColor: textColor,
            .paragraphStyle: style
        ]
        let constrainedSize = CGSize(width: Scene.sceneSize.width, height: Scene.sceneSize.height)
        let textBounds = text.boundingRect(with: constrainedSize,
                                            options: .usesLineFragmentOrigin,
                                            attributes: attributes,
                                            context: nil)
        let textSize = textBounds.size
        guard textSize.width > 1 && textSize.height > 1 else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(textSize, false, 0.0)
        
        text.draw(in: CGRect(x:0, y:0, width:textSize.width,  height:textSize.height), withAttributes: attributes)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    class func compositeImage(from textImage: UIImage, overlaidOn backgroundImage: UIImage) -> UIImage {
        var compositeImage = backgroundImage
        
        // Create an image with a small resizable center.
        let insetH = (backgroundImage.size.width / 2)
        let insetV = (backgroundImage.size.height / 2)
        let insets = UIEdgeInsets(top: insetV - 1, left: insetH - 1, bottom: insetV, right: insetH)
        compositeImage = backgroundImage.resizableImage(withCapInsets: insets)
        
        // Resize image so that it has some padding around textImage.
        let imageSize = CGSize(width: textImage.size.width + 40, height: textImage.size.height + 30)
        compositeImage = compositeImage.resized(to: imageSize)
        
        // Overlay textImage on top (in the center).
        return compositeImage.overlaid(with: textImage, offsetBy: CGPoint(x: 0, y: 0))
    }
    
    func updateButtonHighlight(image: Image, textImage: UIImage) {
        let highlightImagePath = "\(image.path)_down"
        if let highlightImage = UIImage(named: highlightImagePath) {
            let highlightCompositeImage = InternalGraphic.compositeImage(from: textImage, overlaidOn: highlightImage)
            buttonHighlightTexture = SKTexture(image: highlightCompositeImage)
        }
    }
}

// MARK: Shape Protocol
extension InternalGraphic {
    func _setShape(_ shape: BaseShape?) {
        self.shape = shape
    }
    
    public func updateShapeImage() {
        guard let shape = shape else { return }
        
        let texture = SKTexture(image: shape.image)
        updateBackingNode(texture: texture)
    }
    
    internal func handleShapeChanged(shape: BaseShape) {
        self.shape = shape
    }
}

// MARK: Actionable
extension InternalGraphic {
    func _runAction(action: SKAction, name: String?) {
        DispatchQueue.main.async {
            if let name = name {
                self.run(action, withKey: name)
            }
            else {
                self.run(action)
            }
        }
    }
    
    func _removeAction(name: String) {
        DispatchQueue.main.async {
            self.removeAction(forKey: name)
        }
    }
    
    func _removeAllActions() {
        DispatchQueue.main.async {
            self.removeAllActions()
        }
    }
}

// MARK: Touchable
extension InternalGraphic {
    func _setHandler(for type: InteractionType, handler: Any) {
        handlers[type] = handler
    }
    
    public func hasHandler(forInteraction type: InteractionType) -> Bool {
        if let _ = handlers[type] {
            return true
        } else {
            return false
        }
    }
    
    public func removeHandler(forInteraction type: InteractionType) {
        handlers.removeValue(forKey: type)
    }
}

//MARK: Colliable
extension InternalGraphic {
    func _setOnCollisionHandler(_ handler: @escaping (Collision)->Void) {
        self.collisionHandler = handler
    }
}

//MARK: Physicable
extension InternalGraphic {
    func _setAffectedByGravity(gravity: Bool) {
        if let physicsBody = physicsBody {
            physicsBody.affectedByGravity = gravity
        }
    }
    func _setIsDynamic(dynamic: Bool) {
        if let physicsBody = physicsBody {
            physicsBody.isDynamic = dynamic
        }
    }
    func _setAllowsRotation(rotation: Bool) {
        if let physicsBody = physicsBody {
            physicsBody.allowsRotation = rotation
        }
    }
    func _setVelocity(velocity: CGVector) {
        if let physicsBody = physicsBody {
            physicsBody.velocity = velocity
        }
    }
    func _setRotationalVelocity(rotationalVelocity: Double) {
        if let physicsBody = physicsBody {
            physicsBody.angularVelocity = rotationalVelocity.cgFloat
        }
    }
    func _setBounciness(bounciness: Double) {
        if let physicsBody = physicsBody {
            physicsBody.restitution = bounciness.cgFloat
        }
    }
    func _setFriction(friction: Double) {
        if let physicsBody = physicsBody {
            physicsBody.friction = friction.cgFloat
        }
    }
    func _setDensity(density: Double) {
        if let physicsBody = physicsBody {
            physicsBody.density = density.cgFloat
        }
    }
    func _setDrag(drag: Double) {
        if let physicsBody = physicsBody {
            physicsBody.linearDamping = drag.cgFloat
        }
    }
    func _setRotationalDrag(drag: Double) {
        if let physicsBody = physicsBody {
            physicsBody.angularDamping = drag.cgFloat
        }
    }
    func _applyImpulse(vector: CGVector) {
        if let physicsBody = physicsBody {
            physicsBody.applyImpulse(CGVector(dx: (vector.dx) / 3, dy: (vector.dy) / 3))
        } else {
            return
        }
    }
    func _applyForce(vector: CGVector, duration: Double) {
        if let _ = physicsBody {
            let forceAction = SKAction.applyForce(CGVector(dx: vector.dx, dy: vector.dy), duration: duration)
            run(forceAction)
        } else {
            return
        }
    }
}
