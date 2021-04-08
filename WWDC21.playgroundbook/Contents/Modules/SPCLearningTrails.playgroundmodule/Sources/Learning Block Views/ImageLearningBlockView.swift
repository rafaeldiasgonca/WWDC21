//
//  ImageLearningBlockView.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import PDFKit
import SPCCore

public protocol ImageLearningBlockViewDelegate {
    func didLoadImage(_ imageBlockView: ImageLearningBlockView)
    func didTapFullscreenButton(_ imageBlockView: ImageLearningBlockView, screenRect: CGRect)
    func didTapHotspot(_ imageBlockView: ImageLearningBlockView, hotspot: LearningInteractive.Hotspot, screenRect: CGRect)
}

public class ImageLearningBlockView: UIView {
    public var learningBlock: LearningBlock?
    public var style: LearningBlockStyle?
    public var textStyle: AttributedStringStyle?

    public let imageView = UIImageView()
    public let coverView = UIView()
    private let zoomButton = UIButton()
    private var hotspotButtons = [HotspotButton : LearningInteractive.Hotspot]()
    private var statusTextView: UITextView?
    private let buttonSize = CGSize(width: 30, height: 30)
    private let buttonOffset: CGFloat = 8
    private let hotspotSize = CGSize(width: 30, height: 30)
    
    // Default Specified size: see below.
    private var defaultSizeRelativeToWidth = CGSize(width: -1, height: 0.35)
    
    // Specified size (normalized) for the content relative to the width of the block.
    // The content is aspect-fitted within the specified size.
    // Size width and height values are normalized, and both are relative to the width. -1 => unspecified.
    // Examples:
    //      (width: -1, height: 0.5) => the height of the image is to be 0.5 times the width of the block.
    //      (width: 0.8, height: -1) => the width of the image is to be 0.8 times the width of the block.
    // Note that when the width is specified, the block may change size once the image is loaded as it has to calculate the height based on the image aspect ratio.
    private var specifiedSizeRelativeToWidth = CGSize(width: -1, height: -1)
    
    private var interactive: LearningInteractive?
    
    private var imageDescription: String?
    
    private var pdfDocument: PDFDocument?

    public var image: UIImage? {
        return imageView.image
    }
    
    private var isZoomable = false
    
