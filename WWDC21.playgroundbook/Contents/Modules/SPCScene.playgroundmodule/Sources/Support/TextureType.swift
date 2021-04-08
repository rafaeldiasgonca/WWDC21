//
//  TextureType.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import CoreGraphics
enum TextureType {
    
    case background
    case graphic
    
    var maximumSize: CGSize {
        switch self {
        case .background:
            return CGSize(width: 1400, height: 1400)
            
        case .graphic:
            return CGSize(width: 500, height: 500)
        }
    }
    
    static var backgroundMaxSize = CGSize(width: 1366, height: 1366)
    static var graphicMaxSize = CGSize(width: 500, height: 500)
}
