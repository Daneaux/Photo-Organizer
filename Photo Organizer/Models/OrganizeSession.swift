import Foundation
import SwiftData

@Model
final class OrganizeSession {
    // MARK: - Identity

    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Configuration

    var sourceDirectoryPath: String
    var sourceBookmarkData: Data?
    var destinationDirectoryPath: String
    var destinationBookmarkData: Data?

    // MARK: - Session State

    var sessionStateRaw: String
    var sessionState: SessionState {
        get { SessionState(rawValue: sessionStateRaw) ?? .setup }
        set { sessionStateRaw = newValue.rawValue }
    }

    // MARK: - Statistics

    var totalFilesScanned: Int
    var totalFilesPlanned: Int
    var totalFilesCompleted: Int
    var totalFilesFailed: Int
    var totalFilesSkipped: Int

    // MARK: - Generated Scripts

    var forwardScriptPath: String?
    var undoScriptPath: String?
    var logsDirectoryPath: String?

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade)
    var mediaFiles: [MediaFile] = []

    @Relationship(deleteRule: .cascade)
    var operations: [PlannedOperation] = []

    // MARK: - Initialization

    init(name: String, sourcePath: String, destinationPath: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sourceDirectoryPath = sourcePath
        self.destinationDirectoryPath = destinationPath
        self.sessionStateRaw = SessionState.setup.rawValue
        self.totalFilesScanned = 0
        self.totalFilesPlanned = 0
        self.totalFilesCompleted = 0
        self.totalFilesFailed = 0
        self.totalFilesSkipped = 0
    }

    // MARK: - Computed Properties

    var sourceDirectoryName: String {
        URL(fileURLWithPath: sourceDirectoryPath).lastPathComponent
    }

    var destinationDirectoryName: String {
        URL(fileURLWithPath: destinationDirectoryPath).lastPathComponent
    }

    var progress: Double {
        guard totalFilesPlanned > 0 else { return 0 }
        return Double(totalFilesCompleted + totalFilesFailed) / Double(totalFilesPlanned)
    }

    var isComplete: Bool {
        sessionState == .completed
    }

    var canResume: Bool {
        sessionState == .paused || sessionState == .reviewing
    }

    // MARK: - Methods

    func updateTimestamp() {
        updatedAt = Date()
    }

    func incrementCompleted() {
        totalFilesCompleted += 1
        updateTimestamp()
    }

    func incrementFailed() {
        totalFilesFailed += 1
        updateTimestamp()
    }

    func incrementSkipped() {
        totalFilesSkipped += 1
        updateTimestamp()
    }
}
