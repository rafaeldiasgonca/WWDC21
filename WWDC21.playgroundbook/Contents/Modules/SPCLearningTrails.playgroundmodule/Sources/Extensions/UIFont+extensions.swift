//
//  UIFont+extensions.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

public enum FontFileExtension: String {
    case ttf, otf
}

extension UIFont {
    
    // Loads and registers a font from a URL.
    static func registerFont(from fontFileURL: URL) -> String? {
        let cgFontDataProvider    = CGDataProvider(url: fontFileURL as CFURL)!
        let cgFont                = CGFont(cgFontDataProvider)
        let fontName              = cgFont!.postScriptName as String?
        
        if CTFontManagerRegisterGraphicsFont(cgFont!, nil) {
            return fontName
        }
        else {
            return nil
        }
    }
    
    // Loads and registers a font from a resource in the main bundle.
    static func registerFontFromResource(named resourceName: String, fontfileExtension: FontFileExtension) -> String? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: fontfileExtension.rawValue),
            let fontName = UIFont.registerFont(from: url) else {
                return nil
        }
        return fontName
    }
}

