//
//  LearningBlockView.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit


/// An object that displays a learning block should conform to this protocol.
public protocol LearningBlockViewable {
    var learningBlock: LearningBlock? { get set }
    var style: LearningBlockStyle?  { get set }
    var textStyle: AttributedStringStyle?  { get set }

    /// Returns true if the learning block view should be visible as an accessibility element.
    var isVisibleToAccessibility: Bool { get }
    
    /// Loads the learning block view with a learning block, style, and (optional) text style.
    ///
    /// - Parameters:
    ///   - learningBlock: The learning block to be loaded.
    ///   - style: The learning block style to be applied.
    ///   - textStyle: The attributed string style to be used for styling text (optional).
    func load(learningBlock: LearningBlock, style: LearningBlockStyle, textStyle: AttributedStringStyle?)
}

// Default implementation.
extension LearningBlockViewable {
     public var isVisibleToAccessibility: Bool { return true }
}

public typealias LearningBlockView = (UIView & LearningBlockViewable)

public protocol LearningBlockViewDelegate {
    func didTapLink(blockView: LearningBlockView, url: URL, linkRect: CGRect)
}