    // Background color resolved for current light/dark mode.
    private var backgroundFillColor: UIColor {
        let color = backgroundColor ?? UIColor.systemBackgroundLT
        if #available(iOS 13.0, *) {
            return color.resolvedColor(with: traitCollection)
        } else {
            return color
        }
    }
    
    public var isZoomed = false {
        didSet {
            let image = isZoomed ? UIImage(named: "zoom-out-icon") : UIImage(named: "zoom-in-icon")
            zoomButton.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
            updateAX()
        }
    }
    
    public func setHotspotsVisible(_ visible: Bool, animated: Bool = false) {
        let completion: ((Bool) -> Void) = { _ in
            for button in self.hotspotButtons.keys {
                button.isHidden = !visible
            }
        }
        
        guard animated else {
            completion(true)
            return
        }
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut] , animations: {
            for button in self.hotspotButtons.keys {
                button.alpha = visible ? 1.0 : 0.0
            }
        }, completion: completion)
    }
    
    public func setZoomButtonVisible(_ visible: Bool, animated: Bool = false) {
        let completion: ((Bool) -> Void) = { _ in
            self.zoomButton.isHidden = !visible
            self.zoomButton.isAccessibilityElement = visible
        }
        
        guard animated else {
            completion(true)
            return
        }
        
        UIView.animate(withDuration: 1.0, delay: 0, options: [.curveEaseInOut] , animations: {
            self.zoomButton.alpha = visible ? 1.0 : 0.0
        }, completion: completion)
    }
    
    public var delegate: ImageLearningBlockViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        addSubview(zoomButton)
                
        coverView.layer.borderColor = UIColor.red.cgColor
        coverView.layer.borderWidth = 2.0
        
        imageView.contentMode = .scaleAspectFit
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        zoomButton.backgroundColor = UIColor.clear
        zoomButton.isHidden = true
        zoomButton.addTarget(self, action: #selector(didPressFullscreenButton), for: .touchUpInside)
        
        isAccessibilityElement = false // Accessibility container

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onDoubleTap(recognizer:)))
        gestureRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(gestureRecognizer)
        
        defer {
            // Defer so that isZoomed didSet gets called.
            self.isZoomed = false
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else {
            return
        }

        if let document = self.pdfDocument {
            // Re-render PDF with appropriate background color for current light/dark mode.
            loadPDF(document, backgroundColor: self.backgroundFillColor)
        }
    }
    
    // Load an image.
    public func load(imageName: String) {
                
        // Completion closure to be called whenever the image is successfully loaded.
        let completion = {
            self.setNeedsLayout()
            self.layoutIfNeeded()
            self.delegate?.didLoadImage(self)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Display hotspots and zoom button. If zoomed, this happens later, after the zoom transition.
                if !self.isZoomed {
                    self.setHotspotsVisible(true, animated: true)
                    self.setZoomButtonVisible(self.isZoomable, animated: true)
                }
            }
        }
            
        if imageName.lowercased().hasSuffix(".pdf") {
            // Load a PDF document.
            guard let imageURL = Bundle.main.url(forResource: imageName, withExtension: nil) else {
                PBLog("Failed to locate image named: \(imageName)")
                return
            }
            guard let document = PDFDocument(url: imageURL) else {
                PBLog("Failed to load PDF document from: \(imageURL)")
                return
            }
            
            self.pdfDocument = document
            
            loadPDF(document, backgroundColor: backgroundFillColor, completion: completion)
        } else {
            // Load an image.
            loadImage(imageName, completion: completion)
        }
    }
    
    // Load image asynchronously.
    private func loadImage(_ imageName: String, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            let newImage = UIImage(named: imageName)
            guard let image = newImage else {
                PBLog("Failed to load image named: \(imageName)")
                return
            }
            DispatchQueue.main.async {
                self.imageView.image = image
                completion?()
            }
        }
    }
    
    // Load PDF asynchronously.
    private func loadPDF(_ document: PDFDocument, backgroundColor: UIColor, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let page = document.page(at: 0) else { return }
            let rect = page.bounds(for: PDFDisplayBox.mediaBox).applying(page.transform(for: .mediaBox))
            let renderer = UIGraphicsImageRenderer(size: rect.size)
            
            let image = renderer.image(actions: { context in
                let cgContext = context.cgContext
                let rect = cgContext.boundingBoxOfClipPath

                cgContext.setFillColor(backgroundColor.cgColor)
                cgContext.fill(rect)
                cgContext.translateBy(x: 0, y: rect.size.height)
                cgContext.scaleBy(x: 1, y: -1)
                
                page.draw(with: PDFDisplayBox.mediaBox, to: cgContext)
            })

            DispatchQueue.main.async {
                self.imageView.image = image
                completion?()
            }
        }
    }
    
    public func load(interactive: LearningInteractive) {
        guard let learningBlock = learningBlock else { return }
        self.interactive = interactive
        for (index, hotspot) in interactive.hotspots.enumerated() {
            let button = HotspotButton(hotspot: hotspot)
            button.addTarget(self, action: #selector(didPressHotspotButton), for: .touchUpInside)
            button.isHidden = true
            button.accessibilityIdentifier = "\(learningBlock.accessibilityIdentifier).hotspot\(index + 1)"
            imageView.addSubview(button)
            imageView.isUserInteractionEnabled = true
            hotspotButtons[button] = hotspot
        }
    }
    
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        // Start with a square width x width: the size returned will never be larger than this.
        let availableSize = CGSize(width: size.width, height: size.width)
        var returnSize = availableSize
        
        if specifiedSizeRelativeToWidth.height >= 0 {
            // Height is specified => sufficient to fully determine size.
            returnSize.height = min(availableSize.width * specifiedSizeRelativeToWidth.height, availableSize.width)
        }
        
        // Add any margins.
        returnSize.width += (layoutMargins.left + layoutMargins.right)
        returnSize.height += (layoutMargins.top + layoutMargins.bottom)
        return returnSize
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        guard let image = imageView.image else { return }
        let availableBounds = bounds.inset(by: layoutMargins)
        imageView.frame = availableBounds
        let imageFittedSize = image.size.scaledToFit(within: availableBounds.size)
        let imageFittedFrame = CGRect(x: (availableBounds.size.width - imageFittedSize.width) / 2, y: (availableBounds.size.height - imageFittedSize.height) / 2, width: imageFittedSize.width, height: imageFittedSize.height)
        
        coverView.frame = imageFittedFrame
        
        var zoomButtonPosition = CGPoint.zero
        zoomButtonPosition.x = min(imageFittedFrame.maxX + 10 + (buttonSize.width / 2), imageView.bounds.size.width - (buttonSize.width / 2) - 10)
        zoomButtonPosition.y =  max(imageFittedFrame.minY + (buttonSize.width / 2), (buttonSize.width / 2) )
        zoomButtonPosition.x += imageView.frame.minX
         zoomButtonPosition.y += imageView.frame.minY
        zoomButton.frame = CGRect(origin: CGPoint.zero, size: buttonSize)
        zoomButton.center = zoomButtonPosition
        
        for (button, hotspot) in hotspotButtons {
            let position = CGPoint(x: imageFittedFrame.minX + (hotspot.position.x * imageFittedSize.width),
                                   y: imageFittedFrame.minY + (hotspot.position.y * imageFittedSize.height))
            button.frame = CGRect(origin: CGPoint.zero, size: hotspotSize)
            button.center = position
        }
    }
    
    // Returns the image view frame in screen coordinates.
    private func rectInScreenCoordinateSpaceFor(frame: CGRect) -> CGRect {
        return convert(frame, to: nil)
    }
    
    private func goFullScreen() {
        let screenRect = rectInScreenCoordinateSpaceFor(frame: self.frame)
        delegate?.didTapFullscreenButton(self, screenRect: screenRect)
    }
    
    private func updateAX() {
        let hotspotViews = hotspotButtons.keys.map { $0 as UIView }
        accessibilityElements = [imageView, zoomButton] + hotspotViews
        
        guard let learningBlock = learningBlock else { return }
        let state = isZoomed ? ".zoomed" : ".unzoomed"
        imageView.accessibilityIdentifier = learningBlock.accessibilityIdentifier + state
        imageView.accessibilityTraits = .image
        imageView.accessibilityLabel = imageDescription
        imageView.isAccessibilityElement = true
        zoomButton.accessibilityIdentifier = "\(learningBlock.accessibilityIdentifier).zoombutton" + state
        if isZoomed {
            zoomButton.accessibilityLabel = NSLocalizedString("Zoom out", tableName: "SPCLearningTrails", comment: "AX label for zoom-out button in image block")
            zoomButton.accessibilityHint = NSLocalizedString("Makes the image smaller again.", tableName: "SPCLearningTrails", comment: "AX hint for zoom-out button in image block.")
        } else {
            zoomButton.accessibilityLabel = NSLocalizedString("Zoom in", tableName: "SPCLearningTrails", comment: "AX label for zoom-in button in image block")
            zoomButton.accessibilityHint = NSLocalizedString("Makes the image bigger.", tableName: "SPCLearningTrails", comment: "AX hint for zoom-in button in image block.")
        }
        zoomButton.isAccessibilityElement = isZoomable
    }
    
    private func showMessage(_ message: String) {
        if statusTextView == nil {
            let textView = UITextView()
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.textColor = .yellow
            textView.font = UIFont.systemFont(ofSize: 14.0)
            textView.backgroundColor = .darkGray
            textView.alpha = 0.75
            textView.textAlignment = .center
            textView.isHidden = true
            textView.isScrollEnabled = false
            addSubview(textView)
            
            NSLayoutConstraint.activate([
                textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
                textView.leadingAnchor.constraint(equalTo: leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: trailingAnchor),
                ])
            
            self.statusTextView = textView
        }
        guard let statusTextView = statusTextView else { return }
        statusTextView.text = message
        statusTextView.isHidden = false
        statusTextView.sizeToFit()
    }
    
    // MARK: Actions

    @objc
    func didPressFullscreenButton(_ sender: UIButton) {
        guard isZoomable else { return }
        goFullScreen()
    }
    
    @objc
    func onDoubleTap(recognizer: UITapGestureRecognizer) {
        guard isZoomable else { return }
        goFullScreen()
    }

    @objc
    func didPressHotspotButton(_ sender: UIButton) {
        guard let hotspotButton = sender as? HotspotButton, let hotspot = hotspotButton.hotspot else { return }
        var screenRect = rectInScreenCoordinateSpaceFor(frame: sender.frame)
        screenRect.origin.x += imageView.frame.origin.x
        screenRect.origin.y += imageView.frame.origin.y
        delegate?.didTapHotspot(self, hotspot: hotspot, screenRect: screenRect)
    }
}

