//
//  HotspotButton.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

class HotspotButton: UIButton {
    
    private static var hotspotImage: UIImage? = {
        return UIImage(named: "hotspot")?.withRenderingMode(.alwaysTemplate)
    }()
    
    var hotspot: LearningInteractive.Hotspot?
    
    convenience init(hotspot: LearningInteractive.Hotspot) {
        self.init(frame: CGRect.zero)
        self.hotspot = hotspot
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setImage(HotspotButton.hotspotImage, for: .normal)
        backgroundColor = UIColor.clear
        accessibilityLabel = NSLocalizedString("Hotspot", tableName: "SPCLearningTrails", comment: "AX label hotspot button")
        accessibilityHint = NSLocalizedString("Tap to show more about this part of the image", tableName: "SPCLearningTrails", comment: "AX hint for hotspot button")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
