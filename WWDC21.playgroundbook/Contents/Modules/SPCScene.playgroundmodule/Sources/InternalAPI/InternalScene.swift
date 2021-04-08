//
//  InternalScene.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//


import Foundation
import UIKit
import SpriteKit
import Dispatch
import PlaygroundSupport
import AVFoundation
import SPCCore
import SPCAudio
import SPCAccessibility
import SPCLiveView

private let sceneSize = CGSize(width:1000, height: 1000)

open class InternalScene: SKScene, UIGestureRecognizerDelegate, SKPhysicsContactDelegate, LiveViewLifeCycleProtocol, GraphicAccessibilityElementDelegate, BackgroundAccessibilityElementDelegate {
    
    static let initialPrintPosition = CGPoint(x: 0, y: 400)
    static var printPosition = initialPrintPosition
    
    public static let didCreateGraphic = NSNotification.Name("LiveViewSceneDidCreateGraphic")
    public static let collisionOccurred = NSNotification.Name("LiveViewSceneCollisionOccurred")
    public static let firstGraphicKey = "LiveViewSceneFirstGraphic"
    public static let secondGraphicKey = "LiveViewSceneSecondGraphic"
    
    /// Determines whether a graphic on the scene, if touched first, will capture all subsequent touches delivered to the scene. If set to `true`, a first touch delivered to a graphic or the scene will only activate the touchMoved handlers for that graphic or the scene. Set to `false` by default.
    ///
    /// - localizationKey: Scene.capturesTouches
    public var capturesTouches = false
    
    public let containerNode = SKNode()
    
    var capturedGraphic: BaseGraphic? = nil
    
    
    let nc = NotificationCenter.default
    var enterBackgroundObserver: Any?
    var willEnterForegroundObserver: Any?
    
    var blockLightSensorImage = false
    
    private var graphicAccessibilityElementGroupsByID = Dictionary<String, GraphicAccessibilityElement>()
    
    private var accessibilityAllowsDirectInteraction: Bool = false {
        didSet {
            let note : String
            
            if accessibilityAllowsDirectInteraction {
                note = NSLocalizedString("Direct interaction enabled", tableName: "SPCScene", comment: "AX description when direct interaction is enabled")
            }
            else {
                note = NSLocalizedString("Direct interaction disabled", tableName: "SPCScene", comment: "AX description when direct interaction is disabled")
            }
            
            UIAccessibility.post(notification: .layoutChanged, argument: note)
        }
    }
    
    private let audioPlayerQueue = DispatchQueue(label: "com.apple.audioPlayerQueue")
    
    var executionMode: PlaygroundPage.ExecutionMode? = nil {
        didSet {
            updateState(forExecutionMode: executionMode)
        }
    }
    
    private var steppingEnabled : Bool {
        get {
            return executionMode == .step || executionMode == .stepSlowly
        }
    }
    
    private var addedToView = false
    private let backgroundNode = BackgroundContainerNode()
    private var loadscreenNode = SKSpriteNode()
    private var connectedToUserProcess : Bool = false {
        didSet {
            // Only do this if we’re turning it off, not just initializing it
            if !connectedToUserProcess && oldValue == true {
                accessibilityAllowsDirectInteraction = false
                setNeedsUpdateAccessibility(notify: false)
            }
        }
    }
    
    // To track when we’ve received the last touch we sent to the user process
    private var lastSentTouch : Touch?
    
    private var shouldHandleTouches: Bool = true
    
    private var graphicsPositionUpdateTimer:Timer? = nil
    
    var graphicsInfo = [String : InternalGraphic]() { // keyed by id
        didSet {
            setNeedsUpdateAccessibility(notify: false)
        }
    }
    
    private var activeCollisions = Set<CollisionPair>()
    
    /// The function that’s called when two things collide onscreen.
    ///
    /// The `collision` parameter passed to the handler contains information about the collision.
    ///
    /// - localizationKey: Scene.onCollisionHandler
    public var onCollisionHandler: ((Collision) -> Void)?

    func setNeedsUpdateAccessibility(notify: Bool) {
        self.axElements.removeAll(keepingCapacity: true)
        
        if notify {
            UIAccessibility.post(notification: .screenChanged, argument: self.accessibilityElements?.first)
        }
    }
    
    func addAccessibleGraphic(_ graphic: InternalGraphic) {
        if UIAccessibility.isVoiceOverRunning {
            self.graphicPlacedAudioPlayer?.play()
        }
    }
    
