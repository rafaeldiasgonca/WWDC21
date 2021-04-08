//
//  AttributedStringStyler.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import PlaygroundSupport
import SPCCore

public protocol AttributedStringStyle {
    static var shared: AttributedStringStyle { get }
    var fontSize: CGFloat { get set }
    var tintColor: UIColor { get set }
    var attributes: [String : [NSAttributedString.Key: Any]] { get }
}

public class AttributedStringStyler {
    private var elementStyleAttributes: [String : [NSAttributedString.Key: Any]] = [:]
    private var styleAttributesStack: [[NSAttributedString.Key: Any]] = []
    
    private var currentStyleAttributes: [NSAttributedString.Key: Any] = [:]
    
    let attributedString = NSMutableAttributedString()
    
    private var taskPrefix: String {
        return "➤ "
    }
    
    // Maps the icon name to the unicode character in the icon font e.g. <icon name="main">.
    private let iconCharacterMap: [String : String] = [
        "main" : "\u{e900}",
        "module" : "\u{e901}"
    ]

    /// Creates an instance of the string styler from a chunk of well-formed XML, and applies the specified style attributes to each element.
    ///
    /// - Parameter xml: The xml to be styled.
    /// - Parameter styleAttributes: A dictionary of styles keyed on element name.
    ///
    public init(xml: String, style: AttributedStringStyle) {
        elementStyleAttributes = style.attributes
        let parser = SlimXMLParser(xml: xml)
        parser.delegate = self
        parser.parse()
    }
    
    // Merges all the style attributes in the stack working up from the bottom.
    // The result (currentStyleAttributes) is the style to be applied to any text.
    func updateCurrentStyleAttributes() {
        currentStyleAttributes = [:]
        for attributes in styleAttributesStack {
            currentStyleAttributes = currentStyleAttributes.merging(attributes, uniquingKeysWith: { (_, new) in new })
        }
    }
    
}

extension AttributedStringStyler: SlimXMLParserDelegate {
    
    func parser(_ parser: SlimXMLParser, didStartElement  element: SlimXMLElement) {
        
        if var styleAttributes = elementStyleAttributes[element.name] {
            // Attach link attributes.
            if let linkAttribute = styleAttributes[TextAttributedStringStyle.Key.linkAttribute] as? String, let href = element.attributes[linkAttribute] {
                styleAttributes[.link] = href
            }
            if let colorAttribute = element.attributes["color"] {
                let color = UIColor(delimitedList: colorAttribute)
                styleAttributes[.foregroundColor] = color
            }
            styleAttributesStack.append(styleAttributes)
            updateCurrentStyleAttributes()
        }
    }
    
    func parser(_ parser: SlimXMLParser, didEndElement  element: SlimXMLElement) {

        if element.name == "br" {
            // Insert a line break.
            var currentAttributes = currentStyleAttributes
            // Remove the custom attribute that identifies a line of code so as to preserve the boundaries between lines of code used by auto-indentation.
            currentAttributes.removeValue(forKey: CodeAttributedStringStyle.CodeAttribute)
            attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
        } else if element.name == "p" {
            // Insert a paragraph break.
            attributedString.append(NSAttributedString(string: "\n\r", attributes: currentStyleAttributes))
        } else if element.name == "task" {
            let taskAttributes = elementStyleAttributes["task"] ?? currentStyleAttributes
            attributedString.append(NSAttributedString(string: taskPrefix, attributes: taskAttributes))
        } else if element.name == "icon" {
            if let iconName = element.attributes["name"], let characterString = iconCharacterMap[iconName] {
                let iconAttributes = elementStyleAttributes["icon"] ?? currentStyleAttributes
                attributedString.append(NSAttributedString(string: characterString, attributes: iconAttributes))
            }
        }
        
        // Only pop style if it was pushed onto the stack in didStartElement.
        if let _ = elementStyleAttributes[element.name] {
            _ = styleAttributesStack.popLast()
            updateCurrentStyleAttributes()
        }
    }
    
    func parser(_ parser: SlimXMLParser, foundCharacters string: String) {
        attributedString.append(NSAttributedString(string: string, attributes: currentStyleAttributes))
    }
    
    func parser(_ parser: SlimXMLParser, shouldCaptureElementContent elementName: String, attributes: [String : String]) -> Bool {
        return false
    }
    
    func parser(_ parser: SlimXMLParser, shouldLocalizeElementWithID elementName: String) -> Bool {
        return false
    }
    
