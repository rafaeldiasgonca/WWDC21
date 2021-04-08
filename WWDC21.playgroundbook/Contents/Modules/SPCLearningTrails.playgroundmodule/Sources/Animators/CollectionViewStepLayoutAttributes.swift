//
//  CollectionViewStepLayoutAttributes.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

final class CollectionViewStepLayoutAttributes: UICollectionViewLayoutAttributes {
    var initialOrigin = CGPoint.zero
    var headerTransform = CGAffineTransform.identity
    var headerContentTransform = CGAffineTransform.identity
    var headerAlpha: CGFloat = 1.0
    var headerTitleAlpha: CGFloat = 1.0
    var contentAlpha: CGFloat = 1.0
    
    override func copy(with zone: NSZone?) -> Any {
        guard let copiedAttributes = super.copy(with: zone) as? CollectionViewStepLayoutAttributes else {
            return super.copy(with: zone)
        }
        
        copiedAttributes.initialOrigin = initialOrigin
        copiedAttributes.headerTransform = headerTransform
        copiedAttributes.headerContentTransform = headerContentTransform
        copiedAttributes.headerAlpha = headerAlpha
        copiedAttributes.headerTitleAlpha = headerTitleAlpha
        copiedAttributes.contentAlpha = contentAlpha
        return copiedAttributes
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherAttributes = object as? CollectionViewStepLayoutAttributes else {
            return false
        }
        
        if otherAttributes.initialOrigin != initialOrigin
            || otherAttributes.headerTransform != headerTransform
            || otherAttributes.headerContentTransform != headerContentTransform
            || otherAttributes.headerAlpha != headerAlpha
            || otherAttributes.headerTitleAlpha != headerTitleAlpha
            || otherAttributes.contentAlpha != contentAlpha {
            return false
        }
        
        return super.isEqual(object)
    }
}
