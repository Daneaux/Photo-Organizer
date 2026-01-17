import Foundation

struct EventDescriptionParser {
    // MARK: - Date Patterns to Remove

    private static let datePatterns: [String] = [
        "\\d{4}-\\d{2}-\\d{2}",   // YYYY-MM-DD
        "\\d{4}-\\d{2}",          // YYYY-MM
        "\\d{8}",                  // YYYYMMDD
        "\\d{2}-\\d{2}-\\d{4}",   // MM-DD-YYYY
        "\\d{2}/\\d{2}/\\d{4}",   // MM/DD/YYYY
        "\\d{2}\\.\\d{2}\\.\\d{4}" // MM.DD.YYYY
    ]

    // MARK: - Extraction

    /// Extracts an event description from a directory name by removing date patterns
    func extractEventDescription(from directoryName: String) -> String? {
        var remaining = directoryName

        // Remove all date patterns
        for pattern in Self.datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(remaining.startIndex..., in: remaining)
                remaining = regex.stringByReplacingMatches(
                    in: remaining,
                    options: [],
                    range: range,
                    withTemplate: ""
                )
            }
        }

        // Clean up the result
        remaining = cleanupDescription(remaining)

        return remaining.isEmpty ? nil : remaining
    }

    /// Cleans up an event description by removing extra separators and whitespace
    private func cleanupDescription(_ string: String) -> String {
        var result = string

        // Replace common separators with space
        result = result.replacingOccurrences(of: "_", with: " ")

        // Remove leading/trailing separators and whitespace
        let trimCharacters = CharacterSet(charactersIn: " -_.")
        result = result.trimmingCharacters(in: trimCharacters)

        // Collapse multiple spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }

        // Remove leading dash if present
        if result.hasPrefix("- ") {
            result = String(result.dropFirst(2))
        }
        if result.hasPrefix("-") {
            result = String(result.dropFirst())
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Batch Analysis

    /// Analyzes multiple directory names and suggests common event descriptions
    func suggestEventDescriptions(from directoryNames: [String]) -> [String: String] {
        var suggestions: [String: String] = [:]

        for dirName in directoryNames {
            if let description = extractEventDescription(from: dirName) {
                suggestions[dirName] = description
            }
        }

        return suggestions
    }

    /// Groups directories by their extracted event descriptions
    func groupByEventDescription(_ directoryNames: [String]) -> [String?: [String]] {
        var groups: [String?: [String]] = [:]

        for dirName in directoryNames {
            let description = extractEventDescription(from: dirName)
            if groups[description] == nil {
                groups[description] = []
            }
            groups[description]?.append(dirName)
        }

        return groups
    }
}
