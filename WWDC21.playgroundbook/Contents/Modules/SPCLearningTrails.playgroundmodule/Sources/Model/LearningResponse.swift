//
//  LearningResponse.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport
import SPCCore

public class LearningResponse {
    
    public enum ResponseType: String {
        case multiplechoice
        case singlechoice
        case freetext
    }
    
    public private(set) var identifier: String
    public private(set) var name: String?
    public private(set) var promptXML: String?
    public var options = [LearningResponseOption]()
    
    private var isValid = false
    
    private var optionTextXML: String?
    private var optionFeedbackXML: String?

    // Indicates the type of response required.
    public private(set) var responseType: ResponseType = .multiplechoice
    
    // Indicates whether the confirm button must be pressed to reveal answers.
    public private(set) var isConfirmRequired = false
    
    // Indicates whether the confirm button has been pressed.
    public var isConfirmed = false
    
    // Set to true once the correct options have been selected.
    // If isConfirmRequired is false, the correct options must all be selected.
    // If isConfirmRequired is true, the correct options must all be selected and the confirm button pressed.
    public var isAnsweredCorrectly: Bool {
        var isCorrect = false
        for option in options {
            if option.type == .correct {
                if !option.isSelected { return false }
                isCorrect = true
            }
        }
        return isCorrect
    }
    
    init?(identifier: String, xml: String, attributes: [String : String]) {
        self.identifier = identifier
        name = attributes["name"]
        if let name = name { self.identifier += ".\(name)"}
        
        if let subtype = attributes["subtype"] {
            if subtype == "multiple-choice" {
                responseType = .multiplechoice
            } else if subtype == "single-choice" {
                responseType = .singlechoice
            }
        }
        
        isConfirmRequired = (attributes["confirm"] == "true")
        
        let parser = SlimXMLParser(xml: xml)
        parser.delegate = self
        parser.parse()
        
        isValid = options.count > 0
        
        if options.filter({$0.type == .correct}).count > 0 {
            for index in 0..<options.count {
                if options[index].type != .correct {
                    options[index].type = .wrong
                }
            }
        }

        if isValid {
            PBLog("Learning Response loaded: (\(self.identifier)) with \(options.count) options.")
        } else {
            PBLog("Failed to load Learning Response.")
            return nil
        }
    }
    
    // Saves the state of the user response.
    public func saveState() {
        var state = [String : PlaygroundValue]()
        for (index, option) in options.enumerated() {
            guard let optionValue = option.isSelected.playgroundValue else { continue }
            let optionKey = "Option.\(index)"
            state[optionKey] = optionValue
        }
        if let confirmedValue = isConfirmed.playgroundValue {
            state["IsConfirmed"] = confirmedValue
        }
        PBLog("Saving state for Learning Response: \(identifier) \(isConfirmed ? "confirmed" : "")")
        PlaygroundKeyValueStore.current[identifier] = .dictionary(state)
    }
    
    // Loads any saved state from a previous user response. Returns `true` if successful.
    public func loadState() -> Bool {
        guard let stateValue = PlaygroundKeyValueStore.current[identifier],
            case let .dictionary(state) = stateValue
            else {
                return false // No saved state found.
        }
        if state.isEmpty {
            PBLog("Empty state for Learning Response: \(identifier)")
            return false
        }
        PBLog("Loading state for Learning Response: \(identifier)")
        for index in 0..<options.count {
            let optionKey = "Option.\(index)"
            if let optionValue = state[optionKey], case let .boolean(value) = optionValue {
                options[index].isSelected = value
            } else {
                PBLog("Missing \(optionKey) in saved state for Learning Response: \(identifier)")
                return false
            }
        }
        if let confirmedValue = state["IsConfirmed"], case let .boolean(value) = confirmedValue {
            isConfirmed = value
        }
        return true
    }
    
    // Removes any saved state from a previous user response.
    public func clearState() {
        PBLog("Remove state for Learning Response: \(identifier)")
        let emptyState = [String : PlaygroundValue]()
        PlaygroundKeyValueStore.current[identifier] = .dictionary(emptyState)
    }
}

extension LearningResponse: SlimXMLParserDelegate {
    
    func parser(_ parser: SlimXMLParser, didStartElement element: SlimXMLElement) {
        switch element.name {
        case "option":
            optionTextXML = nil
            optionFeedbackXML = nil
        default:
            break
        }

    }
    
    func parser(_ parser: SlimXMLParser, didEndElement element: SlimXMLElement) {
        switch element.name {
        case "prompt":
            guard let xmlContent = element.xmlContent else { break }
            promptXML = xmlContent
        case "option":
            let textXML = optionTextXML ?? element.xmlContent
            guard let optionTextXML = textXML else { break }
            options.append(LearningResponseOption(textXML: optionTextXML, feedbackXML: optionFeedbackXML, type: element.attributes["type"]))
        case "text":
            optionTextXML = element.xmlContent
        case "feedback":
            optionFeedbackXML = element.xmlContent
        default:
            break
        }
    }
    
    func parser(_ parser: SlimXMLParser, foundCharacters string: String) {
    }
    
    func parser(_ parser: SlimXMLParser, shouldCaptureElementContent elementName: String, attributes: [String : String]) -> Bool {
        switch elementName {
        case "prompt", "option", "feedback", "text":
            return true
        default:
            return false
        }
    }
    
    func parser(_ parser: SlimXMLParser, shouldLocalizeElementWithID elementName: String) -> Bool {
        return true
    }
    
    func parser(_ parser: SlimXMLParser, parseErrorOccurred parseError: Error, lineNumber: Int) {
        NSLog("\(parseError.localizedDescription) at line: \(lineNumber)")
    }
}
