//
//  VideoLearningBlockView.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit


class VideoLearningBlockView: UIView {
    public var learningBlock: LearningBlock?
    public var style: LearningBlockStyle?
    public var textStyle: AttributedStringStyle?
    
    private let defaultHeight: CGFloat = 200
    
    private var avPlayerViewController = AVPlayerViewController()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        addSubview(avPlayerViewController.view)
        avPlayerViewController.view.backgroundColor = .lightGray
        
        isAccessibilityElement = false // Accessibility container
        avPlayerViewController.view.isAccessibilityElement = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let availableSize = CGSize(width: size.width, height: defaultHeight)
        return availableSize
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        let availableBounds = bounds.inset(by: layoutMargins)
        avPlayerViewController.view.frame = availableBounds
    }

    func load(url: URL) {
        let avPlayer = AVPlayer(url: url)
        avPlayerViewController.player = avPlayer
    }
}

extension VideoLearningBlockView: LearningBlockViewable {
    public func load(learningBlock: LearningBlock, style: LearningBlockStyle, textStyle: AttributedStringStyle? = nil) {
        self.learningBlock = learningBlock
        self.style = style
        self.textStyle = textStyle
        
        accessibilityIdentifier = learningBlock.accessibilityIdentifier

        guard let name = learningBlock.attributes["source"], let videoURL = Bundle.main.url(forResource: name, withExtension: "mov") else { return }
        
        directionalLayoutMargins = style.margins
        
        if let descriptionElement = SlimXMLParser.getElementsIn(xml: learningBlock.content, named: "description").first {
            avPlayerViewController.view.accessibilityLabel = descriptionElement.content
        }
        
        DispatchQueue.main.async {
            self.load(url: videoURL)
        }
    }
}
