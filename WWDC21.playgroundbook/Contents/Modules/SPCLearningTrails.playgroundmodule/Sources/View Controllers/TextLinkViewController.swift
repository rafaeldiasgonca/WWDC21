//
//  TextLinkViewController.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

class TextLinkViewController: UIViewController {
    
    let linkLabel = UILabel()
    
    var link: String = "" {
        didSet {
            linkLabel.text = link
        }
    }
    
    override var preferredContentSize: CGSize {
        get {
            return CGSize(width: 200, height: 40)
        }
        set { super.preferredContentSize = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.cornerRadius = 20
        linkLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        linkLabel.frame = view.bounds
        linkLabel.textAlignment = .center
        linkLabel.adjustsFontSizeToFitWidth = true
        linkLabel.adjustsFontForContentSizeCategory = true
        view.addSubview(linkLabel)
    }
    
    static func present(link: String, from viewController: UIViewController, sourceRect: CGRect, sourceView: UIView) {
        
        let textLinkViewController = TextLinkViewController()
        textLinkViewController.modalPresentationStyle = UIModalPresentationStyle.popover
        textLinkViewController.link = link
        
        let arrowGapInset: CGFloat = -4 // Gap between arrow and sourceRect.
        
        // Specify the location and arrow direction of the popover.
        let popoverPresentationController = textLinkViewController.popoverPresentationController
        popoverPresentationController?.backgroundColor = textLinkViewController.view.backgroundColor
        popoverPresentationController?.sourceView = sourceView
        let permittedArrowDirections: UIPopoverArrowDirection = [.any]
        popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        popoverPresentationController?.sourceRect = sourceRect.insetBy(dx: arrowGapInset, dy: arrowGapInset)
        
//        if let ppcDelegate = viewController as? UIPopoverPresentationControllerDelegate {
//            popoverPresentationController?.delegate = ppcDelegate
//        } else {
//            popoverPresentationController?.delegate = textLinkViewController
//        }
        
        viewController.present(textLinkViewController, animated: true) {
            
        }
    }

}
