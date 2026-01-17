import Foundation

nonisolated(unsafe) struct DateFormatters: Sendable {
    // MARK: - EXIF Date Parsing

    /// EXIF date format: "YYYY:MM:DD HH:MM:SS"
    static let exifFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// Alternative EXIF format without time
    static let exifDateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    // MARK: - Display Formatters

    /// Display format for dates: "Jan 15, 2024"
    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Display format with time: "Jan 15, 2024 at 3:30 PM"
    static let displayWithTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Folder name format: "MM-DD"
    static let folderDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter
    }()

    /// Year format: "YYYY"
    static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    // MARK: - Script/Log Formatters

    /// ISO 8601 format for scripts and logs
    static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Timestamp for filenames: "20240115_153045"
    static let filenameTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()

    // MARK: - Parse Methods

    static func parseExifDate(_ string: String) -> Date? {
        if let date = exifFormatter.date(from: string) {
            return date
        }
        if let date = exifDateOnlyFormatter.date(from: string) {
            return date
        }
        return nil
    }

    // MARK: - Format Methods

    static func displayString(for date: Date) -> String {
        displayFormatter.string(from: date)
    }

    static func displayStringWithTime(for date: Date) -> String {
        displayWithTimeFormatter.string(from: date)
    }

    static func folderDayString(for date: Date) -> String {
        folderDayFormatter.string(from: date)
    }

    static func yearString(for date: Date) -> String {
        yearFormatter.string(from: date)
    }

    static func isoString(for date: Date) -> String {
        isoFormatter.string(from: date)
    }

    static func filenameTimestamp(for date: Date = Date()) -> String {
        filenameTimestampFormatter.string(from: date)
    }
}
