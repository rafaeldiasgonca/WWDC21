//
//  ImageLearningBlockPresentationViewController.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import SPCCore

class ImageLearningBlockPresentationViewController: UIViewController {
    private let backgroundView = UIView()
    let imageLearningBlockView = ImageLearningBlockView()
    
    private var initialLearningBlockFrame = CGRect.zero
    private var isPresenting = false
    private var isTransitioning = false
    
    private var imageInsetX: CGFloat = 10
    private var imageInsetY: CGFloat = 80
    
    private let buttonSize = CGSize(width: 30, height: 30)
    private let buttonOffset: CGFloat = 8
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundView.backgroundColor = .black
        backgroundView.frame = view.bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(backgroundView)
        view.addSubview(imageLearningBlockView)
        
        imageLearningBlockView.isZoomed = true
        imageLearningBlockView.insetsLayoutMarginsFromSafeArea = false

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onDoubleTap(recognizer:)))
        gestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(gestureRecognizer)
    }
    
    override public func viewWillLayoutSubviews() {
        guard !isTransitioning else { return }
        let availableBounds = view.bounds.insetBy(dx: imageInsetX, dy: imageInsetY)
        let size = initialLearningBlockFrame.size.scaledToFit(within: availableBounds.size)
        let x: CGFloat = (view.bounds.size.width - size.width) / 2.0
        let y: CGFloat = (view.bounds.size.height - size.height) / 2.0
        imageLearningBlockView.frame = CGRect(origin: CGPoint(x: x, y: y), size: size)
        dismissPresentedViewControllerIfNeeded()
    }
    
    func display(learningBlockView: ImageLearningBlockView, viewController: UIViewController, from initialFrame: CGRect) {
        
        guard
            let learningBlock = learningBlockView.learningBlock,
            let style = learningBlockView.style,
            let textStyle = learningBlockView.textStyle
            else { return }
        
        imageLearningBlockView.load(learningBlock: learningBlock, style: style, textStyle: textStyle)
        imageLearningBlockView.delegate = learningBlockView.delegate
        initialLearningBlockFrame = initialFrame
        imageLearningBlockView.frame = initialFrame
        imageLearningBlockView.setNeedsLayout()
    }
    
    static func present(imageBlockView: ImageLearningBlockView, from viewController: UIViewController, initialFrame: CGRect) {
        let ipvc = ImageLearningBlockPresentationViewController()
        ipvc.modalPresentationStyle = .custom
        ipvc.transitioningDelegate = ipvc
        ipvc.display(learningBlockView: imageBlockView, viewController: viewController, from: initialFrame)
        viewController.present(ipvc, animated: true, completion: {
            UIAccessibility.post(notification: .layoutChanged, argument: ipvc.imageLearningBlockView)
        })
    }
    
    private func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func dismissPresentedViewControllerIfNeeded() {
        self.dismiss(animated: false, completion: nil)
    }
    
    // MARK: Actions
    
    @objc
    func onDoubleTap(recognizer: UITapGestureRecognizer) {
        close()
    }
}

// MARK: UIViewControllerTransitioningDelegate
extension ImageLearningBlockPresentationViewController : UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        isPresenting = true
        return self
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = false
        return self
    }
}

// MARK: UIViewControllerAnimatedTransitioning
extension ImageLearningBlockPresentationViewController : UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromView = transitionContext.viewController(forKey: .from)?.view,
            let toView = transitionContext.viewController(forKey: .to)?.view
            else { return }
        
        toView.frame = fromView.frame
        
        isTransitioning = true
        
        // Initial pre-animation state.
        if isPresenting {
            transitionContext.containerView.addSubview(toView)
            self.backgroundView.alpha = 0
            toView.alpha = 1
        } else {
            self.backgroundView.alpha = 1
            toView.alpha = 0
            self.imageLearningBlockView.setZoomButtonVisible(false, animated: false)
        }
        
        // Final animated state.
        var backgroundViewAlpha: CGFloat = 0
        var blockFrame = initialLearningBlockFrame
        let toViewAlpha: CGFloat = 1
        if isPresenting {
            backgroundViewAlpha = 1
            
//            // The view size seems to always be 1366 x 1024 even when presentationMode is overCurrentContent
//            // in which you'd expect the view size to match that of the presenting view controller.
//            let size = image.size.scaledToFit(within: view.bounds.size)
//            imageRect = CGRect(origin: CGPoint(x: (view.bounds.size.width - size.width) / 2,
//                                               y: (view.bounds.size.height - size.height) / 2), size: size)
            
            let availableBounds = fromView.bounds.insetBy(dx: imageInsetX, dy: imageInsetY)
            let size = initialLearningBlockFrame.size.scaledToFit(within: availableBounds.size)
            blockFrame = CGRect(origin: CGPoint(x: (fromView.bounds.size.width - size.width) / 2,
                                                              y: (fromView.bounds.size.height - size.height) / 2), size: size)
        }
        
        let duration = self.transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut, .layoutSubviews] , animations: {
            self.backgroundView.alpha = backgroundViewAlpha
            self.imageLearningBlockView.frame = blockFrame
            toView.alpha = toViewAlpha
        }, completion: { _ in
            transitionContext.completeTransition(true)
            self.isTransitioning = false
            self.imageLearningBlockView.setHotspotsVisible(true, animated: true)
            self.imageLearningBlockView.setZoomButtonVisible(true, animated: true)
            
            if !self.isPresenting {
                fromView.removeFromSuperview()
            }
        })
    }
}

extension ImageLearningBlockPresentationViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

