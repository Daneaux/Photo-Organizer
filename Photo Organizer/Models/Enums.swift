import Foundation

// MARK: - Media Type

enum MediaType: String, Codable, CaseIterable {
    case image
    case video

    var displayName: String {
        switch self {
        case .image: return "Image"
        case .video: return "Video"
        }
    }
}

// MARK: - Date Source

enum DateSource: String, Codable, CaseIterable {
    case exifDateTimeOriginal
    case exifCreateDate
    case exifDateTimeDigitized
    case videoCreationDate
    case directoryName
    case userInput
    case fileModificationDate
    case none

    var displayName: String {
        switch self {
        case .exifDateTimeOriginal: return "EXIF (DateTimeOriginal)"
        case .exifCreateDate: return "EXIF (CreateDate)"
        case .exifDateTimeDigitized: return "EXIF (DateTimeDigitized)"
        case .videoCreationDate: return "Video Metadata"
        case .directoryName: return "Directory Name"
        case .userInput: return "User Input"
        case .fileModificationDate: return "File Modified Date"
        case .none: return "Unknown"
        }
    }

    var confidence: DateConfidence {
        switch self {
        case .exifDateTimeOriginal, .exifCreateDate, .exifDateTimeDigitized, .videoCreationDate:
            return .high
        case .directoryName, .userInput:
            return .medium
        case .fileModificationDate:
            return .low
        case .none:
            return .none
        }
    }
}

enum DateConfidence: String, Codable {
    case high
    case medium
    case low
    case none
}

// MARK: - Processing Status

enum ProcessingStatus: String, Codable, CaseIterable {
    case pending
    case planned
    case completed
    case failed
    case skipped

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .planned: return "Planned"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .skipped: return "Skipped"
        }
    }
}

// MARK: - Operation Status

enum OperationStatus: String, Codable, CaseIterable {
    case pending
    case inProgress
    case completed
    case failed
    case cancelled
    case undone

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .undone: return "Undone"
        }
    }
}

// MARK: - Session State

enum SessionState: String, Codable, CaseIterable {
    case setup
    case scanning
    case reviewing
    case executing
    case paused
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .setup: return "Setup"
        case .scanning: return "Scanning"
        case .reviewing: return "Reviewing"
        case .executing: return "Executing"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}