    func parser(_ parser: SlimXMLParser, parseErrorOccurred parseError: Error, lineNumber: Int) {
        NSLog("\(parseError.localizedDescription) at line: \(lineNumber)")
    }
}

private extension String {
    
    // Substitutes color and image literals with a form that can be rendered.
    //
    // <literal>#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)</literal>
    // =>
    // <literal color="0.4745098054, 0.8392156959, 0.9764705896, 1")>■</literal>
    //
    // backgroundImage = <literal>#imageLiteral(resourceName: "SwitchCameraButton")</literal>
    // =>
    // backgroundImage = <literal image="SwitchCameraButton">🏞</literal>
    //
    func substitutingLiterals() -> String {
        guard let regex = try? NSRegularExpression(pattern: "(<literal>.*?</literal>)") else { return self }
        
        var substitutedString = self
        let range = NSRange(location: 0, length: self.utf16.count)
        for match in regex.matches(in: self, options: [], range: range) {
            let matchedString = (self as NSString).substring(with: match.range(at: 1))
            
            if matchedString.contains("#colorLiteral") {
                var colorString = matchedString.removingCharacters(in: CharacterSet(charactersIn: "01234567890.,").inverted)
                colorString = colorString.replacingOccurrences(of: ",", with: ", ")
                let replacementString = "<literal color=\"\(colorString)\">■</literal>"
                substitutedString = substitutedString.replacingOccurrences(of: matchedString, with: replacementString)
                
            } else if matchedString.contains("#imageLiteral") {
                if let resourceNameRegex = try? NSRegularExpression(pattern: "\"([^\"]*)\"") {
                    let matchedStringRange = NSRange(location: 0, length: matchedString.utf16.count)
                    if let resourceNameMatch = resourceNameRegex.firstMatch(in: matchedString, options: [], range: matchedStringRange) {
                        let resourceName = (matchedString as NSString).substring(with: resourceNameMatch.range(at: 1))
                        let replacementString = "<literal image=\"\(resourceName)\">🏞</literal>"
                        substitutedString = substitutedString.replacingOccurrences(of: matchedString, with: replacementString)
                    }
                }
            }
        }
        
        return substitutedString
    }
    
    // Translate placeholders such as:
    // < #button# >
    // =>
    // <placeholder>button</placeholder>
    func substitutingPlaceholders() ->String {
        var substitutedString = self
        if let regex = try? NSRegularExpression(pattern: "&lt;#([^#]*)#&gt;") {
            let range = NSRange(location: 0, length: self.utf16.count)
            for match in regex.matches(in: self, options: [], range: range) {
                let matchedString = (self as NSString).substring(with: match.range(at: 0))
                let matchedSymbol = (self as NSString).substring(with: match.range(at: 1))
                let replacementString = "<placeholder>\(matchedSymbol)</placeholder>"
                substitutedString = substitutedString.replacingOccurrences(of: matchedString, with: replacementString)
            }
        }
        return substitutedString
    }
    
    // Returns string with contents of any <code> elements preprocessed prior to styling.
    func codePreprocessed() -> String {
        guard let regex = try? NSRegularExpression(pattern: "<code[^>]*>(.*?)</code>", options: [.dotMatchesLineSeparators]) else { return "" }
        let range = NSRange(location: 0, length: self.utf16.count)
        
        var currentLocation = 0
        var processed = ""
        for match in regex.matches(in: self, options: [], range: range) {
            guard match.numberOfRanges > 1 else { continue }
            let matchRange = match.range(at: 0)
            let prefix = (self as NSString).substring(with: NSRange(location: currentLocation, length: (matchRange.location - currentLocation)))
            let code = (self as NSString).substring(with: matchRange)
            currentLocation = matchRange.location + matchRange.length
            
            // Substitute literals.
            var substitutedCode = code.substitutingLiterals()
            // Substitute placeholders.
            substitutedCode = substitutedCode.substitutingPlaceholders()
            
            // Force each line to have its own paragraph style (for auto-indentation).
            substitutedCode = substitutedCode.replacingOccurrences(of: "\n", with: "<br/>")
            
            processed += prefix
            processed += substitutedCode
        }
        let remainder = (self as NSString).substring(with: NSRange(location: currentLocation, length: (range.length - currentLocation)))
        processed += remainder
        return processed
    }
}

extension NSAttributedString {
    
