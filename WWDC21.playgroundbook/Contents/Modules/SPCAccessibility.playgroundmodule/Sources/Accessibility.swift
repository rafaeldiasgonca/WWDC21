//
//  Accessibility.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import SPCCore
import UIKit

public class Accessibility {
    public static func announce(_ announcement: String) {
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}
