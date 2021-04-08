//
//  LearningBlockCell.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

public protocol LearningBlockCellDelegate {
    func cell(_ cell: LearningBlockCell, didChangeDisclosedState disclosed: Bool)
    func cell(_ cell: LearningBlockCell, didChangeVisibleState visible: Bool)
    func cell(_ cell: LearningBlockCell, didRaiseAction url: URL, at rect: CGRect?)
    func cell(_ cell: LearningBlockCell, didSubmitResponseFor learningResponse: LearningResponse)
    func cell(_ cell: LearningBlockCell, didRequestZoomImage imageBlockView: ImageLearningBlockView, at screenRect: CGRect)
    func cellNeedsRefresh(_ cell: LearningBlockCell)
}

public class LearningBlockCell: UIView {
    private let buttonSize = CGSize(width: 30, height: 30)

    private var learningBlockViewHeightConstraint: NSLayoutConstraint?

    public var isVisible: Bool = false {
        didSet {
            if let learningBlockView = learningBlockView {
                learningBlockView.isHidden = !isVisible
            }
            setNeedsUpdateConstraints()
            delegate?.cell(self, didChangeVisibleState: isVisible)
        }
    }
    
    public override var accessibilityElementsHidden: Bool {
        get {
            // Accessible elements are available :
            // a) if the block cell is visible
            // b) if the block view reports that it should be visible to accessibility.
            if isVisible, let learningBlockView = learningBlockView {
                return !learningBlockView.isVisibleToAccessibility
            }
            return true
        }
        set { }
    }

    public var learningBlock: LearningBlock?
    
    public var delegate: LearningBlockCellDelegate?
        
    public var learningBlockView: LearningBlockView? {
        didSet {
            if let existingLearningBlockView = oldValue {
                learningBlockViewHeightConstraint?.isActive = false
                existingLearningBlockView.removeFromSuperview()
            }
            
            guard let learningBlockView = learningBlockView else { return }
            isLoaded = true
            
            // Ensures that view doesn't leave artifacts during table view animations.
            learningBlockView.clipsToBounds = true
            
            learningBlockView.isHidden = !isVisible
            addSubview(learningBlockView)
            
            learningBlockView.translatesAutoresizingMaskIntoConstraints = false
            
            learningBlockViewHeightConstraint?.isActive = false
            learningBlockViewHeightConstraint = learningBlockView.heightAnchor.constraint(equalToConstant: 0)
            learningBlockViewHeightConstraint?.priority = .defaultHigh

            NSLayoutConstraint.activate([
                learningBlockView.topAnchor.constraint(equalTo: topAnchor),
                learningBlockView.leadingAnchor.constraint(equalTo: leadingAnchor),
                learningBlockView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])

            learningBlockViewHeightConstraint?.isActive = true
            
            setNeedsUpdateConstraints()
        }
    }
    
    public var isLoaded: Bool = false

    public convenience init(learningBlock: LearningBlock) {
        self.init(frame: CGRect.zero)
        
        self.learningBlock = learningBlock
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initialize() {
        backgroundColor = UIColor.systemBackgroundLT
        isAccessibilityElement = false
    }

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        if !isVisible {
            learningBlockViewHeightConstraint?.constant = 0.5
            return CGSize(width: size.width, height: 0.5)
        }

        guard let learningBlockView = learningBlockView else { return size }
        let blockViewSize = learningBlockView.sizeThatFits(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
        
        learningBlockViewHeightConstraint?.constant = blockViewSize.height

        return CGSize(width: size.width, height: blockViewSize.height)
    }
    
    override public func updateConstraints() {
        super.updateConstraints()
    }
}

extension LearningBlockCell: LearningBlockViewDelegate {
    
    public func didTapLink(blockView: LearningBlockView, url: URL, linkRect: CGRect) {
        delegate?.cell(self, didRaiseAction: url, at: linkRect)
    }
}

extension LearningBlockCell: ImageLearningBlockViewDelegate {

    public func didLoadImage(_ imageBlockView: ImageLearningBlockView) {
        setNeedsUpdateConstraints()
        delegate?.cellNeedsRefresh(self)
    }
    
    public func didTapFullscreenButton(_ imageBlockView: ImageLearningBlockView, screenRect: CGRect) {
        delegate?.cell(self, didRequestZoomImage: imageBlockView, at: screenRect)
    }
    
    public func didTapHotspot(_ imageBlockView: ImageLearningBlockView, hotspot: LearningInteractive.Hotspot, screenRect: CGRect) {
        guard let delegateViewController = delegate as? UIViewController else { return }
        guard let hotspotXML = hotspot.xmlText else { return }
        guard let textStyle = imageBlockView.textStyle else { return }
        let attributedText = NSAttributedString(xml: "<text>\(hotspotXML)</text>", style: textStyle)
        
        var sourceView: UIView = self
        var sourceRect = self.convert(screenRect, from: nil)
        var currentViewController = delegateViewController
        if let presentedViewController = delegateViewController.presentedViewController {
            // If the delegate view controller is presenting a view controller, present from that instead.
            currentViewController = presentedViewController
            sourceView = currentViewController.view
            sourceRect = sourceView.convert(screenRect, from: nil)
        }
        
        HotspotViewController.present(attributedString: attributedText, from: currentViewController, sourceRect: sourceRect, sourceView: sourceView, delegate: self)
    }
}

extension LearningBlockCell: GroupLearningBlockViewDelegate {
    
    func groupBlockView(_ groupBlockView: GroupLearningBlockView, didChangeDisclosedState disclosed: Bool) {
        delegate?.cell(self, didChangeDisclosedState: disclosed)
    }
}

extension LearningBlockCell: ResponseLearningBlockViewDelegate {

    
    func responseBlockView(_ responseBlockView: ResponseLearningBlockView, didSelectOption index: Int) {
        
    }
    
    func responseBlockView(_ responseBlockView: ResponseLearningBlockView, didRevealFeedbackForOption index: Int) {
        delegate?.cellNeedsRefresh(self)
    }
    
    func responseBlockView(_ responseBlockView: ResponseLearningBlockView, didSubmitResponseFor learningResponse: LearningResponse) {
        delegate?.cell(self, didSubmitResponseFor: learningResponse)
    }

}

extension LearningBlockCell: HotspotViewControllerDelegate {
    
    func didTapLink(_ hotspotViewController: HotspotViewController, url: URL, linkRect: CGRect) {
        // Dismiss the hotspot popover and then respond to the link.
        hotspotViewController.dismiss(animated: false, completion: {
            self.delegate?.cell(self, didRaiseAction: url, at: linkRect)
        })
    }
}

extension LearningBlockCell: ButtonsLearningBlockViewDelegate {
    
    public func didPressButton(_ buttonsBlockView: ButtonsLearningBlockView, button: LearningInteractive.Button, screenRect: CGRect) {
        
        if button.action == .link, let url = button.url {
            self.delegate?.cell(self, didRaiseAction: url, at: screenRect)
        }
    }
}
