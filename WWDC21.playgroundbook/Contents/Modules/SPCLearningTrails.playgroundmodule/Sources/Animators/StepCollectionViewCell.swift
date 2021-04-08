//
//  StepCollectionViewCell.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

protocol CustomCellAnimatable {
    var headerView: LearningStepHeaderView { get }
    var headerTitle: UILabel { get }
    var contentView: UIView { get }
}

final class StepCollectionViewCell: UICollectionViewCell {
    
    private weak var stepViewController: LearningStepViewController?
        
    func configure(with viewController: LearningStepViewController) {
        
        if let subview = contentView.subviews.first, subview != viewController.view {
            subview.removeFromSuperview()
        }

        // Ensure that the step view controller’s view is sized to the the contentView which is sized to the cell.
        viewController.view.frame = contentView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        contentView.addSubview(viewController.view)
        
        stepViewController = viewController
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        guard let attributes = layoutAttributes as? CollectionViewStepLayoutAttributes, let stepViewController = stepViewController else {
            return
        }
        
        stepViewController.headerView.transform = attributes.headerTransform
        stepViewController.headerTitle.transform = attributes.headerContentTransform
        
        stepViewController.headerView.alpha = attributes.headerAlpha
        stepViewController.headerTitle.alpha = attributes.headerTitleAlpha
        stepViewController.contentView.alpha = attributes.contentAlpha        
    }
}
