//
//  StepAnimator.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

class CustomInteractor: UIPercentDrivenInteractiveTransition {
    var navigationController : UINavigationController
    var shouldCompleteTransition = false
    var transitionInProgress = false
    
    init?(attachTo viewController : UIViewController) {
        if let nav = viewController.navigationController {
            self.navigationController = nav
            super.init()
            setupBackGesture(view: viewController.view)
        } else {
            return nil
        }
    }

    private func setupBackGesture(view : UIView) {
        let swipeBackGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleBackGesture(_:)))
        swipeBackGesture.edges = .left
        view.addGestureRecognizer(swipeBackGesture)
    }
    
    @objc private func handleBackGesture(_ gesture : UIScreenEdgePanGestureRecognizer) {
        let viewTranslation = gesture.translation(in: gesture.view?.superview)
        let progress = viewTranslation.x / self.navigationController.view.frame.width
        
        switch gesture.state {
        case .began:
            transitionInProgress = true
            navigationController.popViewController(animated: true)
            break
        case .changed:
            shouldCompleteTransition = progress > 0.5
            update(progress)
            break
        case .cancelled:
            transitionInProgress = false
            cancel()
            break
        case .ended:
            transitionInProgress = false
            shouldCompleteTransition ? finish() : cancel()
            break
        default:
            return
        }
    }
}

protocol StepAnimatable {
    var headerView: UIView { get }
    var headerViews: [UIView] { get }
    var contentView: UIView { get }
}

class StepAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    var duration: TimeInterval
    var isPresenting: Bool
    
    init(duration : TimeInterval, isPresenting : Bool) {
        self.duration = duration
        self.isPresenting = isPresenting
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? UIViewController & StepAnimatable,
        let toViewController = transitionContext.viewController(forKey: .to) as? UIViewController & StepAnimatable,
        let fromView = transitionContext.view(forKey: .from),
        let toView = transitionContext.view(forKey: .to) else { return }
        
        if isPresenting {
            container.addSubview(toView)
        } else {
            container.insertSubview(toView, belowSubview: fromView)
        }
        
        toView.frame = fromView.frame
        toView.layoutIfNeeded()
        
        let fromContentView = fromViewController.contentView
        let toContentView = toViewController.contentView
        let fromHeaderView = fromViewController.headerView
        let toHeaderView = toViewController.headerView
        
        let offscreenTransform = isPresenting ?
            CGAffineTransform(translationX: fromView.frame.width / 2, y: 0) :
            CGAffineTransform(translationX: -fromView.frame.width / 2, y: 0)
        
        toContentView.transform = offscreenTransform // This always starts offscreen
        toViewController.headerViews.forEach { $0.transform = offscreenTransform } // These always start offscreen
        toContentView.alpha = 0 // This always animates from 0 to 1
        
        if isPresenting {
            toHeaderView.alpha = 0
        }
        
        let easeInOutTiming = UICubicTimingParameters(animationCurve: .easeInOut)
        let slideOutAnimator = UIViewPropertyAnimator(duration: duration / 2, timingParameters: easeInOutTiming)
        slideOutAnimator.addAnimations {
            let transform = self.isPresenting ?
                CGAffineTransform(translationX: -fromView.frame.width, y: 0) :
                CGAffineTransform(translationX: fromView.frame.width, y: 0)
            fromContentView.transform = transform
            
            fromViewController.headerViews.forEach { $0.transform = transform }
        }
        
        slideOutAnimator.startAnimation()
        
        let slideInAnimator = UIViewPropertyAnimator(duration: duration * 4 / 5, timingParameters: easeInOutTiming)
        slideInAnimator.addAnimations {
            toContentView.transform = .identity
            toContentView.alpha = 1
            toViewController.headerViews.forEach { $0.transform = .identity }
        }
        slideInAnimator.startAnimation()
        
        let fadeHeaderAnimator = UIViewPropertyAnimator(duration: duration, timingParameters: easeInOutTiming)
        fadeHeaderAnimator.addAnimations {
            if self.isPresenting {
                toHeaderView.alpha = 1
            } else {
                fromHeaderView.alpha = 0
            }
        }
        
        fadeHeaderAnimator.addCompletion { (position) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

            // Views are maintained on the navigation stack, so reset alpha and transforms
        }
        
        fadeHeaderAnimator.startAnimation()
    }
}
