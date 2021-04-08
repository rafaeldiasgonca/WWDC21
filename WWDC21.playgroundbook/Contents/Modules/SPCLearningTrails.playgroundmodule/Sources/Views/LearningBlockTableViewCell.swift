//
//  LearningBlockTableViewCell.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

public class LearningBlockTableViewCell: UITableViewCell {
    private var topSeparatorView = UIView()
    private var bottomSeparatorView = UIView()
    
    private let separatorHeight: CGFloat = GroupLearningBlockStyle.separatorHeight
    private lazy var separatorTopMargin: CGFloat = separatorHeight
    private let separatorBottomMargin: CGFloat = GroupLearningBlockStyle.separatorBottomMargin
    
    private let topSeparatorColor = GroupLearningBlockStyle.separatorColor
    private let bottomSeparatorColor = GroupLearningBlockStyle.separatorColor
        
    static let contentWidthMultiplier: CGFloat = 0.85
    
    var isTopSeparatorVisible = false {
        didSet {
            topSeparatorView.isHidden = !isTopSeparatorVisible
        }
    }
    var isBottomSeparatorVisible = false {
        didSet {
            bottomSeparatorView.isHidden = !isBottomSeparatorVisible
        }
    }
    
    // Sets the bottom separator to clear.
    // Allows the separator to be hidden during animations without interfering
    // with its hidden or alpha properties which are being animated.
    func setBottomSeparatorTransparent(_ transparent: Bool) {
        bottomSeparatorView.backgroundColor = transparent ? .clear : bottomSeparatorColor
    }
    
    public var learningBlockCell: LearningBlockCell? {
        didSet {
            guard let blockCell = learningBlockCell else { return }
            contentView.subviews.filter( { $0 is LearningBlockCell } ).forEach({ $0.removeFromSuperview() })
            contentView.insertSubview(blockCell, at: 0)
            
            blockCell.translatesAutoresizingMaskIntoConstraints = false
            
            let heightConstraint = contentView.heightAnchor.constraint(equalTo: blockCell.heightAnchor, constant: 0)
            heightConstraint.priority = .defaultHigh
                        
            NSLayoutConstraint.activate([
                blockCell.topAnchor.constraint(equalTo: contentView.topAnchor),
                blockCell.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: LearningBlockTableViewCell.contentWidthMultiplier),
                blockCell.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                heightConstraint
            ])
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func initialize() {
        backgroundColor = UIColor.systemBackgroundLT
        topSeparatorView.backgroundColor = topSeparatorColor
        bottomSeparatorView.backgroundColor = bottomSeparatorColor
        topSeparatorView.isHidden = true
        bottomSeparatorView.isHidden = true
        topSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        bottomSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(topSeparatorView)
        contentView.addSubview(bottomSeparatorView)
        
        isAccessibilityElement = false
        
        NSLayoutConstraint.activate([
            topSeparatorView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: separatorTopMargin),
            topSeparatorView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: LearningBlockTableViewCell.contentWidthMultiplier),
            topSeparatorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            topSeparatorView.heightAnchor.constraint(equalToConstant: separatorHeight),
            
            bottomSeparatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -separatorBottomMargin),
            bottomSeparatorView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: LearningBlockTableViewCell.contentWidthMultiplier),
            bottomSeparatorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            bottomSeparatorView.heightAnchor.constraint(equalToConstant: separatorHeight)
            ])
    }

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let learningBlockCell = learningBlockCell else { return CGSize.zero }
        
        let availableWidth = size.width * LearningBlockTableViewCell.contentWidthMultiplier
        
        // Match to autolayout computed size: rounded up/down unless exactly on a half-pixel boundary.
        var autolayoutWidth = availableWidth
        let fractionalPart = availableWidth.truncatingRemainder(dividingBy: 1.0)
        if fractionalPart == 0.5 {
            autolayoutWidth = availableWidth
        } else {
            autolayoutWidth = round(availableWidth)
        }
        let availableSize = CGSize(width: autolayoutWidth, height: size.height)
        
        let blockCellSize = learningBlockCell.sizeThatFits(availableSize) // Height is determined by block cell.
        var fitsSize = CGSize(width: size.width, height: blockCellSize.height)

        if !bottomSeparatorView.isHidden {
            fitsSize.height += separatorBottomMargin
        }
        return fitsSize
    }
}
