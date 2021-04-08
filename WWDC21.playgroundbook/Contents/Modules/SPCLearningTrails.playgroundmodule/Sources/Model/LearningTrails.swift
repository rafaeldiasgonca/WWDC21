//
//  LearningTrails.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation

public class LearningTrails {
    
    // True if authoring support is enabled.
    public static var isAuthoringSupportEnabled: Bool = false {
        didSet {
            // Disable localization whenever authoring support is enabled: i.e. ignores LearningTrail.strings.
            SlimXMLParser.isLocalizationEnabled = !isAuthoringSupportEnabled
        }
    }
    
    // True if the step title should appear in the step header in place of the step type.
    public static var isStepTitleInHeader: Bool = false
}
