//
//  RectangleShape.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import SPCCore

/// RectangleShape encapsulates the concept of a rectangle.
///
/// - localizationKey: RectangleShape

public class RectangleShape: BaseShape {

    /// Defines the width of the rectangle.
    public var width: Int {
        didSet {
            updatePath()
            shapeChanged()
        }
    }

    /// Defines the height of the rectangle.
    public var height: Int {
        didSet {
            updatePath()
            shapeChanged()
        }
    }

    /// Causes the corners of the rectangle to be rounded.
    public var cornerRadius: Double {
        didSet {
            updatePath()
            shapeChanged()
        }
    }

    // MARK:-

    /// Create a rectangle with specified dimensions.
    ///
    /// - parameter width: Defines the width of the rectangle.
    /// - parameter height: Defines the height of the rectangle.
    /// - parameter cornerRadius: Rounds the corners of the rectangle.

    public init(width: Int, height: Int, cornerRadius: Double = 0.0) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        super.init(path: RectangleShape.path(width: width, height: height, cornerRadius: cornerRadius))
    }

    // MARK:- Private

    private static func path(width: Int, height: Int, cornerRadius: Double) -> CGPath {
        let boundingRect = CGRect(origin: .zero, size: CGSize(width: width, height: height))
        let path = CGPath.init(roundedRect: boundingRect,
                               cornerWidth: CGFloat(cornerRadius),
                               cornerHeight: CGFloat(cornerRadius),
                               transform: nil)
        return path
    }

    private func updatePath() {
        _path = RectangleShape.path(width: width, height: height, cornerRadius: cornerRadius)
    }
}
