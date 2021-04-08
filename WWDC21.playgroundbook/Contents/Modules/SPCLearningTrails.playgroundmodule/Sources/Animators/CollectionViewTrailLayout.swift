//
//  CollectionViewTrailLayout.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

final class CollectionViewTrailLayout: UICollectionViewLayout {
    
    enum Element: String {
        case sectionHeader
        case cell
        
        var id: String {
            return self.rawValue
        }
        
        var kind: String {
            return "Kind\(self.rawValue.capitalized)"
        }
    }
    
    override class var layoutAttributesClass: AnyClass {
        return CollectionViewStepLayoutAttributes.self
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: collectionViewHeight)
    }
    
    var settings = CollectionViewTrailLayoutSettings()
    
    private var oldBounds = CGRect.zero
    private var contentWidth = CGFloat()
    private var cache = [Element: [IndexPath: CollectionViewStepLayoutAttributes]]()
    private var visibleLayoutAttributes = [CollectionViewStepLayoutAttributes]()
    private var zIndex = 0
    
    private var collectionViewHeight: CGFloat {
        return collectionView!.frame.height
    }
    
    private var collectionViewWidth: CGFloat {
        return collectionView!.frame.width
    }
    
    private var contentOffset: CGPoint {
        return collectionView!.contentOffset
    }
    
    private var cellHeight: CGFloat {
        guard let itemSize = settings.itemSize else {
            return collectionViewHeight
        }
        
        return itemSize.height
    }
    
    private var cellWidth: CGFloat {
        guard let itemSize = settings.itemSize else {
            return collectionViewWidth
        }
        
        return itemSize.width
    }
    
    private var sectionsHeaderSize: CGSize {
        guard let sectionsHeaderSize = settings.sectionsHeaderSize else {
            return CGSize(width: collectionViewWidth, height: 64)
        }
        
        return sectionsHeaderSize
    }
}

extension CollectionViewTrailLayout {
    
    override func prepare() {
        guard let collectionView = collectionView, cache.isEmpty else { return }
        
        prepareCache()
        contentWidth = 0
        zIndex = 0
        oldBounds = collectionView.bounds
        let itemSize = CGSize(width: cellWidth, height: cellHeight)
        
        for section in 0..<collectionView.numberOfSections {
            let sectionHeaderAttributes = CollectionViewStepLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(item: 0, section: section))
            prepareElement(
                size: sectionsHeaderSize,
                type: .sectionHeader,
                attributes: sectionHeaderAttributes)
            
            for item in 0..<collectionView.numberOfItems(inSection: section) {
                let cellIndexPath = IndexPath(item: item, section: section)
                let attributes = CollectionViewStepLayoutAttributes(forCellWith: cellIndexPath)
                let lineInterSpace = settings.minimumLineSpacing
                attributes.frame = CGRect(x: contentWidth + lineInterSpace, y: 0 + settings.minimumInteritemSpacing, width: itemSize.width, height: itemSize.height)
                attributes.zIndex = zIndex
                contentWidth = attributes.frame.maxX
                cache[.cell]?[cellIndexPath] = attributes
                zIndex += 1
            }
        }
    }
    
    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if oldBounds.size != newBounds.size {
            cache.removeAll(keepingCapacity: true)
        }
        return true
    }
    
    private func prepareCache() {
        cache.removeAll(keepingCapacity: true)
        cache[.sectionHeader] = [IndexPath: CollectionViewStepLayoutAttributes]()
        cache[.cell] = [IndexPath: CollectionViewStepLayoutAttributes]()
    }
    
    private func prepareElement(size: CGSize, type: Element, attributes: CollectionViewStepLayoutAttributes) {
        guard size != .zero else { return }
        
        if type == .sectionHeader {
            attributes.initialOrigin = CGPoint.zero
            attributes.frame = CGRect(origin: attributes.initialOrigin, size: size)
        } else if type == .cell {
            attributes.initialOrigin = CGPoint(x: contentWidth, y: 0)
            attributes.frame = CGRect(origin: attributes.initialOrigin, size: size)
            contentWidth = attributes.frame.maxX
        }
        
        cache[type]?[attributes.indexPath] = attributes
    }
}

extension CollectionViewTrailLayout {
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return nil
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[.cell]?[indexPath]
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView else { return nil }
        
        visibleLayoutAttributes.removeAll(keepingCapacity: true)
        
        for (type, elementInfos) in cache {
            for (indexPath, attributes) in elementInfos {
                // update attributes here
                
                updateSupplementaryViews(type, attributes: attributes, collectionView: collectionView, indexPath: indexPath)
                if attributes.frame.intersects(rect) {
                    if type == .cell {
                        updateCells(attributes)
                    }
                    visibleLayoutAttributes.append(attributes)
                }
            }
        }
        
        return visibleLayoutAttributes
    }
    
    private func updateSupplementaryViews(_ type: Element, attributes: CollectionViewStepLayoutAttributes, collectionView: UICollectionView, indexPath: IndexPath) {
        guard type == .sectionHeader else { return }
        
        attributes.transform = CGAffineTransform(translationX: contentOffset.x, y: 0)
    }
    
    private func updateCells(_ attributes: CollectionViewStepLayoutAttributes) {
        
        let cellIndex = CGFloat(attributes.indexPath.row)
        let xOffset = contentOffset.x
        let cellOffsetX = cellIndex * cellWidth
        let scrollingBeyondLimit = xOffset < 0.0 || xOffset > (collectionViewContentSize.width - cellWidth)
        
        let headerAlpha = min(1, max(0, 1 - (cellOffsetX - xOffset) / cellWidth))
        let headerTitleAlpha = min(1, max(0, 1 - abs((cellOffsetX - xOffset)) / 75.0))
        let contentAlpha = min(1, max(0, 1 - abs((cellOffsetX - xOffset)) / cellWidth))
        
        let headerTranslationX = -1 * cellOffsetX + xOffset
        let headerContentTranslationX = max(-1 * cellWidth, min(cellWidth * 0.2, cellOffsetX - xOffset))
        
        attributes.headerAlpha = scrollingBeyondLimit ? 1.0 : headerAlpha
        attributes.headerTitleAlpha = scrollingBeyondLimit ? 1.0 : headerTitleAlpha
        attributes.contentAlpha = scrollingBeyondLimit ? 1.0 : contentAlpha
                
        attributes.headerTransform = CGAffineTransform.identity.translatedBy(x: headerTranslationX, y: 0.0)
        attributes.headerContentTransform = scrollingBeyondLimit ? CGAffineTransform.identity : CGAffineTransform.identity.translatedBy(x: headerContentTranslationX, y: 0.0)
    }
}
