//
//  HelperExtensions.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation

extension Int {
    
    /// Generates a random Int (whole number) in the given range.
    ///
    /// - Parameter from: The lowest value that the random number can have.
    /// - Parameter to: The highest value that the random number can have.
    ///
    /// - localizationKey: Int.random(from:to:)
    static func random(from: Int, to: Int) -> Int {
        let maxValue: Int = Swift.max(from, to)
        let minValue = Swift.min(from, to)
        if minValue == maxValue {
            return minValue
        } else {
            return (Int(arc4random())%(1 + maxValue - minValue)) + minValue
        }
    }
}

extension Float {
    
    /// Generates a random Float in the given range.
    ///
    /// - Parameter from: The lowest value that the random number can have.
    /// - Parameter to: The highest value that the random number can have.
    ///
    /// - localizationKey: Float.random(from:to:)
    static func random(from: Float, to: Float) -> Float {
        let maxValue = max(from, to)
        let minValue = min(from, to)
        if minValue == maxValue {
            return minValue
        } else {
            // Between 0.0 and 1.0
            let randomScaler = Float(arc4random()) / Float(UInt32.max)
            return (randomScaler * (maxValue-minValue)) + minValue
        }
    }
}

extension Double {
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
