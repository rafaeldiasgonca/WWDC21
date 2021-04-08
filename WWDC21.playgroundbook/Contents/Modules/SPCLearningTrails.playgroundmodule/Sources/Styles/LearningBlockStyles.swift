//
//  LearningBlockStyles.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import UIKit

public protocol LearningBlockStyle {
    var margins: NSDirectionalEdgeInsets { get set }
    var backgroundAlpha: CGFloat { get }
    var backgroundColor: UIColor { get }
    var cornerBadge: UIImage? { get }
}

// Default implmementation.
extension LearningBlockStyle {
    public var backgroundAlpha: CGFloat { return 1.0 }
    public var backgroundColor: UIColor { return UIColor.systemBackgroundLT }
    public var cornerBadge: UIImage? { return nil }
}

// Default block style.
public struct DefaultLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0)
}

// Style for code block.
public struct CodeLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 18, trailing: 0)
    public var backgroundColor = UIColor.codeBackgroundLT
}

// Style for text block.
public struct TextLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 18, trailing: 0)
}

// Style for group block.
public struct GroupLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 22, leading: 0, bottom: 22, trailing: 5)
}

extension GroupLearningBlockStyle {
    static var groupLevelIndent: CGFloat = 12
    static var separatorColor = UIColor.mainSeparatorColorLT.withAlphaComponent(0.5)
    static var separatorHeight: CGFloat = 0.5
    static var separatorBottomMargin: CGFloat = 18
}

// Style for response block.
public struct ResponseLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 18, trailing: 0)
    static var confirmButtonBackgroundColor = UIColor.systemBlueLT
    static var confirmButtonDisabledBackgroundColor = UIColor.systemBlueLT.withAlphaComponent(0.5)
    static var confirmButtonTitleColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    static var confirmButtonTitleColorCorrect = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).withAlphaComponent(0.5)
    static var confirmButtonTitleColorWrong = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
}

// Style for image block.
public struct ImageLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 18, trailing: 0)
}

// Style for buttons block.
public struct ButtonsLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 18, trailing: 10)
    static var buttonBackgroundColor = UIColor.systemBlueLT
    static var buttonCornerRadius: CGFloat = 10.0
    static var buttonPadding: CGFloat = 20.0
}

// Style for video block.
public struct VideoLearningBlockStyle: LearningBlockStyle {
    public var margins = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 18, trailing: 10)
}
