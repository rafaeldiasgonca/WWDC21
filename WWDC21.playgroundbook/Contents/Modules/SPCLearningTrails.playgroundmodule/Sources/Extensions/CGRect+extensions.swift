//
//  CGRect+extensions.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

extension CGRect {
    func scaled(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
    
    // Center-normalized conversions
    // Co-ordinate space is a 1 x 1 square where the centre is (0, 0)
    //
    //                                    +      (0.5, 0.5)
    //                                    |
    //                                    |
    //                                    |
    //                                    |
    //                        +---------(0,0)--------+
    //                                    |
    //                                    |
    //                                    |
    //                                    |
    //                   (-0.5, -0.5)     +
    //
    
    func normalizedPoint(for point: CGPoint) -> CGPoint {
        return CGPoint(x: (point.x - (width / 2)) / width, y: ((point.y - (height / 2)) / -height))
    }
    
    func point(forNormalizedPoint normalizedPoint: CGPoint) -> CGPoint {
        return CGPoint(x: (normalizedPoint.x * width) + (width / 2), y: -1 * ((normalizedPoint.y * height)  - (height / 2)))
    }
    
    func normalizedSize(for size: CGSize) -> CGSize {
        return CGSize(width: size.width / width, height: size.height / height)
    }
    
    func size(forNormalizedSize normalizedSize: CGSize) -> CGSize {
        return CGSize(width: normalizedSize.width * width, height: normalizedSize.height * height)
    }
    
    func normalizedRect(for rect: CGRect) -> CGRect {
        return CGRect(origin: normalizedPoint(for: rect.origin), size: normalizedSize(for: rect.size))
    }
    
    func rect(forNormalizedRect normalizedRect: CGRect) -> CGRect {
        return CGRect(origin: point(forNormalizedPoint: normalizedRect.origin), size: size(forNormalizedSize: normalizedRect.size))
    }
    
    static func boundingRect(for points: [CGPoint]) -> CGRect {
        var maxX = points[0].x
        var maxY = points[0].y
        var minX = points[0].x
        var minY = points[0].y
        for point in points {
            maxX = max(maxX, point.x);
            maxY = max(maxY, point.y);
            minX = min(minX, point.x);
            minY = min(minY, point.y);
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
