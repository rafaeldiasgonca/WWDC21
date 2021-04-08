//
//  String+extensions.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation

extension String {
    func lowercasedFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }
    
    func trimmingWhitespaceAndNewlines() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func trimmingTrailingWhitespaceAndNewlines() -> String {
        let trimmed = ("|" + self).trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed[trimmed.index(after: trimmed.startIndex)...])
    }
    
    func trimmingLeadingNewlines() -> String {
        let trimmed = self + "|"
        return String(trimmed.trimmingCharacters(in: .newlines).dropLast())
    }
    
    func removingCharacters(in characterSet: CharacterSet) -> String {
        let filtered = unicodeScalars.lazy.filter { !characterSet.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }
    
    // Returns the string with leading and trailing whitespace trimmed and
    // each line trimmed of any leading whitespace.
    func linesLeftTrimmed() -> String {
        let lines = self.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\n", omittingEmptySubsequences: false)
        let trimmedLines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
        return trimmedLines.joined(separator: "\n")
    }
    
    // Returns all the substrings in the string that match regular expression pattern.
    func substringsMatching(pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let string = self as NSString
        return regex.matches(in: self, options: [], range: NSRange(location: 0, length: string.length)).map {
            string.substring(with: $0.range)
        }
    }
}
