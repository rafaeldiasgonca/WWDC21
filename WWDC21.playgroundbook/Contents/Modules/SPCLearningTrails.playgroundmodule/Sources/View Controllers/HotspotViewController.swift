//
//  HotspotViewController.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

protocol HotspotViewControllerDelegate {
    func didTapLink(_ hotspotViewController: HotspotViewController, url: URL, linkRect: CGRect)
}

class HotspotViewController: UIViewController {
    let textView = LTTextView()
    private let widthLimit: CGFloat = 420
    private var maximumWidth: CGFloat = 200
    private let textInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    
    var attributedString: NSAttributedString = NSAttributedString() {
        didSet {
            textView.attributedText = attributedString
        }
    }
    
    var delegate: HotspotViewControllerDelegate?
    
    // A closure to be called when the view controller is dismissed.
    var onDismissed : (() -> Void)?
    
    override var preferredContentSize: CGSize {
        get {
            return view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        }
        set { super.preferredContentSize = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.directionalLayoutMargins = NSDirectionalEdgeInsets.zero
        textView.textContainerInset = textInsets
        textView.ltTextViewDelegate = self
        textView.backgroundColor = UIColor.tertiarySystemBackgroundLT
        view.backgroundColor = textView.backgroundColor
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        let marginsWidthConstraint = textView.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor)
        marginsWidthConstraint.priority = .fittingSizeLevel + 1
        let maximumWidthConstraint = textView.widthAnchor.constraint(lessThanOrEqualToConstant: maximumWidth)
        maximumWidthConstraint.priority = .required
        
        NSLayoutConstraint.activate([
            textView.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
            marginsWidthConstraint,
            maximumWidthConstraint,
            textView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
        ])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismissed?()
    }
    
    static func present(attributedString: NSAttributedString, from viewController: UIViewController, sourceRect: CGRect, sourceView: UIView, delegate: HotspotViewControllerDelegate?) {
        let hotspotViewController = HotspotViewController()
        hotspotViewController.modalPresentationStyle = UIModalPresentationStyle.popover
        hotspotViewController.delegate = delegate
        hotspotViewController.attributedString = attributedString
        
        hotspotViewController.maximumWidth = min(viewController.view.frame.width * 0.6, hotspotViewController.widthLimit)
        
        let arrowGapInset: CGFloat = -4 // Gap between arrow and sourceRect.
        
        // Specify the location and arrow direction of the popover.
        let popoverPresentationController = hotspotViewController.popoverPresentationController
        popoverPresentationController?.backgroundColor = hotspotViewController.view.backgroundColor
        popoverPresentationController?.sourceView = sourceView
        let permittedArrowDirections: UIPopoverArrowDirection = [.any]
        popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        popoverPresentationController?.sourceRect = sourceRect.insetBy(dx: arrowGapInset, dy: arrowGapInset)
        
        hotspotViewController.onDismissed = {
            // On dismissal set the AX focus back to the image block.
            UIAccessibility.post(notification: .layoutChanged, argument: sourceView)
        }
        
        if let viewController = viewController as? UIPopoverPresentationControllerDelegate {
            hotspotViewController.popoverPresentationController?.delegate = viewController
        }
        
        viewController.present(hotspotViewController, animated: true) {
            UIAccessibility.post(notification: .layoutChanged, argument: hotspotViewController.textView)
        }
    }
}

extension HotspotViewController: LTTextViewDelegate {
    
    func didTapLink(_ ltTextView: LTTextView, url: URL, linkRect: CGRect) {
        delegate?.didTapLink(self, url: url, linkRect: linkRect)
    }
}
