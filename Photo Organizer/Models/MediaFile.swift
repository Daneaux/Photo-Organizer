import Foundation
import SwiftData

@Model
final class MediaFile {
    // MARK: - Identity

    var id: UUID
    var originalPath: String
    var filename: String
    var fileExtension: String

    // MARK: - Classification

    var mediaTypeRaw: String
    var mediaType: MediaType {
        get { MediaType(rawValue: mediaTypeRaw) ?? .image }
        set { mediaTypeRaw = newValue.rawValue }
    }
    var fileSizeBytes: Int64

    // MARK: - Date Information

    var detectedDate: Date?
    var dateSourceRaw: String
    var dateSource: DateSource {
        get { DateSource(rawValue: dateSourceRaw) ?? .none }
        set { dateSourceRaw = newValue.rawValue }
    }
    var dateConfirmed: Bool

    // MARK: - Event Information

    var eventDescription: String?
    var eventConfirmed: Bool
    var sourceDirectoryName: String
    var sourceDirectoryPath: String

    // MARK: - Processing State

    var processingStatusRaw: String
    var processingStatus: ProcessingStatus {
        get { ProcessingStatus(rawValue: processingStatusRaw) ?? .pending }
        set { processingStatusRaw = newValue.rawValue }
    }
    var errorMessage: String?

    // MARK: - Relationships

    @Relationship(inverse: \PlannedOperation.mediaFile)
    var plannedOperation: PlannedOperation?

    @Relationship(inverse: \OrganizeSession.mediaFiles)
    var session: OrganizeSession?

    // MARK: - Initialization

    init(
        originalPath: String,
        filename: String,
        fileExtension: String,
        mediaType: MediaType,
        sourceDirectoryName: String,
        sourceDirectoryPath: String
    ) {
        self.id = UUID()
        self.originalPath = originalPath
        self.filename = filename
        self.fileExtension = fileExtension
        self.mediaTypeRaw = mediaType.rawValue
        self.fileSizeBytes = 0
        self.dateSourceRaw = DateSource.none.rawValue
        self.dateConfirmed = false
        self.eventConfirmed = false
        self.sourceDirectoryName = sourceDirectoryName
        self.sourceDirectoryPath = sourceDirectoryPath
        self.processingStatusRaw = ProcessingStatus.pending.rawValue
    }

    // MARK: - Computed Properties

    var hasValidDate: Bool {
        detectedDate != nil
    }

    var dateConfidenceLevel: DateConfidence {
        dateSource.confidence
    }

    var displayDateSource: String {
        dateSource.displayName
    }
}
