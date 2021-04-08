//
//  CodeLearningBlockView.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit

class CodeLearningBlockView: UIView {
    public var learningBlock: LearningBlock?
    public var style: LearningBlockStyle?
    public var textStyle: AttributedStringStyle?
    
    public private(set) var isParticipatingInDragSession: Bool = false {
        didSet {
            let dragValue = NSNumber(integerLiteral: isParticipatingInDragSession ? 1 : -1)
            NotificationCenter.default.post(name: .dragInteractionStateChanged, object: dragValue, userInfo: nil)
        }
    }

    private var textView: UITextView
    private let copyButton = UIButton()
    private var buttonSize = CGSize(width: 30, height: 30)
    
    private let textStorage: NSTextStorage
    private let layoutManager: CodeLayoutManager
    private let textContainer: NSTextContainer
    
    private let backgroundBottomPadding: CGFloat = 5
    
    private var originalXML = ""
    
    lazy var copyableCode: String? = {
        guard let textStyle = textStyle else { return nil }
        // Convert the XML to an attributed string without preprocessing i.e. no substitutions necessary.
        var code = NSAttributedString(xml: originalXML, style: textStyle, preProcessXML: false).string
        // Always append a new line: makes dropping/pasting subsequent code easier.
        code += "\n"
        return code
    }()
    
