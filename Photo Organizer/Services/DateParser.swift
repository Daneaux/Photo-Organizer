import Foundation

struct DateParser {
    // MARK: - Parsed Date

    struct ParsedDate {
        let date: Date
        let format: DateParseFormat
        let hasDay: Bool
        let matchedString: String
    }

    enum DateParseFormat: String {
        case isoDate        // YYYY-MM-DD
        case yearMonth      // YYYY-MM
        case compactDate    // YYYYMMDD
        case usDate         // MM-DD-YYYY
        case usDateSlash    // MM/DD/YYYY
        case usDateDot      // MM.DD.YYYY
    }

    // MARK: - Regex Patterns

    private static let patterns: [(pattern: String, format: DateParseFormat, hasDay: Bool)] = [
        // YYYY-MM-DD (ISO format) - highest priority
        ("(\\d{4})-(\\d{2})-(\\d{2})", .isoDate, true),

        // YYYYMMDD (compact) - before YYYY-MM to avoid partial match
        ("(\\d{4})(\\d{2})(\\d{2})(?!\\d)", .compactDate, true),

        // YYYY-MM (Year-Month only)
        ("(\\d{4})-(\\d{2})(?!-\\d)", .yearMonth, false),

        // MM-DD-YYYY (US format with dashes)
        ("(\\d{2})-(\\d{2})-(\\d{4})", .usDate, true),

        // MM/DD/YYYY (US format with slashes)
        ("(\\d{2})/(\\d{2})/(\\d{4})", .usDateSlash, true),

        // MM.DD.YYYY (US format with dots)
        ("(\\d{2})\\.(\\d{2})\\.(\\d{4})", .usDateDot, true),
    ]

    // MARK: - Parsing

    /// Parses a date from a directory name
    func parseDate(from directoryName: String) -> ParsedDate? {
        for (pattern, format, hasDay) in Self.patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                continue
            }

            let range = NSRange(directoryName.startIndex..., in: directoryName)
            guard let match = regex.firstMatch(in: directoryName, options: [], range: range) else {
                continue
            }

            // Extract matched string
            guard let matchRange = Range(match.range, in: directoryName) else {
                continue
            }
            let matchedString = String(directoryName[matchRange])

            // Extract date components based on format
            let date: Date?

            switch format {
            case .isoDate, .compactDate:
                // Year-Month-Day order
                let year = extractGroup(match, group: 1, from: directoryName)
                let month = extractGroup(match, group: 2, from: directoryName)
                let day = extractGroup(match, group: 3, from: directoryName)
                date = createDate(year: year, month: month, day: day)

            case .yearMonth:
                // Year-Month only
                let year = extractGroup(match, group: 1, from: directoryName)
                let month = extractGroup(match, group: 2, from: directoryName)
                date = createDate(year: year, month: month, day: "01")

            case .usDate, .usDateSlash, .usDateDot:
                // Month-Day-Year order
                let month = extractGroup(match, group: 1, from: directoryName)
                let day = extractGroup(match, group: 2, from: directoryName)
                let year = extractGroup(match, group: 3, from: directoryName)
                date = createDate(year: year, month: month, day: day)
            }

            if let validDate = date {
                return ParsedDate(
                    date: validDate,
                    format: format,
                    hasDay: hasDay,
                    matchedString: matchedString
                )
            }
        }

        return nil
    }

    // MARK: - Helper Methods

    private func extractGroup(_ match: NSTextCheckingResult, group: Int, from string: String) -> String? {
        guard group < match.numberOfRanges,
              let range = Range(match.range(at: group), in: string) else {
            return nil
        }
        return String(string[range])
    }

    private func createDate(year: String?, month: String?, day: String?) -> Date? {
        guard let yearStr = year, let monthStr = month, let dayStr = day,
              let yearInt = Int(yearStr),
              let monthInt = Int(monthStr),
              let dayInt = Int(dayStr) else {
            return nil
        }

        // Validate ranges
        guard yearInt >= 1900 && yearInt <= 2100,
              monthInt >= 1 && monthInt <= 12,
              dayInt >= 1 && dayInt <= 31 else {
            return nil
        }

        var components = DateComponents()
        components.year = yearInt
        components.month = monthInt
        components.day = dayInt
        components.hour = 12 // Noon to avoid timezone issues

        return Calendar.current.date(from: components)
    }
}
