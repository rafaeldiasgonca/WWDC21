//
//  Graphic.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import CoreGraphics
import SPCCore

/// A Graphic object, made from an image or with a shape, that can placed on the scene.
/// - localizationKey: Graphic
open class Graphic: BaseGraphic, AudioPlaying, ImageProtocol, TextProtocol, ShapeProtocol, Scaleable, Actionable, Emittable, TouchInteractable {
    
    fileprivate static var defaultNameCount = 1
    
    public init(graphicType: GraphicType = .graphic, name: String = "") {
        super.init()
        self.graphicType = graphicType
        self.name = name
        //SceneProxy().createNode(id: id, graphicName: name, graphicType: graphicType)
    }
    
    /// Creates a Graphic with the given identifier; for example, reconstructing a graphic.
    ///
    /// - Parameter id: The identifier associated with the Graphic.
    /// - Parameter graphicType: The graphic type associated with the Graphic.
    /// - Parameter name: The name associated with the Graphic.
    ///
    /// - localizationKey: Graphic(id:name:graphicType:)
    public init(id: String, graphicType: GraphicType = .graphic, name: String = "") {
        super.init()
        self.name = name
        self.graphicType = graphicType
    }
    
        
    /// Creates a Graphic from a given image and name.
    ///
    /// - Parameter image: The image you choose to create the Graphic.
    /// - Parameter name: The name you give to the Graphic.
    ///
    /// - localizationKey: Graphic(image:name:)
    public init(image: Image, name: String = "") {
        super.init()
        self.graphicType = graphicType
        if name == "" {
            self.name = "graphic" + String(Graphic.defaultNameCount)
            Graphic.defaultNameCount += 1
        } else {
            self.name = name
        }
        
        self.image = image
        
        updateSize()
    }
    
    public class func circle(radius: Int, color: Color, colors: [Color]? = nil) -> Graphic {
        return Graphic(shape: CircleShape(radius: radius), color: color, colors: colors)
    }
    
    public class func rectangle(width: Int, height: Int, cornerRadius: Double, color: Color, colors: [Color]? = nil) -> Graphic {
        return Graphic(shape: RectangleShape(width: width, height: height, cornerRadius: cornerRadius), color: color, colors: colors)
    }
    
    public class func polygon(radius: Int, sides: Int, color: Color, colors: [Color]? = nil) -> Graphic {
        return Graphic(shape: PolygonShape(radius: radius, sides: sides), color: color, colors: colors)
    }
    
    public class func star(radius: Int, points: Int, sharpness: Double, color: Color, colors: [Color]? = nil) -> Graphic {
        return Graphic(shape: StarShape(radius: radius, points: points, sharpness: sharpness), color: color, colors: colors)
    }
    
    public class func line(start: Point, end: Point, thickness: Int, color: Color, colors: [Color]? = nil) -> Graphic {
        let line = Line(start: start, end: end, thickness: thickness)
        let pos = line.centerPoint
        
        let graphic = Graphic(shape: line, color: color, colors: colors)
        graphic.location = pos
        line.baseGraphic = graphic
        
        return graphic
    }
    
    public class func line(length: Double, thickness: Int, color: Color, colors: [Color]? = nil) -> Graphic {
        let line = Line(length: length, thickness: thickness)
        let graphic = Graphic(shape: line, color: color, colors: colors)
        line.baseGraphic = graphic
        return graphic
    }
    
    public class func customShape(path: CGPath, color: Color, colors: [Color]? = nil) -> Graphic {
        return Graphic(shape: BaseShape(path: path), color: color, colors: colors)
    }
    
    /// Creates a Graphic with a specified shape, color, gradient, and name.
    /// Example usage:
    /// ````
    /// let pentagon = Graphic(shape: .polygon(radius: 50, sides: 5), color: .red, gradientColor: .yellow, name: \"pentagon\")
    /// ````
    /// - Parameter shape: One of the Graphic shapes.
    /// - Parameter color: A fill color for the Graphic.
    /// - Parameter gradientColor: A secondary color for the gradient.
    /// - Parameter name: An optional name you can give to the shape. You can choose to leave the name blank.
    ///
    /// - localizationKey: Graphic(shape:color:gradientColor:name:)
    public convenience init(shape: BaseShape, color: Color, colors: [Color]? = nil, name: String = "") {

        if name == "" {
            self.init(graphicType: .graphic, name: "graphic" + String(Graphic.defaultNameCount))
            Graphic.defaultNameCount += 1
        } else {
            self.init(graphicType: .graphic, name: name)
        }

        updateShape(shape: shape, color: color, colors: colors)

        updateSize()
    }
    
    public func setOnTouchHandler(_ handler: @escaping (Touch)->Void) {
        allowsTouchInteraction = true
        setHandler(for: .touch, handler: handler)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
