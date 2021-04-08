//
//  GradientView.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

class GradientView: UIView {
    
    private var gradientLayer = CAGradientLayer()
    
    init(colors: [UIColor], locations: [NSNumber], startPoint: CGPoint = CGPoint(x: 0, y: 0), endPoint: CGPoint = CGPoint(x: 0, y: 1)) {
        super.init(frame: .zero)
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.locations = locations
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        layer.addSublayer(gradientLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = self.bounds
    }
}
