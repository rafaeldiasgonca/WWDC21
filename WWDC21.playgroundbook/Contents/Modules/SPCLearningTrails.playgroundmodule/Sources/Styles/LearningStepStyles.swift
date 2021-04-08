//
//  LearningStepStyles.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import UIKit

public protocol LearningStepStyle {
    /// Step header text  style.
    var textStyle: AttributedStringStyle { get }
}

public struct LearningStepTypeAttributedStringStyle: AttributedStringStyle {
    
    // Style attributes for step type.
    private var typeAttributes: [NSAttributedString.Key: Any] {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title3)
        let boldDescriptor = descriptor.withSymbolicTraits(.traitBold)!
        let sizeDescriptor = boldDescriptor.withSize(20)
        let font = UIFont(descriptor: sizeDescriptor, size: 0.0)
        return [
            .font : UIFontMetrics.default.scaledFont(for: font),
            .foregroundColor : UIColor.mainTextColorLT
        ]
    }

    // Style attributes for step title.
    private var titleAttributes: [NSAttributedString.Key: Any] {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
        let boldDescriptor = descriptor.withSymbolicTraits(.traitBold)!
        let sizeDescriptor = boldDescriptor.withSize(18)
        let font = UIFont(descriptor: sizeDescriptor, size: 0.0)
        return [
            .font : UIFontMetrics.default.scaledFont(for: font),
            .foregroundColor : UIColor.mainTextColorLT
        ]
    }
    
    // MARK: Public
    
    public static var shared: AttributedStringStyle = LearningStepTypeAttributedStringStyle()
    
    public var fontSize: CGFloat = TextAttributedStringStyle.defaultSize
    
    public var tintColor: UIColor = UIColor.red

    public var attributes: [String : [NSAttributedString.Key: Any]] {
        return [
            "type" : typeAttributes,
            "title" : titleAttributes
        ]
    }
}

// Default implmementation.

extension LearningStepStyle {
    public var textStyle: AttributedStringStyle {
        return LearningStepTypeAttributedStringStyle.shared
    }
}

// Default step style.
public struct DefaultLearningStepStyle: LearningStepStyle {
    public static let headerHeight: CGFloat = 50
    public static let headerButtonSize = CGSize(width: 35, height: 35)
}

// Style for check step.
public struct CheckLearningStepStyle: LearningStepStyle {
}

// Style for code step.
public struct CodeLearningStepStyle: LearningStepStyle {
}

// Style for context step.
public struct ContextLearningStepStyle: LearningStepStyle {
}

// Style for experiment step.
public struct ExperimentLearningStepStyle: LearningStepStyle {
}

// Style for find step.
public struct FindLearningStepStyle: LearningStepStyle {
}
