//
//  GraphicAccessibilityElement.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import UIKit
import SPCAccessibility

class GraphicAccessibilityElement : UIAccessibilityElement {
    let identifier: String
    let delegate: GraphicAccessibilityElementDelegate
    let accessibilityHints: AccessibilityHints
    
    var graphics = [Graphic]()
    
    init(delegate: GraphicAccessibilityElementDelegate, identifier: String, accessibilityHints: AccessibilityHints) {
        self.identifier = identifier
        self.delegate = delegate
        self.accessibilityHints = accessibilityHints
        
        super.init(accessibilityContainer: delegate)
        
        accessibilityIdentifier = identifier
    }
    
    public override var accessibilityLabel: String? {
        set {
            // no-op
        }
        get {
            return delegate.accessibilityLabel(element: self)
        }
    }
    
    public override var accessibilityFrame: CGRect {
        set {
            // no-op
        }
        get {
            return delegate.accessibilityFrame(element: self)
        }
    }
    
    public override var accessibilityTraits: UIAccessibilityTraits {
        set { }
        get {
            return delegate.accessibilityTraits(element: self)
        }
    }
    
    public override var accessibilityCustomActions : [UIAccessibilityCustomAction]? {
        set { }
        get {
            var actions: [UIAccessibilityCustomAction]? = nil
            
            if accessibilityHints.actions.contains(.drag) {
                actions = [UIAccessibilityCustomAction(name: NSLocalizedString("Graphic drag.", tableName: "SPCScene", comment: "AX action name"), target: self, selector: #selector(graphicDragAXAction))]
            }
            
            return actions
        }
    }
    
    @objc func graphicDragAXAction() {
        if graphics.count > 0 {
            let total = 50
            var count = 0
            let frame = accessibilityFrame
            
            _ = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                if count == total {
                    timer.invalidate()
                }
                
                
                let x = Double(frame.origin.x) + Double(frame.size.width) * (Double(count) / Double(total))
                let y = Double(frame.origin.y + frame.size.height) - Double(frame.size.height) * (Double(count) / Double(total))
                
                self.delegate.accessibilitySimulateTouch(at: CGPoint(x: x, y: y), firstTouch: count == 0, lastTouch: count == total)
                
                count += 1
            }
        }
    }
}

protocol GraphicAccessibilityElementDelegate {
    func accessibilityLabel(element: GraphicAccessibilityElement) -> String
    func accessibilityFrame(element: GraphicAccessibilityElement) -> CGRect
    func accessibilityTraits(element: GraphicAccessibilityElement) -> UIAccessibilityTraits
    
    func accessibilitySimulateTouch(at point: CGPoint, firstTouch: Bool, lastTouch: Bool)
}
