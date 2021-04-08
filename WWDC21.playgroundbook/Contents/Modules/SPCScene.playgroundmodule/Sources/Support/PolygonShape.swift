//
//  PolygonShape.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import SPCCore

/// PolygonShape encapsulates the concept of a rectangle.
///
/// - localizationKey: PolygonShape

public class PolygonShape: BaseShape {

    /// Defines the width and height of the polygon.
    public var radius: Int {
        didSet {
            updatePath()
            shapeChanged()
        }
    }

    /// The number of sides the polygon has.
    public var sides: Int {
        didSet {
            updatePath()
            shapeChanged()
        }
    }

    // We can't rely on the size of the bounding box for this shape.
    public override var size: CGSize {
        return CGSize(width: radius * 2, height: radius * 2)
    }

    // MARK:-

    /// Create a polygon with specified dimensions.
    ///
    /// - parameter radius: Defines the width and height of the polygon.
    /// - parameter sides: The number of sides the polygon will have.

    public init(radius: Int, sides: Int) {
        self.radius = radius
        self.sides = sides
        super.init(path: PolygonShape.path(radius: radius, sides: sides))
    }

    // MARK:- Private

    private static func path(radius: Int, sides: Int) -> CGPath {
        let rect = CGRect(origin: .zero, size: CGSize(width: radius * 2, height: radius * 2))
        let midpoint = CGPoint(x: rect.midX, y: rect.midY)
        let path = CGPath.polygonPath(center: midpoint, radius: CGFloat(radius), sides: sides)
        return path
    }

    private func updatePath() {
        _path = PolygonShape.path(radius: radius, sides: sides)
    }
}
