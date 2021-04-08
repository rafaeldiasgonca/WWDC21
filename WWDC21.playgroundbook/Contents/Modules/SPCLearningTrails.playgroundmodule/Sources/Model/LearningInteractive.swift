//
//  LearningInteractive.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import SPCCore

public class LearningInteractive {
    
    enum Kind: String {
        case buttons, hotspots
    }
    
    enum Action: String {
        case link, popupText
    }
    
    enum Direction: String {
        case up, down, left, right
    }
    
    public class Hotspot {
        var position = CGPoint.zero
        var action: Action?
        var direction: Direction?
        var xmlText: String?
        
        init?(xml: String, attributes: [String : String]) {
            guard let posComponents = attributes["position"]?.components(separatedBy: ","), posComponents.count > 1 else { return nil }
            position.x = CGFloat(Float(posComponents[0].trimmingCharacters(in: .whitespaces)) ?? 0)
            position.y = CGFloat(Float(posComponents[1].trimmingCharacters(in: .whitespaces)) ?? 0)
            
            if let actionAttribute = attributes["action"] {
                action = Action(rawValue: actionAttribute)
            }
            
            if let caratDirectionAttribute = attributes["carat"] {
                direction = Direction(rawValue: caratDirectionAttribute)
            }
            
            let parser = SlimXMLParser(xml: xml)
            parser.delegate = self
            parser.parse()
        }
    }
    
    public class Button {
        var action: Action?
        var url: URL?
        var xmlText: String?
        var imageName: String?
        
        init?(xml: String, attributes: [String : String]) {
            if let actionAttribute = attributes["action"] {
                action = Action(rawValue: actionAttribute)
            }
            
            if let href = attributes["href"] {
                url = URL(string: href)
            }
            
            let parser = SlimXMLParser(xml: xml)
            parser.delegate = self
            parser.parse()
        }
    }
    
    var name: String?
    var kind: Kind = .hotspots
    var hotspots = [Hotspot]()
    var buttons = [Button]()
    var isValid = false
    
    var itemData: [(String, [String : String])] = []

    init?(xml: String, attributes: [String : String] = [:]) {
        name = attributes["name"]
        
        let parser = SlimXMLParser(xml: xml)
        parser.delegate = self
        parser.parse()
        parseItems()
        
        if isValid {
            var suffix = ""
            switch kind {
            case .buttons:
                suffix = "with \(buttons.count) buttons"
            case .hotspots:
                suffix = "with \(hotspots.count) hotspots"
            }
            PBLog("LearningInteractive [\(name ?? "")] loaded \(suffix).")
        } else {
            return nil
        }
    }
    
    private func parseItems() {
        itemData.forEach( {
            switch kind {
            case .hotspots:
                if let hotspot = Hotspot(xml: $0, attributes: $1) {
                    hotspots.append(hotspot)
                }
            case .buttons:
                if let button = Button(xml: $0, attributes: $1) {
                    buttons.append(button)
                }
            }
        })
    }
}

extension LearningInteractive: SlimXMLParserDelegate {
    
    func parser(_ parser: SlimXMLParser, didStartElement element: SlimXMLElement) {
        switch element.name {
        case "interactive":
            isValid = true
        default: break
        }
    }
    
    func parser(_ parser: SlimXMLParser, didEndElement element: SlimXMLElement) {
        switch element.name {
        case "button":
            guard let xmlContent = element.xmlContent else { break }
            if itemData.isEmpty { kind = .buttons }
            itemData.append((xmlContent, element.attributes))
        case "hotspot":
            guard let xmlContent = element.xmlContent else { break }
            if itemData.isEmpty { kind = .hotspots }
            itemData.append((xmlContent, element.attributes))
        default: break
        }
    }
    
    func parser(_ parser: SlimXMLParser, foundCharacters string: String) {
    }
    
    func parser(_ parser: SlimXMLParser, shouldCaptureElementContent elementName: String, attributes: [String : String]) -> Bool {
        switch elementName {
        case "button", "hotspot":
            return true
        default:
            return false
        }
    }
    
    func parser(_ parser: SlimXMLParser, shouldLocalizeElementWithID elementName: String) -> Bool {
        return false
    }
    
    func parser(_ parser: SlimXMLParser, parseErrorOccurred parseError: Error, lineNumber: Int) {
        NSLog("\(parseError.localizedDescription) at line: \(lineNumber)")
    }
}

extension LearningInteractive.Hotspot: SlimXMLParserDelegate {
    
    func parser(_ parser: SlimXMLParser, didStartElement element: SlimXMLElement) {
    }
    
    func parser(_ parser: SlimXMLParser, didEndElement element: SlimXMLElement) {
        switch element.name {
        case "text":
            guard let xmlContent = element.xmlContent else { break }
            self.xmlText = xmlContent
        default:
            break
        }
    }
    
    func parser(_ parser: SlimXMLParser, foundCharacters string: String) {
    }
    
    func parser(_ parser: SlimXMLParser, shouldCaptureElementContent elementName: String, attributes: [String : String]) -> Bool {
        switch elementName {
        case "text":
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

extension LearningInteractive.Button: SlimXMLParserDelegate {
    
    func parser(_ parser: SlimXMLParser, didStartElement element: SlimXMLElement) {
    }
    
    func parser(_ parser: SlimXMLParser, didEndElement element: SlimXMLElement) {
        switch element.name {
        case "image":
            self.imageName = element.content
        case "text":
            guard let xmlContent = element.xmlContent else { break }
            self.xmlText = xmlContent
        default:
            break
        }
    }
    
    func parser(_ parser: SlimXMLParser, foundCharacters string: String) {
    }
    
    func parser(_ parser: SlimXMLParser, shouldCaptureElementContent elementName: String, attributes: [String : String]) -> Bool {
        switch elementName {
        case "text":
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


