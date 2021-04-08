//
//  AddressableContentBorderView.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

public class AddressableContentBorderView : UIView {
    override public var isOpaque: Bool {
        set {}
        get { return false }
    }
    
    override public func draw(_ rect: CGRect) {
        UIColor.clear.set()
        let path = UIBezierPath(rect: bounds.inset(by: UIEdgeInsets(top: 0.5, left: 0.5, bottom: 0.5, right: 0.5)))
        path.fill()
        
        let pattern = Array<CGFloat>(arrayLiteral: 3.0, 3.0)
        path.lineJoinStyle = .round
        // draw a set of white dashes
        UIColor.white.set()
        path.setLineDash(pattern, count: 2, phase: 0.0)
        path.stroke()
        // draw black dashes in the gaps
        UIColor.systemGray.set()
        path.setLineDash(pattern, count: 2, phase: 3.0)
        path.stroke()
    }
    
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if (view == self) {
            return nil
        }
        return view
    }
}

