//
//  CircleShape.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import SPCCore

/// CircleShape encapsulates the concept of a circle.
///
/// - localizationKey: CircleShape

public class CircleShape: BaseShape {

    /// Defines the size of the circle.
    public var radius: Int {
        didSet {
            _path = CircleShape.path(radius: radius)
            shapeChanged()
        }
    }

    // MARK:-

    /// Create a circle with specified radius.
    ///
    /// - parameter radius: Defines the size of the circle.

    public init(radius: Int) {
        self.radius = radius
        super.init(path: CircleShape.path(radius: radius))
    }

    // MARK:- Private

    private static func path(radius: Int) -> CGPath {
        let boundingRect = CGRect(origin: .zero, size: CGSize(width: radius * 2, height: radius * 2))
        let path = CGPath.init(ellipseIn: boundingRect,transform: nil)
        return path
    }
}
