//
//  LearningAssessmentManager.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport
import SPCCore
import AudioToolbox

public class LearningAssessment {

    public enum State: String {
        case unknown
        case notAssessable
        case partiallyCompleted
        case completedFailed
        case completedSuccessfully
    }

    public var score: Double = 0.0
}

/// LearningAssessmentManager manages assessment recording, and coordinates between the Learning Trails and the playground book.
/// Used as a singleton, there is one instance of `LearningAssessmentManager` per process, accessed through the `shared` property.
public class LearningAssessmentManager {
    
    /// Shared instance of LearningAssessmentManager.
    public static let shared = LearningAssessmentManager()
    
    func updateAssessmentStateFor(_ learningResponse: LearningResponse, in step: LearningStep) {
        guard
            let learningTrail = step.parentTrail,
            step.isAssessable
            else { return }

        step.assessmentState = .partiallyCompleted
        
        if learningResponse.isAnsweredCorrectly {
            step.assessmentState = .completedSuccessfully
        }
        
        //PBLog("Step: \(step.identifier) LearningResponse: \(learningResponse.identifier) status: \(step.assessmentState.rawValue) ")
        
        if learningTrail.assessmentState == .completedSuccessfully {
            // Set page assessment status.
            if let currentStatus = PlaygroundPage.current.assessmentStatus, case .pass = currentStatus {
                // Avoid setting assessment status if it’s already marked as pass.
                return
            } else {
                PBLog("Trail assessment completed successfully.")
                PlaygroundPage.current.assessmentStatus = .pass(message: nil)
            }
        } else {
            // Ensure assessmentStatus is non-nil
            PlaygroundPage.current.assessmentStatus = .fail(hints: [], solution: nil)
        }
    }

    func isPageAssessmentSuccessfullyCompleted() -> Bool {
        if let currentStatus = PlaygroundPage.current.assessmentStatus, case .pass = currentStatus {
            return true
        }
        return false
    }
}
