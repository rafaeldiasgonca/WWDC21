import UIKit
import SpriteKit

/// /*#-localizable-zone(colorPicker1)*/A custom color picker used to select the color of the brush in the drawing toolbar./*#-end-localizable-zone*/
public class ColorPicker: SideBarPlaceable {
    var width = 400
    var height = 200
    var elementSize: Int = 40
    
    /// /*#-localizable-zone(colorPicker2)*/An event handler called when selecting a color./*#-end-localizable-zone*/
    public var onSelectedColor: ((Color) -> Void) = { _ in }
    
    /// /*#-localizable-zone(colorPicker3)*/The toolbar icon for the color picker./*#-end-localizable-zone*/
    public var icon = Graphic.circle(radius: 25, color: UIColor(named: "drawing_default_color") ?? .black)
    
    public init() { }
    
    /// /*#-localizable-zone(colorPicker4)*/Removes all graphics associated with the color picker./*#-end-localizable-zone*/
    public func dismiss() {
        icon.strokeColor = .black
        icon.strokeWidth = 6
        scene.removeGraphics(named: "colorPicker")
    }
    
    /// /*#-localizable-zone(colorPicker6)*/Draws and sets up the color picker./*#-end-localizable-zone*/
    public func draw(at point: Point) {
        let rect = Graphic.rectangle(width: width + 20, height: height + 20, cornerRadius: 20, color: #colorLiteral(red: 0.2784313725490196, green: 0.2784313725490196, blue: 0.2784313725490196, alpha: 1.0))
        rect.name = "colorPicker"
        scene.place(rect, at: point, anchoredTo: .left)
        
        let rows = height / elementSize
        let columns = width / elementSize
        let columnDistance = Double(width) / Double(columns)
        let rowDistance = Double(height) / Double(rows)
        
        var currentPosition = Point(x: point.x, y: point.y + Double(height) / 1.65)
        
        for y in 1...rows {
            currentPosition.x = point.x + 27
            var saturation = CGFloat(y) / CGFloat(rows)
            currentPosition.y -= rowDistance
            
            for x in 1...columns {
                var color: UIColor
                
                let hue = CGFloat(x) / CGFloat(columns)
                if x == columns {
                    color = UIColor(white: saturation, alpha: 1.0)
                } else {
                    color = UIColor(hue: hue, saturation: saturation, brightness: 1, alpha: 1)
                }
                
                let square = Graphic.rectangle(width: elementSize, height: elementSize, cornerRadius: 0, color: color)
                square.name = "colorPicker"
                square.setOnTouchHandler {_ in
                    square.zPosition = 10
                    square.run(SKAction.scale(to: 2, duration: 0.2)) {
                        self.dismiss()
                        self.onSelectedColor(color)
                    }
                }
                
                scene.place(square, at: currentPosition)
                currentPosition.x += columnDistance
            }
        }
    }
}
