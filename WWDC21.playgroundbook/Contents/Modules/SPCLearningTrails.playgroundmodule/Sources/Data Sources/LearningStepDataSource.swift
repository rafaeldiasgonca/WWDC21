//
//  LearningStepDataSource.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import SPCCore

public protocol LearningStepDataSource {
    var step: LearningStep { get }
    var blockCount: Int  { get }
    init(step: LearningStep)
    func styleForLearningStep(_ learningStep: LearningStep) -> LearningStepStyle?
    func styleForLearningBlock(_ learningBlock: LearningBlock) -> LearningBlockStyle?
    func textStyleForLearningBlock(_ learningBlock: LearningBlock) -> AttributedStringStyle?
    func viewForLearningBlock(_ learningBlock: LearningBlock) -> LearningBlockView?
}

extension LearningStepDataSource {
    public var blockCount: Int  {
        return step.blocks.count
    }
}

open class DefaultLearningStepDataSource: LearningStepDataSource {
    public var step: LearningStep
    
    required public init(step: LearningStep) {
        self.step = step
    }

    open func viewForLearningBlock(_ learningBlock: LearningBlock) -> LearningBlockView? {
        guard let style = styleForLearningBlock(learningBlock) else {
            PBLog("Style not found for learning block of type: \(learningBlock.blockType)")
            return nil
        }
        let textStyle = textStyleForLearningBlock(learningBlock)
    
        var learningBlockView: LearningBlockView?
        switch learningBlock.blockType {
        case .buttons:
            let choicesView = ButtonsLearningBlockView()
            choicesView.load(learningBlock: learningBlock, style: style, textStyle: textStyle)
            learningBlockView = choicesView
        case .code:
            let codeView = CodeLearningBlockView()
            codeView.load(learningBlock: learningBlock, style: style, textStyle: textStyle)
            learningBlockView = codeView
        case .custom:
            return nil
        case .group:
            let groupView = GroupLearningBlockView()
            groupView.load(learningBlock: learningBlock, style: style, textStyle: textStyle)
            learningBlockView = groupView
        case .image:
            let imageView = ImageLearningBlockView()
            imageView.load(learningBlock: learningBlock, style: style, textStyle: textStyle)
            learningBlockView = imageView
        case .response:
            let responseView = ResponseLearningBlockView()
            responseView.load(learningBlock: learningBlock, style: style, textStyle: textStyle)
            learningBlockView = responseView
        case .root:
            return nil
        case .text, .title:
            let textView = TextLearningBlockView()
            textView.load(learningBlock: learningBlock, style: style, textStyle: textStyle)
            learningBlockView = textView
        case .video:
            let videoView = VideoLearningBlockView()
            videoView.load(learningBlock: learningBlock, style: style, textStyle: textStyle)
            learningBlockView = videoView
        }
        return learningBlockView
    }
    
    open func styleForLearningStep(_ learningStep: LearningStep) -> LearningStepStyle? {
        
        var style: LearningStepStyle?
        switch learningStep.type {
        case .check:
            style = CheckLearningStepStyle()
        case .code:
            style = CodeLearningStepStyle()
        case .context:
            style = ContextLearningStepStyle()
        case .experiment:
            style = ExperimentLearningStepStyle()
        case .find:
            style = FindLearningStepStyle()
        default:
            style = DefaultLearningStepStyle()
        }
        
        return style
    }
    
    open func styleForLearningBlock(_ learningBlock: LearningBlock) -> LearningBlockStyle? {
        
        var style: LearningBlockStyle?
        switch learningBlock.blockType {
        case .buttons:
            style = ButtonsLearningBlockStyle()
        case .code:
            style = CodeLearningBlockStyle()
        case .group:
            style = GroupLearningBlockStyle()
        case .image:
            style = ImageLearningBlockStyle()
        case .response:
            style = ResponseLearningBlockStyle()
        case .text:
            style = TextLearningBlockStyle()
        case .video:
            style = VideoLearningBlockStyle()
        default:
            style = DefaultLearningBlockStyle()
        }
        
        if var groupLevelMargins = style?.margins {
            let level = max(0, learningBlock.groupLevel - 1)
            groupLevelMargins.leading += CGFloat(level) * GroupLearningBlockStyle.groupLevelIndent
            style?.margins = groupLevelMargins
        }
        return style
    }

    open func textStyleForLearningBlock(_ learningBlock: LearningBlock) -> AttributedStringStyle? {
        
        var textStyle: AttributedStringStyle?
        switch learningBlock.blockType {
        case .code:
            textStyle = CodeAttributedStringStyle.shared
        case .group:
            textStyle = GroupAttributedStringStyle.shared
        case .response:
            textStyle = ResponseAttributedStringStyle.shared
        default:
            textStyle = TextWithCodeAttributedStringStyle.shared
        }
        return textStyle
    }
}
