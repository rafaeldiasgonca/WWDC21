//
//  StarShape.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import SPCCore

/// StarShape encapsulates the concept of a star.
///
/// - localizationKey: StarShape

public class StarShape: BaseShape {

    /// Defines the width and height of the star.
    public var radius: Int {
        didSet {
            updatePath()
            shapeChanged()
        }
    }

    /// The number of points the star has.
    public var points: Int {
        didSet {
            updatePath()
            shapeChanged()
        }
    }

    /// Defines how long and skinny the points are on the star.
    public var sharpness: Double {
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

    /// Create a star with specified dimensions.
    ///
    /// - parameter radius: Defines the width and height of the star.
    /// - parameter points: The number of points the star will have.
    /// - parameter sharpness: Defines how long and skinny the points are on the star.

    public init(radius: Int, points: Int, sharpness: Double = 1.4) {
        self.radius = radius
        self.points = points
        self.sharpness = sharpness
        super.init(path: StarShape.path(radius: radius, points: points, sharpness: sharpness))
    }
    
    public convenience init(points: Int) {
        self.init(radius: 50, points: points)
    }

    // MARK:-

    private static func path(radius: Int, points: Int, sharpness: Double) -> CGPath {
        let midpoint = CGPoint(x: radius, y: radius)
        let innerRadius = CGFloat(Double(radius) / sharpness)
        let path = CGPath.starPath(center: midpoint, radius: innerRadius, numberOfPoints: points, sharpness: CGFloat(sharpness))
        return path
    }

    private func updatePath() {
        _path = StarShape.path(radius: radius, points: points, sharpness: sharpness)
    }
}
