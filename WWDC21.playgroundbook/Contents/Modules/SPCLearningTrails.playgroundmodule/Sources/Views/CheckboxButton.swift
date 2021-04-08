//
//  CheckboxButton.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

class CheckboxButton: UIButton {
    
    enum CheckedState {
        case unchecked
        case chosen
        case correct
        case wrong
        
        var image: UIImage? {
            switch self {
            case .unchecked:
                return UIImage(named: "checkbox-unchecked")
            case .chosen:
                return UIImage(named: "checkbox-circle")
            case .correct:
                return UIImage(named: "checkbox-tick")
            case .wrong:
                return UIImage(named: "checkbox-cross")
            }
        }
        
        var accessibilityDescription: String {
            var state = ""
            switch self {
            case .unchecked:
                state = NSLocalizedString("unchecked", tableName: "SPCLearningTrails", comment: "AX description of an unchecked option in a response block")
            case .chosen:
                state = NSLocalizedString("chosen", tableName: "SPCLearningTrails", comment: "AX description of a chosen option in a response block")
            case .correct:
                state = NSLocalizedString("correct", tableName: "SPCLearningTrails", comment: "AX description of a correct ticked option in a response block")
            case .wrong:
                state = NSLocalizedString("wrong", tableName: "SPCLearningTrails", comment: "AX description of a wrong ticked option in a response block")
            }
            let option = NSLocalizedString("option", tableName: "SPCLearningTrails", comment: "AX prefix of an option in a response block")
            return "\(option): \(state)"
        }
    }
    
    // The current state of the checkbox.
    var checkedState = CheckedState.unchecked
    
    // The state of the checkbox when it’s selected.
    var checkedStateForSelected = CheckedState.chosen {
        didSet {
            setImage(checkedStateForSelected.image, for: .selected)
            setImage(checkedStateForSelected.image, for: [.selected, .disabled]) // After confirmed.
        }
    }
    
    override var accessibilityTraits: UIAccessibilityTraits {
        get {
            return super.accessibilityTraits.remove(.selected) ?? super.accessibilityTraits
        }
        set {
            super.accessibilityTraits = newValue
        }
    }
    
    override var accessibilityLabel: String? {
        get {
            if let label = super.accessibilityLabel {
                return "\(checkedState.accessibilityDescription). \(label)"
            }
            return nil
        }
        set {
            super.accessibilityLabel = newValue
        }
    }
    
    private let minimumHeight: CGFloat = 30.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0)
        titleLabel?.numberOfLines = 0
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel?.adjustsFontForContentSizeCategory = true
        setImage(CheckedState.unchecked.image, for: .normal)
        setImage(CheckedState.chosen.image, for: .selected)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 20)
        addTarget(self, action: #selector(didPressButton), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let targetSize = CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude)
        var titleSize = titleSizeThatFits(within: targetSize)
        titleSize.height += directionalLayoutMargins.bottom
        return CGSize(width: size.width, height: max(titleSize.height, minimumHeight))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let imageView = imageView, let titleLabel = titleLabel else { return }
        imageView.frame = CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height)
        let titleSize = titleSizeThatFits(within: bounds.size)
        titleLabel.frame = CGRect(x: imageView.frame.maxX + titleEdgeInsets.left, y: 0, width: titleSize.width, height: titleSize.height)
    }
    
    private func titleSizeThatFits(within size: CGSize) -> CGSize {
        guard let imageView = imageView, let titleLabel = titleLabel else { return size }
        imageView.sizeToFit()
        let availableSize = CGSize(width: size.width - titleEdgeInsets.left - titleEdgeInsets.right - imageEdgeInsets.left - imageView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)
        return titleLabel.systemLayoutSizeFitting(availableSize, withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .defaultHigh)
    }
    
    @objc
    func didPressButton(_ sender: UIButton) {
        isSelected = !isSelected
        checkedState = isSelected ? checkedStateForSelected : CheckedState.unchecked
        sendActions(for: .valueChanged)
    }
}
