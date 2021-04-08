//
//  CGPoint+extensions.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import CoreGraphics

extension CGPoint {

    static func midpoint(between point1: CGPoint, and point2: CGPoint) -> CGPoint {
        var midPoint = CGPoint.zero
        midPoint.x = (point1.x + point2.x) / 2.0
        midPoint.y = (point1.y + point2.y) / 2.0
        return midPoint
    }
    
    static func intersectionBetweenSegments(p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGPoint? {
        var denominator = (p3.y - p2.y) * (p1.x - p0.x) - (p3.x - p2.x) * (p1.y - p0.y)
        var ua = (p3.x - p2.x) * (p0.y - p2.y) - (p3.y - p2.y) * (p0.x - p2.x)
        var ub = (p1.x - p0.x) * (p0.y - p2.y) - (p1.y - p0.y) * (p0.x - p2.x)
        if (denominator < 0) {
            ua = -ua; ub = -ub; denominator = -denominator
        }
        
        if ua >= 0.0 && ua <= denominator && ub >= 0.0 && ub <= denominator && denominator != 0 {
            return CGPoint(x: p0.x + ua / denominator * (p1.x - p0.x), y: p0.y + ua / denominator * (p1.y - p0.y))
        }
        
        return nil
    }
}