    override init(frame: CGRect) {
        textContainer = NSTextContainer(size: frame.size)
        layoutManager = CodeLayoutManager()
        textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textView = UITextView(frame: frame, textContainer: textContainer)
        super.init(frame: frame)
        addSubview(textView)
        addSubview(copyButton)
        copyButton.setImage(UIImage(named: "copy-icon"), for: .normal)
        copyButton.accessibilityLabel = NSLocalizedString("Copy code", tableName: "SPCLearningTrails", comment: "AX label for copy code button")
        copyButton.accessibilityHint = NSLocalizedString("Copies the code in this snippet. You can then paste it into your own code.", tableName: "SPCLearningTrails", comment: "AX hint for copy code button")
        copyButton.alpha = 0.75
        copyButton.addTarget(self, action: #selector(didPressCopyButton), for: .touchUpInside)
        
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.dataDetectorTypes = .link
        textView.linkTextAttributes = [:]
        textView.delaysContentTouches = false
        textView.backgroundColor = .clear
        textView.adjustsFontForContentSizeCategory = true
        textView.accessibilityLabel = NSLocalizedString("Code snippet", tableName: "SPCLearningTrails", comment: "AX label for code in a code block")
        textView.accessibilityTraits = .staticText
                
        isAccessibilityElement = false // Accessibility container
        textView.isAccessibilityElement = true
        copyButton.isAccessibilityElement = true
        
        textView.addInteraction(UIDragInteraction(delegate: self))
        copyButton.addInteraction(UIDragInteraction(delegate: self))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var minimumHeight: CGFloat {
        return buttonSize.height + directionalLayoutMargins.top + directionalLayoutMargins.bottom
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let textViewWidth = size.width - directionalLayoutMargins.leading - directionalLayoutMargins.trailing
        let textViewSize = textView.sizeThatFits(CGSize(width: textViewWidth, height: CGFloat.greatestFiniteMagnitude))
        var fittingSize = CGSize(width: size.width, height: textViewSize.height + directionalLayoutMargins.top + directionalLayoutMargins.bottom)
        if fittingSize.height < minimumHeight {
            fittingSize.height = minimumHeight
        } else {
            // Allow a little space between the bottom of the text and the background.
            fittingSize.height += backgroundBottomPadding
        }
        return fittingSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var insets = UIEdgeInsets.zero
        insets.bottom = directionalLayoutMargins.bottom
        var rect = bounds.inset(by: insets)
        // At least tall enough for the button.
        rect.size.height = max(buttonSize.height, rect.size.height)
        textView.frame = rect
        copyButton.frame = CGRect(x: rect.maxX - buttonSize.width, y: rect.minY,
                                        width: buttonSize.width, height: buttonSize.height)
        
        let textViewSize = textView.sizeThatFits(CGSize(width: textView.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
        
        var textInsets = textView.textContainerInset
        // If the text height is less than the height of the button, push the text down to center it vertically.
        if textViewSize.height < buttonSize.height {
            let extraSpace = textView.bounds.size.height - textViewSize.height
            textInsets.top = max(0, extraSpace / 2.0)
        }
        textView.textContainerInset = textInsets
    }
    
    override public func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer is UILongPressGestureRecognizer {
            gestureRecognizer.isEnabled = false
        }
        if let tapGestureRecognizer = gestureRecognizer as? UITapGestureRecognizer {
            tapGestureRecognizer.numberOfTapsRequired = 1
        }
        super.addGestureRecognizer(gestureRecognizer)
    }
    
    //MARK: Actions

    @objc
    func didPressCopyButton(_ sender: UIButton) {
        if let code = copyableCode {
            UIPasteboard.general.string = code
        }
    }
}

extension CodeLearningBlockView: UIDragInteractionDelegate {
    
    func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: UIDragSession) {
        isParticipatingInDragSession = true
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, session: UIDragSession, didEndWith operation: UIDropOperation) {
        isParticipatingInDragSession = false
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        guard let code = copyableCode else { return [] }
        let stringItemProvider = NSItemProvider(object: code as NSString)
        let dragItem = UIDragItem(itemProvider: stringItemProvider)
        return [dragItem]
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, prefersFullSizePreviewsFor session: UIDragSession) -> Bool {
        return true
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
        guard let selectionRange = textView.textRange(from: textView.beginningOfDocument, to: textView.endOfDocument) else { return nil }
        let selectionRects = textView.selectionRects(for: selectionRange)
        
        var lineRects: [CGRect] = []
        
        let fullWidth = textView.frame.width - textView.textContainerInset.left - textView.textContainerInset.right
        
        for r in selectionRects {
            var rect = r.rect
            if rect.size.width > 0 {
                rect.size.width = fullWidth + 20
            }
            lineRects.append(rect)
        }
        
        let parameters = UIDragPreviewParameters(textLineRects: lineRects as [NSValue])
        let textViewCopy = UITextView(frame: textView.frame)
        var containerInsets = textView.textContainerInset
        containerInsets.top -= 4
        textViewCopy.textContainerInset = containerInsets
        textViewCopy.attributedText = textView.attributedText
        
        guard var windowPoint = textView.superview?.convert(textView.center, to: nil), let topWindow = self.window else { return nil }
        windowPoint.x -= 0.5
        windowPoint.y += 1.5
        
        let target = UIDragPreviewTarget(container: topWindow, center: windowPoint, transform: CGAffineTransform())
        let targetDragView = UITargetedDragPreview(view: textViewCopy, parameters: parameters, target: target)
        
        return targetDragView
    }
}

extension CodeLearningBlockView: LearningBlockViewable {
    func load(learningBlock: LearningBlock, style: LearningBlockStyle, textStyle: AttributedStringStyle? = CodeAttributedStringStyle.shared) {
        self.learningBlock = learningBlock
        self.style = style
        self.textStyle = textStyle
        
        textView.accessibilityIdentifier = learningBlock.accessibilityIdentifier
        copyButton.accessibilityIdentifier = "\(learningBlock.accessibilityIdentifier).copy"

        directionalLayoutMargins = style.margins
        
        var textInsets = layoutMargins
        // Bottom padding is outside of the text view.
        textInsets.bottom -= directionalLayoutMargins.bottom
        textInsets.right = buttonSize.width
        textView.textContainerInset = textInsets
        
        textView.backgroundColor = style.backgroundColor
        
        // Remove any indentation: auto-indentation should take care of it.
        originalXML = learningBlock.xmlPackagedContent(.linesLeftTrimmed)
        
        guard let textStyle = textStyle else { return }
        
        // Apply the text style.
        let attributedText = NSAttributedString(xml: originalXML, style: textStyle)
        
        // Auto-indent the code.
        let autoIndentedAttributedText = attributedText.autoCodeIndented(indentInset: CodeAttributedStringStyle.indentInset, wrapInset: CodeAttributedStringStyle.wrapInset)
        
        textStorage.setAttributedString(autoIndentedAttributedText)
        
        setNeedsLayout()
    }
}

class CodeLayoutManager: NSLayoutManager {
    
    // Custom implementation that draws placeholders.
    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<CGRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: UIColor) {
        
        guard rectCount > 0,
            let attributes = textStorage?.attributes(at: charRange.location, effectiveRange: nil),
            let paragraphStyle = attributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle
        else { return }
        
        let lineHeight = rectArray[0].size.height
        let cornerRadius: CGFloat = lineHeight * 0.15
        let hInset: CGFloat = lineHeight * -0.08 // Slightly wider.
        let vOffset: CGFloat = lineHeight * 0.12 // Vertically center the text.
        
        // Return rect adjusted relative to line height.
        func adjusted(_ rect: CGRect) -> CGRect {
            return rect.insetBy(dx: hInset, dy: 0.0).offsetBy(dx: 0.0, dy: vOffset)
        }
        
        let firstRect = adjusted(rectArray[0])
        var lastRect = adjusted(rectArray[rectCount - 1])
        // Wrapped lines should be indented.
        lastRect.origin.x += paragraphStyle.headIndent
        lastRect.size.width -= paragraphStyle.headIndent

        let path = CGMutablePath()
        
        if rectCount == 1 || (rectCount == 2 && (rectArray[1].maxX < rectArray[0].maxX)) {
            // First line.
            path.addRect(firstRect.insetBy(dx: cornerRadius, dy: cornerRadius))
            if rectCount == 2 {
                // Wrapped onto a second line.
                path.addRect(lastRect.insetBy(dx: cornerRadius, dy: cornerRadius))
            }
        } else {
            // Multiple lines => make a contiguous block.
            path.move(to: CGPoint(x: firstRect.minX + cornerRadius, y: firstRect.maxY + cornerRadius))
            path.addLine(to: CGPoint(x: firstRect.minX + cornerRadius, y: firstRect.minY + cornerRadius))
            path.addLine(to: CGPoint(x: firstRect.maxX - cornerRadius, y: firstRect.minY + cornerRadius))
            path.addLine(to: CGPoint(x: firstRect.maxX - cornerRadius, y: lastRect.minY - cornerRadius))
            path.addLine(to: CGPoint(x: lastRect.maxX - cornerRadius, y: lastRect.minY - cornerRadius))
            path.addLine(to: CGPoint(x: lastRect.maxX - cornerRadius, y: lastRect.maxY - cornerRadius))
            path.addLine(to: CGPoint(x: lastRect.minX + cornerRadius, y: lastRect.maxY - cornerRadius))
            path.addLine(to: CGPoint(x: lastRect.minX + cornerRadius, y: firstRect.maxY + cornerRadius))
            path.closeSubpath()
        }

        color.set()
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.setLineWidth(cornerRadius * 2.0)
        context.setLineJoin(.round)
        context.addPath(path)
        context.drawPath(using: .fillStroke)
    }

}
