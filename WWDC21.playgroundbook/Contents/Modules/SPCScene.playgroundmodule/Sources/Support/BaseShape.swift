//
//  BaseShape.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import SPCCore

/// Shape encapsulates the concept of a shape, like a circle or a rectangle,
/// and provides a CGPath in this shape, used by other types, to render objects on screen.
///
/// - localizationKey: BaseShape

open class BaseShape {

    /// The size of the bounding rect for this shape.
    public var size: CGSize {
        return _path.boundingBoxOfPath.size
    }

    /// The path which defines the outline of this shape.
    public var path: CGPath { return _path }

    /// The color to be used when rendering this shape to an image.
    public var backgroundColor: Color

    /// The colors used in a linear gradient when rendering this shape to an image.
    public var backgroundColors: [Color]
    
    private var backgroundCGColors: [CGColor] {
        get {
            return backgroundColors.map { $0.cgColor }
        }
    }
    
    public var strokeColor: Color
    
    public var strokeColors: [Color]
    
    public var strokeWidth: CGFloat = 5.0
    
    private var strokeCGColors: [CGColor] {
        get {
            return strokeColors.map { $0.cgColor }
        }
    }

    /// An image rendered from the current path and filled with the current color.
    public var image: UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()

        // Creates the layer represented by "backgroundColor"
        ctx.beginPath()
        ctx.addPath(path)
        
        ctx.setFillColor(backgroundColor.cgColor)
        ctx.fillPath()
        
        // Creates the layer represented by "backgroundColors"
        ctx.beginPath()
        ctx.addPath(path)
        ctx.clip()
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = backgroundCGColors as CFArray
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
        
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
        
        // Creates the strokeColor layer
        if strokeColor != .clear {
            ctx.setLineWidth(strokeWidth)
        }
        ctx.setStrokeColor(strokeColor.cgColor)
        ctx.beginPath()
        ctx.addPath(path)
        
        ctx.strokePath()
        
        
        for color in strokeColors {
            if color != .clear {
                ctx.setLineWidth(strokeWidth)
            }
        }
        
        ctx.beginPath()
        ctx.addPath(path)
        ctx.replacePathWithStrokedPath()
        ctx.clip()
        
        let strokeGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: strokeCGColors as CFArray, locations: nil)!
        ctx.drawLinearGradient(strokeGradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])

        ctx.restoreGState()
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return img ?? UIImage()
    }

    // MARK:-

    /// Create a any shape using the provided path.
    ///
    /// - parameter path: The path to be used when drawing this shape.
    /// - parameter color: The color to be used when rendering this shape to an image.
    /// - parameter gradientColor: The second color used in a linear gradient when rendering this shape to an image.

    public init(path: CGPath, color: Color = .black, backgroundColors: [Color] = [.clear, .clear]) {
        self.backgroundColor = color
        self.backgroundColors = backgroundColors
        self._path = path
        self.strokeColor = .clear
        self.strokeColors = [.clear, .clear]
        self.shapeID = UUID().uuidString
    }

    // MARK:- Internal

    // We need the _path to be accessible to subclasses.
    internal var _path: CGPath
    
    internal func shapeChanged() {
        NotificationCenter.default.post(name: Notification.shapeChanged, object: self.shapeID)
    }
    
    internal var shapeID: String
}


extension Notification {
    static let shapeChanged = Notification.Name(rawValue: "shapeChanged")
}
