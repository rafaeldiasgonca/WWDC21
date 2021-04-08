//
//  LearningTrail.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import PlaygroundSupport
import SPCCore

public class LearningTrail {
    public var name: String
    public var steps = [LearningStep]()
    
    public lazy var assessableSteps: [LearningStep] = {
        return steps.filter{ $0.isAssessable }
    }()
    
    public var url: URL? {
        return Bundle.main.url(forResource: name, withExtension: "xml")
    }
    
    /// The current state of assessment for this trial.
    public var assessmentState: LearningAssessment.State {
        guard assessableSteps.count > 0 else { return .notAssessable }
        let partiallyCompletedSteps = assessableSteps.filter{ ($0.assessmentState == .partiallyCompleted) }
        if partiallyCompletedSteps.count > 0 {
            return .partiallyCompleted
        } else {
            let successfullyCompletedSteps = assessableSteps.filter{ ($0.assessmentState == .completedSuccessfully) }
            if successfullyCompletedSteps.count == assessableSteps.count {
                return .completedSuccessfully
            }
        }
        return .unknown
    }
    
    public var backgroundImageURL: URL?
    
    public var errorMessage = ""
    
    public convenience init() {
        self.init(name: "LearningTrail")
    }
    
    public init(name: String) {
        self.name = name
    }
    
    public func load(completion: ((Bool) -> Void)?) {
        guard
            let url = self.url,
            let xml = try? String(contentsOf: url, encoding: String.Encoding.utf8)
            else {
                PBLog("Failed to locate Learning Trail named: \(name)")
                completion?(false)
                return
        }
        currentStepNumber = 0
        currentBlockNumber = 0
        
        let parser = SlimXMLParser(xml: xml)
        parser.delegate = self
        parser.parse()

        if identifier.isEmpty {
            // Trail must have an identifier.
            errorMessage = "Missing trail identifier."
        }
        let success = errorMessage.isEmpty
        if success {
            PBLog("Learning Trail loaded: \(identifier) with \(steps.count) steps.")
        } else {
            PBLog("Error loading Learning Trail: \(errorMessage)")
        }

        if success {
            loadState(completion: {
                completion?(success)
            })
        } else {
            completion?(success)
        }
    }
    
    public var identifier: String = ""
    private var currentStep: LearningStep?
    private var currentParentBlock: LearningBlock?
    private var parentBlocksStack = [LearningBlock]()
    private var currentStepNumber = 0
    private var currentStepIdentifier: String {
        return "\(identifier).step.\(String(format: "%02d", currentStepNumber))"
    }
    private var currentBlockNumber = 0
    private var currentBlockIdentifier: String {
        return "\(currentStepIdentifier).block.\(String(format: "%02d", currentBlockNumber))"
    }
    
    private var trailStateLoadedKey: String {
        return "TrailStateLoaded.\(self.identifier)"
    }
    
    var isTrailStateMarkedAsLoaded: Bool {
        get {
            return PlaygroundKeyValueStore.current[trailStateLoadedKey] != nil
        }
        set {
            if PlaygroundPage.current.assessmentStatus == nil {
                // If page assessment status hasn’t been set yet, set it to .fail.
                // This can be used to detect if the page has been reset: see pageHasBeenReset().
                PlaygroundPage.current.assessmentStatus = newValue ? .fail(hints: [], solution: nil) : nil
            }
            if newValue, let trueValue = true.playgroundValue {
                PlaygroundKeyValueStore.current[trailStateLoadedKey] = trueValue
            }
        }
    }
    
    // Loads state for all steps.
    func loadState(completion: (() -> Void)?) {
        let isStateValid = !pageHasBeenReset()
        var message = "trail: \(identifier)"
        message += isStateValid ? "" : " page has been reset"
        
        for step in steps {
            step.loadState(isValid: isStateValid)
        }
        PBLog("Learning Trail state loaded for trail: \(identifier) \(message)")
        
        isTrailStateMarkedAsLoaded = true
        
        completion?()
    }
    
    func pageHasBeenReset() -> Bool {
        if isTrailStateMarkedAsLoaded,
            PlaygroundPage.current.assessmentStatus == nil
        {
            // Assessment status has been cleared, most likely by a page reset.
            PBLog("Page has been reset for trail: \(identifier)")
            return true
        }
        return false
    }
    