    private lazy var graphicPlacedAudioPlayer: AVAudioPlayer? = {
        guard let url = Bundle.main.url(forResource: "GraphicPlaced", withExtension: "aifc") else { return nil }
        var audioPlayer: AVAudioPlayer?
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.5
        } catch {}
        return audioPlayer
    }()
    
    public func graphicsInfo(forName name: String) -> [InternalGraphic] {
        return graphicsInfo
            .filter { pair -> Bool in
                let (_, graphic) = pair
                return graphic.name == name
        }
        .map { pair -> InternalGraphic in
            let (_, graphic) = pair
            return graphic
        }
    }
    
    public func graphicsInfo(nameStartsWith prefix: String) -> [InternalGraphic] {
        return graphicsInfo
            .filter { pair -> Bool in
                let (_, graphic) = pair
                if let _ = graphic.name?.starts(with: prefix) {
                    return true
                } else {
                    return false
                }
        }
        .map { pair -> InternalGraphic in
            let (_, graphic) = pair
            return graphic
        }
    }
    
    var _joints = [String: SKPhysicsJoint]() // Keyed by Joint ID.
    
    var axElements = [UIAccessibilityElement]()
    
    func updateState(forExecutionMode: PlaygroundPage.ExecutionMode?) {
        guard let executionMode = executionMode else { return }
        switch executionMode {
        case .step, .stepSlowly:
            break
            
        default:
            break
        }
    }
    
    /// The Scene’s background image.
    ///
    /// - localizationKey: Scene.backgroundImage
    public var backgroundImage: Image? {
        didSet {
            // If the image is not exactly our expected edge-to-edge size, assume the learner has placed an image of their own.
            if let liveView = PlaygroundPage.current.liveView as? LiveViewController {
                if let bgImage = backgroundImage {
                    blockLightSensorImage = true
                    
                    if let uiImage = UIImage(named: bgImage.path) {
                        if uiImage.size.width >= TextureType.backgroundMaxSize.width && uiImage.size.height >= TextureType.backgroundMaxSize.height {
                            backgroundNode.backgroundImage = nil
                            
                            liveView.backgroundImage = uiImage
                        }
                        else {
                            // Learner image
                            backgroundNode.backgroundImage = bgImage
                            
                            liveView.backgroundImage = nil
                        }
                    }
                }
                else {
                    // Background image cleared
                    backgroundNode.backgroundImage = nil
                    
                    liveView.backgroundImage = nil
                }
            }
        }
    }
    
    public var lightSensorImage: UIImage? {
        // Interface orientation was deprecated in 8.0 but it's the only way to properly orient the image. Wrapping the entire didSet in an availability macro quiets the warning.
        @available(iOS, deprecated: 8.0)
        didSet {
            if let liveView = PlaygroundPage.current.liveView as? LiveViewController, !blockLightSensorImage {
                if var lsImage = lightSensorImage {
                    let vcOrientation = liveView.interfaceOrientation
                    
                    if vcOrientation != .landscapeRight, let cgImage = lsImage.cgImage {
                        var orientation = UIImage.Orientation.up
                        
                        // rotate image if necessary
                        if vcOrientation == .portrait {
                            orientation = .left
                        } else if vcOrientation == .landscapeLeft {
                            orientation = .down
                        } else if vcOrientation == .portraitUpsideDown {
                            orientation = .right
                        }
                        
                        lsImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
                    }
                    
                    liveView.backgroundImage = lsImage
                    liveView.backgroundImageView.contentMode = .scaleAspectFit
                } else {
                    // Background image cleared
                    liveView.backgroundImage = nil
                }
            }
        }
    }
    
    public let skView = SKView(frame: .zero)
    
    public override init() {
        super.init()
        
        size = sceneSize
        
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        // The SKView hosting this scene is always sized appropriately so fit/fill really doesn’t matter here.
        scaleMode = .aspectFit
        isUserInteractionEnabled = true
        backgroundColor = UIColor.clear
        updateState(forExecutionMode: PlaygroundPage.current.executionMode)
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue:"PlaygroundPageExecutionModeDidChange"), object: nil, queue: OperationQueue.main) { (notification) in
            self.executionMode = PlaygroundPage.current.executionMode
        }
        
        //        SceneProxy.registerToRecieveDecodedMessage(as: self)
        //        AccessibilityProxy.registerToRecieveDecodedMessage(as: self)
        //        AudioProxy.registerToRecieveDecodedMessage(as: self)
        
        // If user code and live view are running in the same process, then the connection is already established.
        //if Message.isLiveViewOnly {
        connectedToUserProcess = true
        //}
        
        skView.allowsTransparency = true
        skView.presentScene(self)
    }
    
    public override init(size: CGSize) {
        super.init(size: size)
        commonInit()
    }
    
    private func configureLoadscreenNode() {
        let name = "loadscreen\(arc4random_uniform(8) + 1)"
        if let img = UIImage(named: name) {
            loadscreenNode.texture = SKTexture(image: img)
            loadscreenNode.size = loadscreenNode.texture!.size()
            loadscreenNode.position = self.center
        }
    }
    
    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        if !addedToView {
            physicsWorld.contactDelegate = self
            physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
            
            configureLoadscreenNode()
            
            AudioSession.current.delegate = self
            AudioSession.current.configureEnvironment()
            
            addChild(backgroundNode)
            addChild(loadscreenNode)
            addChild(containerNode)
            containerNode.name = "container"
            backgroundNode.name = "background"
            
            addedToView = true
        }
    }
    
    public override func didChangeSize(_ oldSize: CGSize) {
        backgroundNode.position = center
        containerNode.position = center
    }
    
    public func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node as? Sprite, let nodeB = contact.bodyB.node as? Sprite else { return }
        
        guard let liveGraphicA = graphicsInfo[nodeA.id] else { return }
        guard let liveGraphicB = graphicsInfo[nodeB.id] else { return }
        
        let sortedGraphics = [liveGraphicA, liveGraphicB].sorted()
        
        guard let collidedSpriteA = sortedGraphics[0] as? Sprite,
            let collidedSpriteB = sortedGraphics[1] as? Sprite else { return }
        
        var isOverLapping: Bool = false
        
        if let pos = contact.bodyB.node?.position, let overlap = contact.bodyA.node?.contains(pos), overlap {
            isOverLapping = true
        }
        
        
        
        var normalizedDirection: CGVector = CGVector()
        if liveGraphicA.name == sortedGraphics[0].name {
            normalizedDirection = contact.contactNormal
        } else {
            normalizedDirection = CGVector(dx: -contact.contactNormal.dx, dy: -contact.contactNormal.dy)
        }
        
        handleCollision(spriteA: collidedSpriteA, spriteB: collidedSpriteB, angle: normalizedDirection, force: Double(contact.collisionImpulse), isOverlapping: isOverLapping)
    }
    
    var _touchHandler: ((Touch) -> Void)?
    var _touchMovedHandler: ((Touch) -> Void)?
    var _doubleTouchHandler: ((Touch) -> Void)?
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard shouldHandleTouches else { return }
        // reenable direct interaction
        if accessibilityAllowsDirectInteraction, let firstTouch = touches.first, firstTouch.tapCount == 2 {
            accessibilityAllowsDirectInteraction = false

            return
        }
        
        let skTouchPosition = touches[touches.startIndex].location(in: containerNode)
        // Get all visible nodes at the touch position.
        let intersectingNodes = containerNode.nodes(at: skTouchPosition)
        // Search visible nodes for the topmost graphic that allows touch interaction.
        for node in intersectingNodes {
            if let interalGraphic = node as? InternalGraphic, let liveGraphic = graphicsInfo[interalGraphic.id], liveGraphic._allowsTouchInteraction {
                capturedGraphic = liveGraphic as? BaseGraphic
                break
            }
        }
        
        let doubleTouch = touches.first?.tapCount == 2
        
        handleTouch(at: skTouchPosition, firstTouch: true, doubleTouch: doubleTouch)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard shouldHandleTouches else { return }
        
        let skTouchPosition = touches[touches.startIndex].location(in: containerNode)
        handleTouch(at: skTouchPosition, touchMoved: true)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard shouldHandleTouches else { return }
        
        let skTouchPosition = touches[touches.startIndex].location(in: containerNode)
        handleTouch(at: skTouchPosition, lastTouch: true)
        
        commonTouchEndingCleanup()
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard shouldHandleTouches else { return }
        
        let skTouchPosition = touches[touches.startIndex].location(in: containerNode)
        handleTouch(at: skTouchPosition, canceledTouch: true)
        
        commonTouchEndingCleanup()
    }
    
    func commonTouchEndingCleanup() {
        guard !capturesTouches else { return }
        capturedGraphic = nil
        
    }
    
    func handleTouch(at: CGPoint, firstTouch: Bool = false, ignoreNode: Bool = false, doubleTouch: Bool = false, touchMoved: Bool = false, lastTouch: Bool = false, canceledTouch: Bool = false) {

        var touch = Touch(position: Point(at), previousPlaceDistance: 0, firstTouch: firstTouch, touchedGraphic: nil, capturedGraphicID: capturedGraphic?.id ?? "")
        
        touch.lastTouch = lastTouch
        
        if !ignoreNode {
            var node: InternalGraphic?
            // Get all visible nodes at the touch position.
            let hitNodes = containerNode.nodes(at: at)
            // Search visible nodes for the topmost graphic that allows touch interaction.
            for hitNode in hitNodes {
                if let hit = hitNode as? InternalGraphic, let graphic = graphicsInfo[hit.id], graphic._allowsTouchInteraction {
                    touch.touchedGraphic = (graphic as! BaseGraphic)
                    node = graphic
                    break
                }
            }
            
            // if capturesTouches is true, call the appropriate handler based on the action
            if capturesTouches, let captured = capturedGraphic {
                if let id = capturedGraphic?.id {
                    touch.capturedGraphicID = id
                }
                if firstTouch {
                    handleTapAction(forNode: captured, doubleTouch: doubleTouch, touch: touch)
                } else if lastTouch, let handler = capturedGraphic?.handlers[.touchEnded] as? (Touch)->Void {

                    handler(touch)
                } else if canceledTouch, let handler = captured.handlers[.touchCancelled] as? (Touch)->Void {

                    handler(touch)
                } else if touchMoved, let handler = captured.handlers[.drag] as? (Touch)->Void {
                    handler(touch)
                    
                }
            // otherwise call the appropriate handler for the touched graphic
            } else if let touchedNode = node {
                if firstTouch {
                    if touchedNode._allowsTouchInteraction {
                        if let button = touchedNode as? Button {
                            button.buttonPressAnimation(duration: 0.1)
                        }
                        handleTapAction(forNode: touchedNode, doubleTouch: doubleTouch, touch: touch)
                    }
                } else if lastTouch, let handler = touchedNode.handlers[.touchEnded] as? (Touch) -> Void {
                    handler(touch)
                } else if canceledTouch, let handler = touchedNode.handlers[.touchCancelled] as? (Touch) -> Void {
                    handler(touch)
                } else if touchMoved, let handler = touchedNode.handlers[.drag] as? (Touch)->Void {
                    handler(touch)
                    
                }
            } else {
                //call the scenes touch handlers
                if firstTouch {
                    if doubleTouch, let handler = _doubleTouchHandler {
                     handler(touch)
                    } else if let handler = _touchHandler {
                        handler(touch)
                    }
                } else if let handler = _touchMovedHandler {
                    handler(touch)
                }
            }
            
            lastSentTouch = touch
        }
        
        
        
    }
    
    private func handleTapAction(forNode: InternalGraphic, doubleTouch: Bool, touch: Touch) {
        if let handler = forNode.handlers[.touch] as? (Touch) -> Void {
            handler(touch)
        } else if doubleTouch, let handler = forNode.handlers[.touch] as? (_:Touch) -> Void  {
            handler(touch)
        }
    }
    
    func handleCollision(spriteA: Sprite, spriteB: Sprite, angle: CGVector, force: Double, isOverlapping: Bool) {
        let collision = Collision(spriteA: spriteA, spriteB: spriteB, angle: Vector(angle), force: force, isOverlapping: isOverlapping)
        
        sceneCollisionEvent(collision: collision)
    }
    
    public func sceneCollisionEvent(collision: Collision) {
        
        // Ignore any additional collisions between the pair
        // until the first collision is completely resolved.
        
        let pair = CollisionPair(spriteA: collision.spriteA, spriteB: collision.spriteB)
        guard !activeCollisions.contains(pair) else { return }
        
        activeCollisions.insert(pair)
        defer {
            // Further debounce collisions.
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [unowned self] (timer) in
                self.activeCollisions.remove(pair)
            }
        }
        
        // Get the placed sprites.
