//
//  Line.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import SPCCore
import UIKit

public class Line: BaseShape {
    /// The length of the line, in points.
    ///
    /// - localizationKey: Line.length
    public var length: Double {
        didSet {
            let x = start.x + cos(rotation) * length
            let y = start.y + sin(rotation) * length
            self.end = Point(x: x, y: y)
            updateShape()
            shapeChanged()
        }
    }
    
    /// The thickness of the line, in points.
    ///
    /// - localizationKey: Line.thickness
    public var thickness: Int {
        didSet {
            updateShape()
            shapeChanged()
        }
    }
    
    /// The point where the line starts.
    ///
    /// - localizationKey: Line.start
    public var start: Point {
        didSet {
            updateShape()
            shapeChanged()
        }
    }
    
    /// The point where the line ends.
    ///
    /// - localizationKey: Line.end
    public var end: Point {
        didSet {
            updateShape()
            shapeChanged()
        }
    }
    
    /// The rotation of the line in radians
    ///
    /// - localizationKey: Line.rotation
    public var rotation: Double {
        didSet {
            if let graphic = baseGraphic {
                graphic._runAction(action: .rotate(toAngle: CGFloat(rotation), duration: 0.5), name: "rotate")

                self.start = Line.rotationPoint(point: self.start, rotation: rotation)
                self.end = Line.rotationPoint(point: self.end, rotation: rotation)
                shapeChanged()
            }
        }
    }

    var centerPoint: Point {
        didSet {
            updateShape()
            shapeChanged()
        }
    }
    
    weak var baseGraphic: BaseGraphic? = nil
    
    public init(start: Point, end: Point, thickness: Int) {
        self.start = start
        self.end = end
        self.thickness = thickness
        
        //Can't use func because it's before super.init
        self.length = Line.calculateDistance(from: start, to: end)
        let rotation = Line.calculateRotation(pointA: start, pointB: end)
        self.rotation = rotation
        
        centerPoint = Line.midPoint(of: start, and: end)
        
        
        super.init(path: Line.path(start: start, end: end, height: Double(thickness), rotation: rotation))
    }
    
    public init(length: Double, thickness: Int) {
        self.rotation = 0
        self.start = Point.zero
        self.end = Point(x: length, y: 0.0)
        self.thickness = thickness
        self.length = length
        self.centerPoint = Line.midPoint(of: self.start, and: self.end)
        super.init(path: Line.path(start: self.start, end: self.end, height: Double(self.thickness), rotation: self.rotation))
    }
    
    public convenience init(start: Point, end: Point) {
        self.init(start: start, end: end, thickness: 10)
    }
    
    public convenience init(startX: Float, startY: Float, endX: Float, endY: Float) {
        self.init(start: Point(x: startX, y: startY), end: Point(x: endX, y: endY))
    }
    
    private static func calculateDistance(from: Point, to: Point) -> Double {
        return sqrt(pow((from.x - to.x), 2.0) + pow((from.y - to.y), 2.0))
    }
    
    private static func calculateRotation(pointA: Point, pointB: Point) -> Double {
        let rise = pointA.y - pointB.y
        let run = pointA.x - pointB.x
        
        //Rotations appear to need to be the opposite.
        //For some reason a 45 degree angle was appearing on
        //screen as a -45 degree angle
        if run == 0 {
            return -Double.pi / 2
        } else {
            return -atan(rise/run)
        }
    }
    
    private static func midPoint(of pointA: Point, and pointB: Point) -> Point {
        return Point(x: (pointA.x + pointB.x) / 2, y: (pointA.y + pointB.y) / 2)
    }
    
    private static func rotationPoint(point: Point, rotation: Double) -> Point {
        // rotating a point is expressed as
        // | cos(t) -sin(t) | | x |
        // | sin(t)  cos(t) | | y |
        // where t is the angle of rotation
        // and x and y are the points being rotated
        
        let x = (cos(rotation) * point.x) - (sin(rotation) * point.y)
        let y = (sin(rotation) * point.x) + (cos(rotation) * point.y)
        
        return Point(x: x, y: y)
    }
    
    private static func path(start: Point, end: Point, height: Double, rotation: Double) -> CGPath {
        let width: Double = Line.calculateDistance(from: start, to: end)
        let lineRect = CGRect(origin: .zero, size: CGSize(width: width, height: height))
        let bezierPath = UIBezierPath(rect: lineRect)

        // Translate the points so that the origin is in the center.
        let originalCenter = CGPoint(x: lineRect.midX, y: lineRect.midY)
        bezierPath.apply(CGAffineTransform(translationX: -originalCenter.x, y: -originalCenter.y))

        // Rotate the points.
        bezierPath.apply(CGAffineTransform(rotationAngle: CGFloat(rotation)))

        // Translate the points back into positive space.
        let modifiedRect = bezierPath.bounds
        bezierPath.apply(CGAffineTransform(translationX: modifiedRect.width/2.0, y: modifiedRect.height/2.0))

        return bezierPath.cgPath
    }
    
    private func updateShape() {
        _path = Line.path(start: self.start, end: self.end,
                          height: Double(self.thickness),
                          rotation: Line.calculateRotation(pointA: self.start, pointB: self.end))
    }
}
