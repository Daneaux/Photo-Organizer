import Foundation
import SwiftData

@Model
final class PlannedOperation {
    // MARK: - Identity

    var id: UUID

    // MARK: - Source and Destination

    var sourcePath: String
    var destinationPath: String
    var destinationEdited: Bool

    // MARK: - Duplicate Handling

    var isDuplicate: Bool
    var duplicateSuffix: String?
    var originalDestinationPath: String?

    // MARK: - Operation Details

    var statusRaw: String
    var status: OperationStatus {
        get { OperationStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
    var executedAt: Date?
    var errorMessage: String?

    // MARK: - Relationships

    var mediaFile: MediaFile?

    @Relationship(inverse: \OrganizeSession.operations)
    var session: OrganizeSession?

    // MARK: - Initialization

    init(sourcePath: String, destinationPath: String) {
        self.id = UUID()
        self.sourcePath = sourcePath
        self.destinationPath = destinationPath
        self.destinationEdited = false
        self.isDuplicate = false
        self.statusRaw = OperationStatus.pending.rawValue
    }

    // MARK: - Computed Properties

    var sourceFilename: String {
        URL(fileURLWithPath: sourcePath).lastPathComponent
    }

    var destinationFilename: String {
        URL(fileURLWithPath: destinationPath).lastPathComponent
    }

    var destinationDirectory: String {
        URL(fileURLWithPath: destinationPath).deletingLastPathComponent().path
    }
}
