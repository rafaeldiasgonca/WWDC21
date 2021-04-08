//
//  LearningBlockCollectionViewCell.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

public class LearningBlockCollectionViewCell: UICollectionViewCell {
    
    public var learningBlockCell: LearningBlockCell? {
        didSet {
            guard let blockCell = learningBlockCell else { return }
            contentView.subviews.forEach({ $0.removeFromSuperview() })
            contentView.addSubview(blockCell)
            
            blockCell.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                blockCell.topAnchor.constraint(equalTo: topAnchor),
                blockCell.leadingAnchor.constraint(equalTo: leadingAnchor),
                blockCell.trailingAnchor.constraint(equalTo: trailingAnchor),
                heightAnchor.constraint(equalTo: blockCell.heightAnchor)
                ])
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        backgroundColor = .clear
    }

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        return learningBlockCell?.sizeThatFits(size) ?? CGSize.zero
    }
    
    override public func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let autoLayoutAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        
        let targetSize = CGSize(width: autoLayoutAttributes.frame.width,
                                height: sizeThatFits(CGSize(width: autoLayoutAttributes.frame.width, height: CGFloat.greatestFiniteMagnitude)).height)
        
        let autoLayoutFrame = CGRect(origin: autoLayoutAttributes.frame.origin, size: targetSize)
        
        // Assign the new size to the layout attributes
        autoLayoutAttributes.frame = autoLayoutFrame
        return autoLayoutAttributes
    }
}
