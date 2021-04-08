//
//  Shape.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import SPCCore

import UIKit


public enum Shape {
    case circle(radius: Int)
    case rectangle(width: Int, height: Int, cornerRadius: Double)
    case polygon(radius: Int, sides: Int)
    case star(radius: Int, points: Int, sharpness: Double)
    case custom(path: CGPath)
}

/// An enumeration of the types of basic shapes, including: circle, rectangle, polygon, and star.
///
/// - localizationKey: BasicShape
public enum BasicShape {
    case circle(radius: Int, color: Color, gradientColor: Color)
    case rectangle(width: Int, height: Int, cornerRadius: Double, color: Color, gradientColor: Color)
    case polygon(radius: Int, sides: Int, color: Color, gradientColor: Color)
    case star(radius: Int, points: Int, sharpness: Double, color: Color, gradientColor: Color)
    case custom(path: CGPath, color: Color, gradientColor: Color)
    
    public var size: CGSize {
        switch self {
        case .circle(let radius, _ , _):
            return CGSize(width: radius * 2, height: radius * 2)
        case .rectangle(let width, let height, _, _ , _):
            return CGSize(width: width, height: height)
        case .polygon(let radius, _, _ , _):
            return CGSize(width: radius * 2, height: radius * 2)
        case .star(let radius, _, _, _, _):
            return CGSize(width: radius * 2, height: radius * 2)
        case.custom(let path, _, _):
            return CGSize(width: path.boundingBoxOfPath.width, height: path.boundingBoxOfPath.height)
        }
    }
    
    var color: Color {
        switch self {
        case .circle(_, let color, _):
            return color
        case .rectangle(_, _, _, let color , _):
            return color
        case .polygon(_, _, let color, _):
            return color
        case .star(_, _, _, let color, _):
            return color
        case .custom(_, let color, _):
            return color
        }
    }
    
    var gradientColor: Color {
        switch self {
        case .circle(_, _, let gradientColor):
            return gradientColor
        case .rectangle(_, _, _, _, let gradientColor):
            return gradientColor
        case .polygon(_, _, _, let gradientColor):
            return gradientColor
        case .star(_, _, _, _, let gradientColor):
            return gradientColor
        case .custom(_, _, let gradientColor):
            return gradientColor
        }
    }
    
    private var path: CGPath {
        let origin = CGPoint(x: 0, y: 0)
        switch self {
        case .circle:
            return UIBezierPath(ovalIn: CGRect(origin: origin, size: size)).cgPath
        case .rectangle(_, _, let cornerRadius, _, _):
            return UIBezierPath(roundedRect: CGRect(origin: origin, size: size), cornerRadius: CGFloat(cornerRadius)).cgPath
        case .polygon(_, let sides, _, _):
            return UIBezierPath(polygonIn: CGRect(origin: origin, size: size), sides: sides).cgPath
        case .star(_, let points, let sharpness, _, _):
            return UIBezierPath(starIn: CGRect(origin: origin, size: size), points: points, sharpness: CGFloat(sharpness)).cgPath
        case .custom(let path, _, _):
            return path
        }
    }
    
    var image: UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        
        ctx.beginPath()
        ctx.addPath(path)
        ctx.clip()
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [color.cgColor, gradientColor.cgColor] as CFArray
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
        
        ctx.restoreGState()
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return img ?? UIImage()
    }
    
    enum ShapeType: String, RawRepresentable {
        case circle
        case rectangle
        case polygon
        case star
        case custom
    }
    
    var type: ShapeType {
        switch self {
        case .circle:
            return .circle
        case .polygon:
            return .polygon
        case .rectangle:
            return .rectangle
        case .star:
            return .star
        case .custom:
            return .custom
        }
    }
}

/// An enumeration of the types of basic shapes, including: circle, rectangle, polygon and star.
///
/// - localizationKey: Shape
public enum ShapeType {
    case circle(radius: Int)
    case rectangle(width: Int, height: Int, cornerRadius: Double)
    case polygon(radius: Int, sides: Int)
    case star(radius: Int, points: Int, sharpness: Double)
    case custom(path: CGPath)
}

extension UIBezierPath
{
    public convenience init(starIn rect: CGRect, points: Int, sharpness: CGFloat = 1.4) {
        let midpoint = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 / sharpness
        let path = CGPath.starPath(center: midpoint, radius: radius, numberOfPoints: points, sharpness: sharpness)
        self.init(cgPath: path)
    }
    
    public convenience init(polygonIn rect: CGRect, sides: Int) {
        let midpoint = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let path = CGPath.polygonPath(center: midpoint, radius: radius, sides: sides)
        self.init(cgPath: path)
    }
}
