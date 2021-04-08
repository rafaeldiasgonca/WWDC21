//
//  LearningResponseOption.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation

public struct LearningResponseOption {
    
    // The types of response option: e.g. a correct answer, or a wrong answer.
    public enum OptionType: String {
        case unspecified
        case correct
        case wrong
    }
    
    // The states that a response option can be in.
    enum State {
        case unchecked
        case chosen
        case correct
        case wrong
    }
    
    public private(set) var textXML: String
    public private(set) var feedbackXML: String?
    public var type: OptionType
    
    public var isSelected = false
    
    public var isSelectedAndCorrect: Bool {
        return (type == .correct) && isSelected
    }
    
    public var isSelectedAndWrong: Bool {
        return (type == .wrong) && isSelected
    }
    
    public var hasFeedback: Bool {
        return feedbackXML != nil
    }
    
    init(textXML: String, feedbackXML: String?, type: String?) {
        self.textXML = textXML
        self.feedbackXML = feedbackXML
        self.type = .unspecified
        if let type = type, let optionType = OptionType(rawValue: type) {
            self.type = optionType
        }
    }
}