    func updateStepsFrom(trail: LearningTrail, completion: (([Int]) -> Void)?) {
        guard trail.steps.count == steps.count else {
            // Updating from a trail with a different number of steps is not supported.
            PBLog("Updating from a trail with a different number of steps is not supported.")
            completion?([])
            return
        }
        
        var updatedStepIndexes = [Int]()
        for (index, step) in steps.enumerated() {
            let freshStep = trail.steps[index]
            if freshStep.signature != step.signature {
                PBLog("Updating step: \(index)")
                steps[index] = freshStep
                updatedStepIndexes.append(index)
            }
        }
        
        completion?(updatedStepIndexes)
    }
    
}

extension LearningTrail: SlimXMLParserDelegate {
    
    func parser(_ parser: SlimXMLParser, didStartElement element: SlimXMLElement) {
        switch element.name {
        case "groupblock":
            currentBlockNumber += 1
            let blockIdentifier = element.attributes["name"] ?? currentBlockIdentifier
            let groupBlock = LearningBlock(in: currentStep, identifier: blockIdentifier, type: .group, subType: nil, attributes: element.attributes, content: "")
            
            if let parentBlock = currentParentBlock {
                parentBlock.addBlock(groupBlock)
                parentBlocksStack.append(parentBlock)
            }
            currentParentBlock = groupBlock
        case "block":
            currentBlockNumber += 1
        case "blocks":
            currentParentBlock = currentStep?.rootBlock
        case "step":
            currentStepNumber += 1
            currentBlockNumber = 0
            let stepIdentifier = element.attributes["name"] ?? currentStepIdentifier
            currentStep = LearningStep(in: self, identifier: stepIdentifier, index: currentStepNumber - 1)
            if let typeValue = element.attributes["type"], let stepType = LearningStep.StepType(rawValue: typeValue) {
                currentStep?.type = stepType
            }
        case "trail":
            identifier = "trail.\(element.attributes["name"] ?? UUID().uuidString)"
            if let backgroundImageValue = element.attributes["backgroundImage"], let url = Bundle.main.url(forResource: backgroundImageValue, withExtension: "png") {
                backgroundImageURL = url
            }
        case "assessment":
            currentStep?.isAssessable = true
        default:
            break
        }
    }
    
    func parser(_ parser: SlimXMLParser, didEndElement element: SlimXMLElement) {
        guard let step = currentStep else { return }
        
        switch element.name {
        case "block", "groupblock":
            let blockIdentifier = element.attributes["id"] ?? currentBlockIdentifier
            
            var type: LearningBlock.BlockType?
            if element.name == "groupblock" {
                type = .group
            } else if let typeValue = element.attributes["type"] {
                type = LearningBlock.BlockType(rawValue: typeValue)
            }
            guard let blockType = type else {
                PBLog("Block type not specified.")
                return
            }
            
            if blockType == .title, let parentBlock = currentParentBlock, parentBlock.blockType == .group {
                parentBlock.content = element.xmlContent ?? ""
            } else if blockType == .group {
                // Nothing to add since group block was added in didStartElement
            } else {
                if blockType == .title {
                    if let parentBlock = currentParentBlock, parentBlock == step.rootBlock {
                        currentStep?.title = element.plainContent ?? ""
                    }
                    
                    if LearningTrails.isStepTitleInHeader {
                        // Title is in the step header => no need to add a block to hold the title.
                        return
                    }
                }
                
                let content = element.content ?? ""
                var hasValidContent = true
                if content.isEmpty && !blockType.mayHaveEmptyContent {
                    // Avoid creating blocks that have no content unless justified.
                    hasValidContent = false
                }
                // Add a block of the specified type.
                if hasValidContent {
                    currentParentBlock?.addBlock(in: step, identifier: blockIdentifier, type: blockType, subType: element.attributes["subtype"], attributes: element.attributes, content: content)
                }
            }
            
            if blockType == .group {
                currentParentBlock = parentBlocksStack.popLast()
            }
            
        case "step":
            step.initializeState()
            steps.append(step)
            currentStep = nil
        default:
            break
        }

    }
    
    func parser(_ parser: SlimXMLParser, foundCharacters string: String) { }
    
    func parser(_ parser: SlimXMLParser, shouldCaptureElementContent elementName: String, attributes: [String : String]) -> Bool {
        if elementName == "block", let _ = attributes["type"] {
            return true
        }
        
        if ["text", "title", "cmt", "str"].contains(elementName)  {
            return true
        }
        
        if elementName == "groupblock" {
            return true
        }
        
        return false
    }
    
    func parser(_ parser: SlimXMLParser, shouldLocalizeElementWithID elementName: String) -> Bool {
        return true
    }
    
    func parser(_ parser: SlimXMLParser, parseErrorOccurred parseError: Error, lineNumber: Int) {
        PBLog("\(parseError.localizedDescription) at line: \(lineNumber)")
        errorMessage = "Parse error at line: \(lineNumber)"
    }
}