//        guard let spriteA = placedGraphics[collision.spriteA.id] as? Sprite else {
//            fatalError("*** Unable to find a sprite with the ID: \(collision.spriteA.id) ***")
//        }
//
//        guard let spriteB = placedGraphics[collision.spriteB.id] as? Sprite else {
//            fatalError("*** Unable to find a sprite with the ID: \(collision.spriteB.id) ***")
//        }
        
        let spriteA = collision.spriteA
        let spriteB = collision.spriteB
        
        // Update the placed sprites.
        spriteA.updateMotionState(from: collision.spriteA)
        spriteB.updateMotionState(from: collision.spriteB)
        
        
        // Call the scene’s collision handler, if there is one.
        if let sceneCollisionHandler = onCollisionHandler {
            // Replace the collision’s temporary sprites with the placed sprites.
            let actualCollision = Collision(spriteA: collision.spriteA, spriteB: collision.spriteB, angle: collision.angle, force: collision.force, isOverlapping: collision.isOverlapping)
            sceneCollisionHandler(actualCollision)
        }
        
        // Call spriteA’s collision handler, if there is one.
        if let spriteACollisionHandler = spriteA.collisionHandler {
            // If spriteA’s notification categories include spriteB’s interaction category, send the notification to spriteA.
            if !spriteA._collisionCategories.intersection(spriteB._interactionCategory).isEmpty {
                // Notify spriteA of a collision with spriteB.
                // The collision’s spriteA is the sprite that receives the notification i.e. itself.
                let collision = Collision(spriteA: spriteA, spriteB: spriteB, angle: collision.angle, force: collision.force, isOverlapping: collision.isOverlapping)
                spriteACollisionHandler(collision)
            }
        }
        
        // Call spriteB’s collision handler, if there is one.
        if let spriteBCollisionHandler = spriteB.collisionHandler {
            // If spriteB’s notification categories include spriteA’s interaction category, send the notification to spriteB.
            if !spriteB._collisionCategories.intersection(spriteA._interactionCategory).isEmpty {
                // Notify spriteB of a collision with spriteA.
                // The collision’s spriteA is the sprite that receives the notification i.e. itself.
                let collision = Collision(spriteA: spriteB, spriteB: spriteA, angle: collision.angle, force: collision.force, isOverlapping: collision.isOverlapping)
                spriteBCollisionHandler(collision)
            }
        }
    }
    
    private func disableGraphics() {
        for graphic in graphicsInfo.values.filter({ $0.disablesOnDisconnect }) {
            graphic.setDisabledAppearance(true)
        }
    }
    
    internal func setupPositionTimer() {
        if self.graphicsPositionUpdateTimer == nil {
            self.graphicsPositionUpdateTimer = Timer.scheduledTimer(withTimeInterval:1.0/20.0, repeats: true, block: { (t : Timer) in
                var positions = [String:CGPoint]()
                var velocities = [String:CGVector]()
                var rotationalVelocities = [String:CGFloat]()
                var sizes = [String:CGSize]()
                
                for id in self.graphicsInfo.keys {
                    if let graphic = self.graphicsInfo[id] {
                        let backingNode = graphic
                        
                        if let physicsBody = backingNode.physicsBody {
                            if physicsBody.isDynamic {
                                positions[id] = backingNode.position
                                velocities[id] = physicsBody.velocity
                                rotationalVelocities[id] = physicsBody.angularVelocity
                            }
                        }
                        
                        sizes[id] = backingNode.size
                    }
                }
            })
        }
    }
    
    
    
    func addSceneObservers() {
        enterBackgroundObserver = nc.addObserver(forName: .NSExtensionHostDidEnterBackground, object: nil, queue: .main) { _ in
            self.graphicsPositionUpdateTimer?.invalidate()
            self.graphicsPositionUpdateTimer = nil
        }
        
        
        willEnterForegroundObserver = nc.addObserver(forName: .NSExtensionHostWillEnterForeground, object: nil, queue: .main) { _ in
            self.setupPositionTimer()
        }
    }
    
    func removeSceneObservers() {
        if let observer = self.enterBackgroundObserver {
            self.nc.removeObserver(observer)
        }
        
        if let observer = self.willEnterForegroundObserver {
            self.nc.removeObserver(observer)
        }
    }
    
    public func setLightSensorImage(image: UIImage?) {
        DispatchQueue.main.async {
            self.lightSensorImage = image
        }
    }
    
    func getGraphics() -> [BaseGraphic] {
        var graphics = [BaseGraphic]()
        for graphic in graphicsInfo.values {
            if let baseGraphic = graphic as? BaseGraphic {
                graphics.append(baseGraphic)
            }
        }
        return graphics
    }
    
    public func setBorderPhysics(hasCollisionBorder: Bool) {
        if hasCollisionBorder {
            let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
            self.physicsBody = borderBody
            
        } else {
            self.physicsBody = nil
        }
    }
    
    public func setSceneBackgroundColor(color: Color) {
        DispatchQueue.main.async { [unowned self] in
            self.backgroundNode.backgroundColor = color
            
            self.blockLightSensorImage = true
            
            if let liveView = PlaygroundPage.current.liveView as? LiveViewController {
                liveView.backgroundImage = nil
            }
            
            self.setNeedsUpdateAccessibility(notify: true)
        }
    }
    
    public func setSceneBackgroundImage(image: Image?) {
        DispatchQueue.main.async {
            self.backgroundImage = image
            
            self.setNeedsUpdateAccessibility(notify: true)
        }
    }
    
    public func setSceneGridVisible(isVisible: Bool) {
        self.backgroundNode.isGridOverlayVisible = isVisible
    }
    
    public func clearScene() {
            self.graphicsPositionUpdateTimer?.invalidate()
            self.graphicsPositionUpdateTimer = nil
            self.containerNode.removeAllChildren()
            self.graphicsInfo.removeAll()
            type(of: self).printPosition = type(of:self).initialPrintPosition
            
            self.setNeedsUpdateAccessibility(notify: false)
            
            self.blockLightSensorImage = false
    }
    
    public func placeGraphic(_ graphic: InternalGraphic, position: CGPoint, isPrintable: Bool, anchorPoint: AnchorPoint) {
        graphicsInfo[graphic.id] = graphic
            if graphic.parent == nil {
                self.containerNode.addChild(graphic)
            }
            
            // Compute center position from anchor point and size.
            // NOTE: anchor point is ignored after initial placement.
            var centerPosition = CGPoint.zero
            switch anchorPoint {
            case .center:
                centerPosition = position
            case .left:
                centerPosition = CGPoint(x: position.x + (graphic.size.width / 2), y: position.y)
            case .top:
                centerPosition = CGPoint(x: position.x, y: position.y - (graphic.size.height / 2))
            case .right:
                centerPosition = CGPoint(x: position.x - (graphic.size.width / 2), y: position.y)
            case .bottom:
                centerPosition = CGPoint(x: position.x, y: position.y + (graphic.size.height / 2))
            }
            
            graphic.position = isPrintable ? InternalScene.printPosition : centerPosition
            
            if isPrintable {
                InternalScene.printPosition.y -= graphic.size.height
            }
            
            self.setupPositionTimer()
            
            self.addAccessibleGraphic(graphic)
        
    }
    
    public func placeRelativeGraphic(graphic: String, relativeTo: String, xOffset: Double, yOffset: Double) {
            if let placed = self.graphicsInfo[graphic] {
                if placed.parent == nil {
                    self.containerNode.addChild(placed)
                }
                
                if let relative = self.graphicsInfo[relativeTo] {
                    placed.position.x = relative.position.x + CGFloat(xOffset)
                    placed.position.y = relative.position.y + CGFloat(yOffset)
                }
                
                self.setupPositionTimer()
                
                self.addAccessibleGraphic(placed)
            }
    }
    
    public func removeGraphic(id: String) {
            if let spriteNode = self.containerNode.childNode(withId: id) {
                spriteNode.removeFromParent()
                if self.graphicsInfo[id] != nil {
                    self.graphicsInfo.removeValue(forKey: id)
                }
                
                self.setNeedsUpdateAccessibility(notify: false)
                
                if self.graphicsInfo.count == 0 {
                    self.graphicsPositionUpdateTimer?.invalidate()
                    self.graphicsPositionUpdateTimer = nil
                }
            }
    }
    
    public func setSceneGravity(vector: CGVector) {
        self.physicsWorld.gravity = vector
    }
    
    public func setScenePositionalAudioListener(id: String) {
        DispatchQueue.main.async {
            guard let graphic = self.graphicsInfo[id] else { return }
            self.listener = graphic
        }
    }
    
    public func addParticleEmitter(name: String, duration: Double, color: Color) {
        DispatchQueue.main.async {
            guard let emitter = SKEmitterNode(fileNamed: name) else { return }
            
            let emitterNode = SKNode()
            emitterNode.zPosition = 15
            emitterNode.addChild(emitter)
            
            var addEmitter = SKAction()
            let wait = SKAction.wait(forDuration: TimeInterval(duration))
            let removeEmitter = SKAction.run { emitterNode.removeFromParent() }
            
            if color.alpha > 0.05 {
                emitter.particleColorSequence = nil
                emitter.particleColor = color
            }
            // Particle emitter is on the scene
            addEmitter = SKAction.run {
                self.containerNode.addChild(emitterNode)
            }
            
            let sequence = SKAction.sequence([addEmitter, wait, removeEmitter])
            self.run(sequence)
        }
    }
    
    // MARK: GraphicAccessibilityElementDelegate
    
    private func graphicDescription(for graphic: InternalGraphic) -> String {
        let label: String
        let imageDescription: String
        let graphicRole: String
        var updatedValueDescription: String? = nil

        if let accLabel = graphic.accessibilityHints?.accessibilityLabel {
            imageDescription = accLabel
        } else if let text = graphic._text {
            imageDescription = text
        } else if let name = graphic.name, !name.isEmpty {
            imageDescription = name
        } else if let image = graphic.image {
            imageDescription = image.description
        } else {
            imageDescription = ""
        }
        
        if graphic.accessibilityHints?.needsUpdatedValue == true {
            switch graphic.graphicType {
            case .label:
                updatedValueDescription = graphic._text
            default:
                break
            }
        }
        if let customLabel = graphic.accessibilityHints?.usesCustomAccessibilityLabel, customLabel {
            label = imageDescription
        } else  {
            switch graphic.graphicType {
            case .button:
                graphicRole = NSLocalizedString("button", tableName: "SPCScene", comment: "graphic type")
            case .character:
                graphicRole = NSLocalizedString("character", tableName: "SPCScene", comment: "graphic type")
            case .graphic:
                graphicRole = NSLocalizedString("graphic", tableName: "SPCScene", comment: "graphic type")
            case .label:
                graphicRole = NSLocalizedString("label", tableName: "SPCScene", comment: "graphic type")
            case .sprite:
                graphicRole = NSLocalizedString("sprite", tableName: "SPCScene", comment: "graphic type")
            }
            
            if let updatedValueDescription = updatedValueDescription {
                label = String(format: NSLocalizedString("%@, %@, %@, at x %d, y %d", tableName: "SPCScene", comment: "AX label: description of an image, its value, and its position in the scene."), imageDescription, updatedValueDescription, graphicRole, Int(graphic.position.x), Int(graphic.position.y))
            } else {
                label = String(format: NSLocalizedString("%@, %@, at x %d, y %d", tableName: "SPCScene", comment: "AX label: description of an image and its position in the scene."), imageDescription, graphicRole, Int(graphic.position.x), Int(graphic.position.y))
            }
        }
        
        
        
        return label
    }
    func accessibilityLabel(element: GraphicAccessibilityElement) -> String {
        var label = ""
        if let liveViewGraphic = graphicsInfo[element.identifier] {
            label = graphicDescription(for: liveViewGraphic)
        }
        return label
    }
    
    func accessibilityFrame(element: GraphicAccessibilityElement) -> CGRect {
        var frame = CGRect.zero
        
        if let liveViewGraphic = graphicsInfo[element.identifier], let hints = liveViewGraphic.accessibilityHints {
            if let groupID = hints.groupID, let element = graphicAccessibilityElementGroupsByID[groupID] {
                for graphic in element.graphics {
                    if let graphic = graphicsInfo[graphic.id] {
                        if frame == CGRect.zero {
                            frame = graphic.accessibilityFrame
                        } else {
                            frame = frame.union(graphic.accessibilityFrame)
                        }
                    }
                }
            } else {
                frame = liveViewGraphic.accessibilityFrame
            }
            
            frame = frame.insetBy(dx: -10, dy: -10)
        }
            
        return frame
    }
    
    func accessibilityTraits(element: GraphicAccessibilityElement) -> UIAccessibilityTraits {
        if let liveViewGraphic = graphicsInfo[element.identifier] {
            switch liveViewGraphic.graphicType {
            case .sprite:
                return .image
            case .button:
                return .button
            case .label:
                return .staticText
            default:
                return .none
            }
        }
        
        return .none
    }
    
    func accessibilitySimulateTouch(at point: CGPoint, firstTouch: Bool, lastTouch: Bool) {
        let viewTouchPosition = UIScreen.main.coordinateSpace.convert(point, to: view!)
        var skTouchPosition = convertPoint(fromView: viewTouchPosition)
        
        skTouchPosition.x += 500.0
        skTouchPosition.y -= 500.0
        
        handleTouch(at: skTouchPosition, firstTouch: firstTouch, lastTouch: lastTouch)
    }
    
    fileprivate func accessibilityActivate(element: BackgroundAccessibilityElement) -> Bool {
        if (connectedToUserProcess) {
            accessibilityAllowsDirectInteraction = !accessibilityAllowsDirectInteraction
        }
        return true
    }
    
    public override var accessibilityCustomActions : [UIAccessibilityCustomAction]? {
        set { }
        get {
            let summary = UIAccessibilityCustomAction(name: NSLocalizedString("Scene summary.", tableName: "SPCScene", comment: "AX action name"), target: self, selector: #selector(sceneSummaryAXAction))
            let sceneDetails = UIAccessibilityCustomAction(name: NSLocalizedString("Image details for scene.", tableName: "SPCScene", comment: "AX action name"), target: self, selector: #selector(imageDetailsForScene))

            
            return [summary, sceneDetails]
        }
    }
    
    private func findGraphics() -> [(String, InternalGraphic)] {
        // Sort the graphics vertically.
        let orderedGraphicsInfo = graphicsInfo.tupleContents.sorted { lhs, rhs in
            return lhs.1.position.y > rhs.1.position.y
        }
        
        return orderedGraphicsInfo.filter { element in
            let graphic = element.1
            guard graphic.parent == containerNode else { return false }
            return true
        }
    }
    
    @objc func sceneSummaryAXAction() {
        var imageListDescription = ""
        
        let count = findGraphics().count
        if count > 0 {
            if (count == 1) {
                imageListDescription += String(format: NSLocalizedString("%d graphic found.", tableName: "SPCScene", comment: "AX label: count of graphics (singular)."), count)
            }
            else {
                imageListDescription += String(format: NSLocalizedString("%d graphics found.", tableName: "SPCScene", comment: "AX label: count of graphics (plural)."), count)
            }
        }
        
        UIAccessibility.post(notification: .announcement, argument: imageListDescription)
    }
    
    @objc func imageDetailsForScene() {
        let graphics = findGraphics()
        var imageListDescription = ""
        switch graphics.count {
        case 0:
            imageListDescription += NSLocalizedString("Zero graphics found in scene.", tableName: "SPCScene", comment: "AX label, count of graphics (none found)")
        case 1:
            imageListDescription += String(format: NSLocalizedString("%d graphic found.", tableName: "SPCScene", comment: "AX label: count of graphics (singular)."), graphics.count)
        default:
            imageListDescription += String(format: NSLocalizedString("%d graphics found.", tableName: "SPCScene", comment: "AX label: count of graphics (plural)."), graphics.count)
        }
        
        for (_, liveViewGraphic) in graphics {
            imageListDescription += graphicDescription(for: liveViewGraphic)
            imageListDescription += ", "
        }
        
        UIAccessibility.post(notification: .announcement, argument: imageListDescription)
    }
    
    public var accessibilityHints: AccessibilityHints?
    
    public override var accessibilityElements: [Any]? {
        set { /* Should not need to set */ }
        get {
            guard !accessibilityAllowsDirectInteraction else { return nil }
            
            // VO will ask for accessible elements pretty frequently. We should only update our list of items when the number of graphics we’re tracking changes.
            guard axElements.isEmpty else { return axElements }
            
            var sceneLabel = ""
            if let hints = accessibilityHints, hints.usesCustomAccessibilityLabel, let label = hints.accessibilityLabel {
                sceneLabel = label
                _addBGElement(frame: view!.bounds, label: sceneLabel, elementCount: findGraphics().count, custom: true)
            } else {
                // Add accessibility elements
                sceneLabel = NSLocalizedString("Scene, ", tableName: "SPCScene", comment: "AX label")
                if let backgroundImage = backgroundImage {
                    sceneLabel += String(format: NSLocalizedString("background image: %@, ", tableName: "SPCScene", comment: "AX label: background image description."), backgroundImage.description)
                }
                
                // Describe the color even if there is an image (it’s possible the image does not cover the entire scene).
                if let backgroundColor = backgroundNode.backgroundColor {
                    sceneLabel += String(format: NSLocalizedString("background color: %@.", tableName: "SPCScene", comment: "AX label: scene background color description."), backgroundColor.accessibleDescription)
                }
                
                _addBGElement(frame: view!.bounds, label: sceneLabel, elementCount: findGraphics().count)
            }
            
            let graphics = findGraphics()
            
            graphicAccessibilityElementGroupsByID.removeAll()
            
            // Add the individual graphics in order based on the quadrant.
            for (id, graphic) in graphics {
                if let hints = graphic.accessibilityHints {
                    if hints.makeAccessibilityElement {
                        if let groupID = hints.groupID {
                            var element: GraphicAccessibilityElement? = graphicAccessibilityElementGroupsByID[groupID]
                            
                            if element == nil {
                                element = GraphicAccessibilityElement(delegate: self, identifier: groupID, accessibilityHints: hints)
                                
                                axElements.append(element!)
                                graphic.axElement = element!
                                
                                graphicAccessibilityElementGroupsByID[groupID] = element
                            }
                            
                            if let element = element {
                                element.graphics.append(graphic.graphic)
                                graphic.axElement = element
                            }
                        } else {
                            let element = GraphicAccessibilityElement(delegate: self, identifier: id, accessibilityHints: hints)
                            
                            element.graphics = [graphic.graphic]
                            
                            axElements.append(element)
                            graphic.axElement = element
                        }
                    }
                }
            }
            
            return axElements
        }
    }
    
    private func _addBGElement(frame: CGRect, label: String, elementCount: Int, custom: Bool = false) {
        let element = BackgroundAccessibilityElement(delegate: self)
        
        var axFrame = UIAccessibility.convertToScreenCoordinates(frame, in: view!)
        if let window = view!.window {
            // Constrain AX frame to visible part of the view (as determined by its window).
            let windowAXFrame = UIAccessibility.convertToScreenCoordinates(window.bounds, in: window)
            axFrame = axFrame.intersection(windowAXFrame)
        }
        element.accessibilityFrame = axFrame
        
        var label = label
        if elementCount > 0 && !custom {
            if (elementCount == 1) {
                label = String(format: NSLocalizedString("%@, %d graphic found.", tableName: "SPCScene", comment: "AX label: count of graphics (singular)."), label, elementCount)
            }
            else {
                label = String(format: NSLocalizedString("%@, %d graphics found.", tableName: "SPCScene", comment: "AX label: count of graphics (plural)."), label, elementCount)
            }
        }
        
        element.accessibilityLabel = label
        if connectedToUserProcess && !custom {
            element.accessibilityHint = NSLocalizedString("Double-press to toggle direct interaction", tableName: "SPCScene", comment: "AX label")
        }
        element.accessibilityIdentifier = "LiveViewScene.main"
        axSceneElement = element
        axElements.append(element)
    }
    
    public var axSceneElement: UIAccessibilityElement?
}

extension InternalScene: AudioPlaybackDelegate {
    // MARK: AudioPlaybackDelegate
    public func audioSession(_ session: AudioSession, isPlaybackBlocked: Bool) {
        
        if isPlaybackBlocked {
            // Pause background audio if the audio session is blocked, for example, by the app going into the background.
            audioController.pauseBackgroundAudioLoop()
            audioController.stopAllPlayersExceptBackgroundAudio()
        } else {
            // Resume if audio session is unblocked, assuming audio is enabled.
            if audioController.isBackgroundAudioEnabled {
                audioController.resumeBackgroundAudioLoop()
            }
        }
    }
}

// MARK: BackgroundContainerNode
private class BackgroundContainerNode : SKSpriteNode {
    var transparencyNode : SKTileMapNode?
    var gridNode : SKSpriteNode?
    var userBackgroundNode : SKSpriteNode?
    var overlayNode = SKSpriteNode()
    
    private let axisLabelSize = CGSize(width: 100, height: 25)
    
    var backgroundColor : UIColor? {
        didSet {
            if let color = backgroundColor {
                self.color = color
                transparencyNode?.isHidden = true
            }
            else {
                self.color = UIColor.clear
                transparencyNode?.isHidden = (backgroundImage == nil)
            }
            update()
        }
    }
    
    var backgroundImage : Image? {
        didSet {
            if let image = backgroundImage {
                if transparencyNode == nil {
                    transparencyNode = self.transparentTileNode()
                    insertChild(transparencyNode!, at: 0)
                }
                
                if userBackgroundNode == nil  {
                    userBackgroundNode = SKSpriteNode()
                    insertChild(userBackgroundNode!, at: 1)
                }
                
                let texture = InternalGraphic.texture(for: image, type: .background)
                // When changing the texture on an SKSpriteNode, one must always reset the scale back to 1.0 first. Otherwise, strange additive scaling effects can occur.
                userBackgroundNode?.xScale = 1.0
                userBackgroundNode?.yScale = 1.0
                userBackgroundNode?.texture = texture
                userBackgroundNode?.size = texture.size()
                
                let wRatio = sceneSize.width / texture.size().width
                let hRatio = sceneSize.height / texture.size().height
                
                // Aspect fit the image if needed
                if (wRatio < 1.0 || hRatio < 1.0) {
                    let ratio = min(wRatio, hRatio)
                    userBackgroundNode?.xScale = ratio
                    userBackgroundNode?.yScale = ratio
                }
                
                transparencyNode?.isHidden = (backgroundColor != nil)
                userBackgroundNode?.isHidden = false
            }
            else {
                // Cleared the image
                userBackgroundNode?.isHidden = true
                transparencyNode?.isHidden = true
            }
            update()
        }
    }
    
    var overlayImage : Image? {
        didSet {
            if let image = overlayImage {
                let texture = InternalGraphic.texture(for: image, type: .background)
                overlayNode.texture = texture
                overlayNode.size = texture.size()
            }
            update()
        }
    }
    
    var isGridOverlayVisible: Bool = false {
        didSet {
            gridNode?.removeFromParent()
            if isGridOverlayVisible {
                if gridNode == nil  {
                    gridNode = SKSpriteNode(texture: SKTexture(imageNamed: "gridLayout"), color: Color.clear, size: sceneSize)
                }
                addChild(gridNode!)
            } else {
                if let gridNode = gridNode {
                    removeChildren(in: [gridNode])
                    
                    self.gridNode = nil
                }
            }
            
            update()
        }
    }
    
    func update() {
        self.isHidden = (backgroundColor == nil && backgroundImage == nil && overlayImage == nil && isGridOverlayVisible == false)
    }
    
    init() {
        super.init(texture: nil, color: Color.clear, size: sceneSize)
        addChild(overlayNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func transparentTileNode() -> SKTileMapNode {
        let texture = SKTexture(imageNamed: "transparent_background")
        let tileDefinition = SKTileDefinition(texture: texture)
        let tileGroup = SKTileGroup(tileDefinition: tileDefinition)
        let tileSet = SKTileSet(tileGroups: [tileGroup], tileSetType: .grid)
        let tileMapNode = SKTileMapNode(tileSet: tileSet, columns: Int(CGFloat(sceneSize.width) / tileDefinition.size.width) + 1,
                                        rows: Int(CGFloat(sceneSize.height) / tileDefinition.size.height) + 1, tileSize: texture.size(), fillWith: tileGroup)
        tileMapNode.name = "transparentBackgroundNode"
        
        return tileMapNode
    }
}

extension Dictionary {
    fileprivate var tupleContents: [(Key, Value)] {
        return self.map { ($0.key, $0.value) }
    }
}

extension SKNode {
    func childNode(withId id: String) -> InternalGraphic? {
        for child in self.children {
            if let graphic = child as? InternalGraphic, graphic.id == id {
                return graphic
            }
        }
        return nil
    }
}

private protocol BackgroundAccessibilityElementDelegate {
    func accessibilityActivate(element: BackgroundAccessibilityElement) -> Bool
}

private class BackgroundAccessibilityElement : UIAccessibilityElement {
    let delegate: BackgroundAccessibilityElementDelegate
    init(delegate: BackgroundAccessibilityElementDelegate) {
        self.delegate = delegate
        super.init(accessibilityContainer: delegate)
    }
    public override func accessibilityActivate() -> Bool {
        return delegate.accessibilityActivate(element: self)
    }
}

extension Accessibility {
    public static func shiftFocus(to element: BaseGraphic) {
        UIAccessibility.post(notification: .layoutChanged, argument: element)
    }
    
    public static func screenChanged(to element: UIAccessibilityElement) {
        UIAccessibility.post(notification: .screenChanged, argument: element)
    }
}
