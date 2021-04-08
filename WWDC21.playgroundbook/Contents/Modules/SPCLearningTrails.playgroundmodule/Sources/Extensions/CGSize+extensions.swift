//
//  CGSize+extensions.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

extension CGSize {
    
    public func scaleToFit(within availableSize: CGSize) -> CGFloat {
        let aspectWidth = availableSize.width / width
        let aspectHeight = availableSize.height / height
        return min(aspectWidth, aspectHeight)
    }
    
    public func scaledToFit(within availableSize: CGSize) -> CGSize {
        let aspectRatio = scaleToFit(within: availableSize)
        return CGSize(width: width * aspectRatio, height: height * aspectRatio)
    }

}