// MARK: LearningBlockViewable
extension ImageLearningBlockView: LearningBlockViewable {
    public func load(learningBlock: LearningBlock, style: LearningBlockStyle, textStyle: AttributedStringStyle? = nil) {
        self.learningBlock = learningBlock
        self.style = style
        self.textStyle = textStyle
        
        directionalLayoutMargins = style.margins
        backgroundColor = style.backgroundColor

        guard let imageFilename = learningBlock.attributes["source"] else { return }
        
        if let widthValue = learningBlock.attributes["width"] {
            if let width = Float(widthValue) {
                specifiedSizeRelativeToWidth.width = CGFloat(width)
                
                if let aspectRatioValue = learningBlock.attributes["aspect"] {
                    let aspectRatioValues = aspectRatioValue.components(separatedBy: ":")
                    if aspectRatioValues.count == 1 {
                        if let aspect = Float(aspectRatioValues[0]) {
                            specifiedSizeRelativeToWidth.height = CGFloat(Float(1.0)/aspect) * CGFloat(width)
                        }
                    }
                    if aspectRatioValues.count == 2 {
                        if let widthValue = Float(aspectRatioValues[0]), let heightValue = Float(aspectRatioValues[1]) {
                            specifiedSizeRelativeToWidth.height = CGFloat(heightValue/widthValue) * CGFloat(width)
                        }
                    }
                } else {
                    // No aspect ratio specified => ignore width and revert to default.
                    specifiedSizeRelativeToWidth = defaultSizeRelativeToWidth
                    // Display a warning.
                    let message = String(format: NSLocalizedString("⚠️ width (%@) specified without aspect: specify both, or height on its own.", tableName: "SPCLearningTrails", comment: "Warning message for image block"), widthValue)
                    showMessage(message)
                }
            }
        }
        
        if let heightValue = learningBlock.attributes["height"] {
            if let height = Float(heightValue) {
                specifiedSizeRelativeToWidth.height = CGFloat(height)
            }
        }
        
        if specifiedSizeRelativeToWidth.width == -1 && specifiedSizeRelativeToWidth.height == -1 {
            specifiedSizeRelativeToWidth = defaultSizeRelativeToWidth
        }
        
        if let zoomableValue = learningBlock.attributes["zoomable"], let zoomable = Bool(zoomableValue) {
            isZoomable = zoomable
        }

        let blockXML = "<block>\(learningBlock.content)</block>"
        
        if let descriptionElement = SlimXMLParser.getElementsIn(xml: blockXML, named: "description").first {
            imageDescription = descriptionElement.content
        }
        
        if let interactiveElement = SlimXMLParser.getElementsIn(xml: blockXML, named: "interactive").first {
            let interactiveXML = "<interactive>\(interactiveElement.content)</interactive>"
            if let interactive = LearningInteractive(xml: interactiveXML) {
                self.load(interactive: interactive)
            }
        }
        
        updateAX()

        DispatchQueue.main.async {
            self.load(imageName: imageFilename)
        }
    }
}