    // Generates an attributed string by applying style to a chunk of well-formed XML.
    public convenience init(xml: String, style: AttributedStringStyle, preProcessXML: Bool = true) {
        var processedXML = xml
        
        let containsCode = xml.contains("<code") && xml.contains("</code>")
        
        // Pre-process the XML.
        if preProcessXML {
            // If the xml contains a <code> element, preprocess it.
            if containsCode {
                processedXML = processedXML.codePreprocessed()
            }
        }
        
        // Style the xml to an attributed string.
        let attributedText = AttributedStringStyler(xml: processedXML, style: style).attributedString
        
        // Post-process the attributed string.
        if containsCode {
            // Auto-indent the code.
            let autoIndentedAttributedText = attributedText.autoCodeIndented(indentInset: CodeAttributedStringStyle.indentInset, wrapInset: CodeAttributedStringStyle.wrapInset)
            self.init(attributedString: autoIndentedAttributedText)
        } else {
            self.init(attributedString: attributedText)
        }
    }
    
    // Auto indents code based on braces ({ and [).
    // - parameter indentInset: The inset to be applied per indentation level.
    // - parameter wrapInset: The additional inset for wrapped lines.
    func autoCodeIndented(indentInset: CGFloat, wrapInset: CGFloat) -> NSAttributedString {
        
        func paragraphStyleFor(indentLevel: Int, from paragraphStyle: NSParagraphStyle) -> NSParagraphStyle {
            let newParagraphStyle = NSMutableParagraphStyle()
            newParagraphStyle.setParagraphStyle(paragraphStyle)
            let indent = indentInset * CGFloat(indentLevel)
            newParagraphStyle.firstLineHeadIndent = indent
            newParagraphStyle.headIndent = indent + wrapInset
            return newParagraphStyle
        }
        
        guard let attrText = self.mutableCopy() as? NSMutableAttributedString else {
            return self
        }
        
        let openingBraces = "[{"
        let closingBraces = "]}"
        let bracesCharacterSet = CharacterSet(charactersIn: closingBraces + openingBraces)

        var indentLevel = 0
        attrText.beginEditing()
        attrText.enumerateAttribute(NSAttributedString.Key.paragraphStyle,
                                    in: NSRange(location: 0, length: self.length),
                                    options: [.longestEffectiveRangeNotRequired]) { (value, range, stop) -> Void in
                                        
                                        guard let ps = value as? NSParagraphStyle else { return }
                                        
                                        // Look for attribute that identifies a code paragraph and skip if not found.
                                        guard attrText.attribute(CodeAttributedStringStyle.CodeAttribute, at: range.location, effectiveRange: nil) != nil else {
                                            return
                                        }
                                        
                                        let line = attrText.attributedSubstring(from: range).string
                                        
                                        var firstBraceOnTheLine = ""
                                        if let firstBraceRange = line.rangeOfCharacter(from: bracesCharacterSet) {
                                            firstBraceOnTheLine = String(line[firstBraceRange.lowerBound])
                                        }
                                        
                                        let openBraces = line.filter { openingBraces.contains($0) }
                                        let closeBraces = line.filter { closingBraces.contains($0) }

                                        if closeBraces.count > openBraces.count {
                                            // Moving up an indentation level => apply immediately to this line.
                                            indentLevel += (openBraces.count - closeBraces.count)
                                        } else if closeBraces.count == openBraces.count, closeBraces.count > 0 {
                                            // Closing then opening on the same line => decrement indentation immediately for this line.
                                            if closingBraces.contains(firstBraceOnTheLine) {
                                                indentLevel -= closeBraces.count
                                            }
                                        }
                                                                                
                                        // Apply indentation for current level.
                                        let updatedParagraphStyle = paragraphStyleFor(indentLevel: indentLevel, from: ps)
                                        attrText.removeAttribute(NSAttributedString.Key.paragraphStyle, range: range)
                                        attrText.addAttribute(NSAttributedString.Key.paragraphStyle, value: updatedParagraphStyle, range: range)
                                        
                                        if openBraces.count > closeBraces.count {
                                            // Moving down an indentation level => apply later to next line.
                                            indentLevel += (openBraces.count - closeBraces.count)
                                        } else if closeBraces.count == openBraces.count, closeBraces.count > 0 {
                                            // Closing then opening on the same line => increment indentation for next line.
                                            if closingBraces.contains(firstBraceOnTheLine) {
                                                indentLevel += closeBraces.count
                                            }
                                        }
        }
        attrText.endEditing()
        
        return attrText
    }
    
}


