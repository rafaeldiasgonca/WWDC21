//
//  LearningBlock.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation

public class LearningBlock {
    
    public enum BlockType: String {
        case buttons
        case code
        case custom
        case group
        case image
        case response
        case root
        case text
        case title
        case video
        
        // Returns true if a block of this type could be valid without any content.
        // e.g. a self-closing block such as <block type="image" source="cat"/>
        var mayHaveEmptyContent: Bool {
            switch self {
            case .image, .video:
                return true
            default: break
            }
            return false
        }
    }
    
    public enum LineTrimmmingOption {
        case linesLeftTrimmed
        case none
    }
    
    public var identifier: String
    public var blockType: LearningBlock.BlockType
    public var subType: String?
    public weak var parentStep: LearningStep?
    public var attributes: [String : String]
    public var content: String
    public var isDisclosed = true
    public var isLastBlockInGroup: Bool = false
    public var initialVisibleState: Bool = true
    public var groupLevel = 0
    
    public var childBlocks = [LearningBlock]()
    
    /// Returns the content packaged inside an XML element of the block’s type.
    /// Optionally trim each line using the specified option.
    ///
    /// e.g. <text>This is a <b>lovely</b> dog.</text>
    ///
    /// - Parameter lineTrimmingOption: Specifies how the lines in the content are trimmed prior to packaging.
    ///
    public func xmlPackagedContent(_ lineTrimmingOption: LineTrimmmingOption = .none) -> String {
        var trimmedContent = self.content
        switch lineTrimmingOption {
        case .linesLeftTrimmed:
            trimmedContent = content.linesLeftTrimmed()
        default:
            break
        }
        return "<\(blockType)>\(trimmedContent)</\(blockType)>"
    }
    
    var accessibilityIdentifier: String {
        return "\(identifier).\(blockType)"
    }
    
    public var signature: String {
        let attributesSignature = attributes.sorted(by: {$0.key < $1.key}).map { $0.0 + "=" + $0.1 }.joined(separator: "\n")
        return "\(blockType)\n\(attributesSignature)\ncontent=\(content)"
    }
    
    class func createRootBlock() -> LearningBlock {
        let id = UUID().uuidString
        return LearningBlock(in: nil, identifier: id, type: .root, subType: nil, attributes: [String : String](), content: "")
    }

    init(in step: LearningStep?, identifier: String, type: LearningBlock.BlockType, subType: String?, attributes: [String : String], content: String) {
        self.parentStep = step
        self.identifier = identifier
        self.blockType = type
        self.subType = subType
        self.attributes = attributes
        self.content = content
                
        isDisclosed = (attributes["disclosed"] != "false")
    }
    
    func addBlock(in step: LearningStep?, identifier: String, type: LearningBlock.BlockType, subType: String?, attributes: [String : String], content: String, isDisclosed: Bool = true) {
        childBlocks.append(LearningBlock(in: step, identifier: identifier, type: type, subType: subType, attributes: attributes, content: content))
    }
    
    func addBlock(_ learningBlock: LearningBlock) {
        childBlocks.append(learningBlock)
    }
    
    // Recursively sets the disclosed (visible) state of any child cells.
    func initializeVisibleState(visible: Bool) {
        for childBlock in childBlocks {
            childBlock.initialVisibleState = visible
            
            var newVisibleState = visible
            if visible == false {
                newVisibleState = false
            } else {
                if childBlock.blockType == .group {
                    newVisibleState = childBlock.isDisclosed
                }
            }
            childBlock.initializeVisibleState(visible: newVisibleState)
        }
    }
    
    // Recursively sets the group state of any child cells.
    func initializeGroupState(level: Int) {
        for childBlock in childBlocks {
            
            childBlock.groupLevel = level
            
            // Flag if cell is the last block in a group.
            childBlock.isLastBlockInGroup = false
            if childBlock == childBlocks.last,
                self.blockType == .group
            {
                childBlock.isLastBlockInGroup = true
            }
            
            // If the LearningBlock is a group, recurse over its children.
            if childBlock.blockType == .group {
               childBlock.initializeGroupState(level: level + 1)
            }
        }
    }

}

extension LearningBlock: Equatable {
    public static func ==(lhs: LearningBlock, rhs: LearningBlock) -> Bool {
        return (lhs.identifier == rhs.identifier)
    }
}

extension LearningBlock: CustomStringConvertible {
    public var description: String {
        return "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque()) \(blockType)>"
    }
}
