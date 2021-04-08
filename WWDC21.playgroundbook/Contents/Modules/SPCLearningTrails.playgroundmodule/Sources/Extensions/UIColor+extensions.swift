//
//  UIColor+extensions.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

public extension UIColor {
    
    var redComponent: CGFloat {
        var component = CGFloat()
        getRed(&component, green: nil, blue: nil, alpha: nil)
        return component
    }
    
    var greenComponent: CGFloat {
        var component = CGFloat()
        getRed(nil, green: &component, blue: nil, alpha: nil)
        return component
    }
    
    var blueComponent: CGFloat {
        var component = CGFloat()
        getRed(nil, green: nil, blue: &component, alpha: nil)
        return component
    }
    
    var alphaComponent: CGFloat {
        var component = CGFloat()
        getRed(nil, green: nil, blue: nil, alpha: &component)
        return component
    }
    
    static var random: UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    convenience init(red: Int, green: Int, blue: Int, alpha: Int = 255) {
        self.init(red: CGFloat(min(red, 255)) / 255.0,
                  green: CGFloat(min(green, 255)) / 255.0,
                  blue: CGFloat(min(blue, 255)) / 255.0,
                  alpha: CGFloat(min(alpha, 255)) / 255.0)
    }
    
    // Creates a color from a delimited string like this "0.5, 0.4, 0.1, 1.0" rgba
    convenience init(delimitedList: String) {
        var validCharacters = CharacterSet.decimalDigits
        validCharacters.insert(".") // "01234567890."
        let cleanedList = delimitedList.trimmingCharacters(in: validCharacters.inverted)
        let components = cleanedList.components(separatedBy: ",").map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
        var values: [CGFloat] = [0.0, 0.0, 0.0, 0.0]
        let componentValues = components.map{ min(Float($0) ?? 0.0, 1.0) }
        for i in 0..<min(componentValues.count, values.count) {
            values[i] = CGFloat(componentValues[i])
        }
        self.init(red: values[0], green: values[1], blue: values[2], alpha: values[3])
    }
}
