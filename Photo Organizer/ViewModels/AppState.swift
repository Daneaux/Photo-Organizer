import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class AppState {
    // MARK: - UserDefaults Keys

    private enum UserDefaultsKeys {
        static let destinationBookmark = "lastDestinationBookmark"
    }

    // MARK: - Directory Selection

    var sourceDirectory: URL?
    var sourceBookmark: Data?
    var destinationDirectory: URL?
    var destinationBookmark: Data?

    // MARK: - Initialization

    init() {
        // Restore last destination directory from saved bookmark
        loadSavedDestination()
    }

    private func loadSavedDestination() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: UserDefaultsKeys.destinationBookmark) else {
            return
        }

        do {
            let result = try SecurityScopedAccess.resolveBookmark(bookmarkData)

            // If bookmark is stale, try to refresh it
            if result.isStale {
                // Need to access the resource to refresh
                if result.url.startAccessingSecurityScopedResource() {
                    defer { result.url.stopAccessingSecurityScopedResource() }

                    // Create new bookmark
                    let newBookmark = try SecurityScopedAccess.createBookmark(for: result.url)
                    UserDefaults.standard.set(newBookmark, forKey: UserDefaultsKeys.destinationBookmark)
                    destinationBookmark = newBookmark
                } else {
                    // Can't refresh, clear the saved bookmark
                    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.destinationBookmark)
                    return
                }
            } else {
                destinationBookmark = bookmarkData
            }

            destinationDirectory = result.url
        } catch {
            // Invalid bookmark, clear it
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.destinationBookmark)
        }
    }

    private func saveDestinationBookmark(_ bookmark: Data) {
        UserDefaults.standard.set(bookmark, forKey: UserDefaultsKeys.destinationBookmark)
    }

    // MARK: - Workflow State

    enum WorkflowState: Equatable {
        case setup
        case scanning
        case dateConfirmation
        case eventConfirmation
        case preview
        case executing
        case paused
        case completed
        case error(String)
    }

    var workflowState: WorkflowState = .setup

    // MARK: - Scanning State

    var scanProgress = DirectoryScanner.ScanProgress()
    var scannedFiles: [MediaFile] = []

    // MARK: - Confirmation State

    var directoriesNeedingDateConfirmation: [DirectoryDateGroup] = []
    var currentDateConfirmationIndex: Int = 0

    var directoriesNeedingEventConfirmation: [DirectoryEventGroup] = []
    var currentEventConfirmationIndex: Int = 0

    // MARK: - Preview State

    var plannedOperations: [PlannedOperation] = []
    var duplicateCount: Int = 0

    // MARK: - Execution State

    var executionProgress = FileOperationService.OperationProgress(
        current: 0, total: 0, currentFile: "", bytesProcessed: 0, totalBytes: 0
    )
    var completedOperations: Int = 0
    var failedOperations: Int = 0
    var operationErrors: [(filename: String, error: String)] = []

    // MARK: - Completion State

    var forwardScriptPath: URL?
    var undoScriptPath: URL?
    var logsDirectory: URL?

    // MARK: - Services

    private let scanner = DirectoryScanner()
    private let metadataExtractor = MetadataExtractor()
    private let dateParser = DateParser()
    private let eventParser = EventDescriptionParser()
    private let duplicateHandler = DuplicateHandler()
    private let operationService = FileOperationService()
    private let scriptGenerator = ScriptGenerator()

    // MARK: - Computed Properties

    var canStartScan: Bool {
        sourceDirectory != nil && destinationDirectory != nil && workflowState == .setup
    }

    var isScanning: Bool {
        if case .scanning = workflowState { return true }
        return false
    }

    var isExecuting: Bool {
        if case .executing = workflowState { return true }
        return false
    }

    // Cancellation flag for scanning
    private var scanCancelled = false

    var totalFilesCount: Int {
        scannedFiles.count
    }

    var filesWithDateCount: Int {
        scannedFiles.filter { $0.detectedDate != nil }.count
    }

    var filesWithoutDateCount: Int {
        scannedFiles.filter { $0.detectedDate == nil }.count
    }

    // MARK: - Directory Selection

    func selectSourceDirectory() {
        if let result = SecurityScopedAccess.selectDirectory(
            message: "Select the folder containing photos to organize",
            prompt: "Select Source"
        ) {
            sourceDirectory = result.url
            sourceBookmark = result.bookmark
        }
    }

    func selectDestinationDirectory() {
        if let result = SecurityScopedAccess.selectDirectory(
            message: "Select the destination folder for organized photos",
            prompt: "Select Destination"
        ) {
            destinationDirectory = result.url
            destinationBookmark = result.bookmark
            // Save for future sessions
            saveDestinationBookmark(result.bookmark)
        }
    }

    // MARK: - Scanning

    func cancelScan() async {
        scanCancelled = true
        await scanner.cancel()
        // Reset to setup state, keeping directories
        workflowState = .setup
        scanProgress = DirectoryScanner.ScanProgress()
        scannedFiles = []
    }

    func startScan() async {
        guard let source = sourceDirectory else { return }

        workflowState = .scanning
        scanCancelled = false
        scanProgress = DirectoryScanner.ScanProgress()
        scannedFiles = []

        do {
            // Start security-scoped access
            guard source.startAccessingSecurityScopedResource() else {
                workflowState = .error("Cannot access source directory. Please select it again.")
                return
            }
            defer { source.stopAccessingSecurityScopedResource() }

            // Scan directory
            let discoveredFiles = try await scanner.scan(directory: source) { [weak self] progress in
                Task { @MainActor in
                    self?.scanProgress = progress
                }
            }

            // Check if cancelled after directory scan
            if scanCancelled { return }

            // Update progress for metadata extraction phase
            scanProgress.phase = .extractingMetadata
            scanProgress.totalFilesToProcess = discoveredFiles.count
            scanProgress.filesProcessed = 0

            // Process each discovered file with progress reporting
            for (index, discovered) in discoveredFiles.enumerated() {
                // Check for cancellation
                if scanCancelled { return }

                scanProgress.filesProcessed = index
                scanProgress.currentFile = discovered.url.lastPathComponent
                scanProgress.lastUpdateTime = Date()

                let mediaFile = await processDiscoveredFile(discovered)
                scannedFiles.append(mediaFile)

                // Update progress after processing
                scanProgress.filesProcessed = index + 1
            }

            // Check if cancelled after processing
            if scanCancelled { return }

            scanProgress.filesProcessed = discoveredFiles.count

            // Group files needing date confirmation by directory
            groupFilesNeedingDateConfirmation()

            // Transition to next state
            if !directoriesNeedingDateConfirmation.isEmpty {
                currentDateConfirmationIndex = 0
                workflowState = .dateConfirmation
            } else {
                prepareEventConfirmation()
            }

        } catch DirectoryScanner.ScanError.cancelled {
            // Scan was cancelled, just return (state already reset by cancelScan)
            return
        } catch {
            if !scanCancelled {
                workflowState = .error("Scan failed: \(error.localizedDescription)")
            }
        }
    }

    private func processDiscoveredFile(_ discovered: DirectoryScanner.DiscoveredFile) async -> MediaFile {
        let file = MediaFile(
            originalPath: discovered.url.path,
            filename: discovered.url.lastPathComponent,
            fileExtension: discovered.url.pathExtension.lowercased(),
            mediaType: discovered.mediaType,
            sourceDirectoryName: discovered.parentDirectoryName,
            sourceDirectoryPath: discovered.parentDirectoryPath
        )
        file.fileSizeBytes = discovered.fileSizeBytes

        // Try to extract date from metadata
        let extractedDate = await metadataExtractor.extractDate(
            from: discovered.url,
            mediaType: discovered.mediaType
        )

        if let extracted = extractedDate {
            file.detectedDate = extracted.date
            file.dateSource = extracted.source
        }

        // Fallback: Try directory name
        if file.detectedDate == nil || file.dateSource == .fileModificationDate {
            if let parsed = dateParser.parseDate(from: discovered.parentDirectoryName) {
                // Only use directory date if we don't have EXIF/video metadata
                if file.detectedDate == nil || file.dateSource == .fileModificationDate {
                    file.detectedDate = parsed.date
                    file.dateSource = .directoryName
                }
            }
        }

        // Extract event description from directory name
        file.eventDescription = eventParser.extractEventDescription(from: discovered.parentDirectoryName)

        return file
    }

    // MARK: - Date Confirmation

    private func groupFilesNeedingDateConfirmation() {
        // Group files without good dates by their source directory
        let filesNeedingDate = scannedFiles.filter {
            $0.detectedDate == nil || $0.dateSource == .fileModificationDate
        }

        let grouped = Dictionary(grouping: filesNeedingDate) { $0.sourceDirectoryPath }

        directoriesNeedingDateConfirmation = grouped.map { path, files in
            DirectoryDateGroup(
                directoryPath: path,
                directoryName: URL(fileURLWithPath: path).lastPathComponent,
                files: files,
                suggestedDate: dateParser.parseDate(from: URL(fileURLWithPath: path).lastPathComponent)?.date
            )
        }.sorted { $0.directoryName < $1.directoryName }
    }

    func confirmDate(_ date: Date, for group: DirectoryDateGroup) {
        for file in group.files {
            file.detectedDate = date
            file.dateSource = .userInput
            file.dateConfirmed = true
        }

        advanceToNextDateConfirmation()
    }

    func skipDateConfirmation(for group: DirectoryDateGroup) {
        for file in group.files {
            file.processingStatus = .skipped
        }

        advanceToNextDateConfirmation()
    }

    private func advanceToNextDateConfirmation() {
        currentDateConfirmationIndex += 1

        if currentDateConfirmationIndex >= directoriesNeedingDateConfirmation.count {
            prepareEventConfirmation()
        }
    }

    // MARK: - Event Confirmation

    private func prepareEventConfirmation() {
        // Group files by their source directory for event confirmation
        let processableFiles = scannedFiles.filter { $0.processingStatus != .skipped && $0.detectedDate != nil }
        let grouped = Dictionary(grouping: processableFiles) { $0.sourceDirectoryPath }

        directoriesNeedingEventConfirmation = grouped.map { path, files in
            let dirName = URL(fileURLWithPath: path).lastPathComponent
            let suggestedEvent = eventParser.extractEventDescription(from: dirName)

            return DirectoryEventGroup(
                directoryPath: path,
                directoryName: dirName,
                files: files,
                suggestedEvent: suggestedEvent
            )
        }.sorted { $0.directoryName < $1.directoryName }

        if !directoriesNeedingEventConfirmation.isEmpty {
            currentEventConfirmationIndex = 0
            workflowState = .eventConfirmation
        } else {
            Task {
                await generatePreview()
            }
        }
    }

    func confirmEvent(_ event: String?, for group: DirectoryEventGroup) {
        for file in group.files {
            file.eventDescription = event
            file.eventConfirmed = true
        }

        advanceToNextEventConfirmation()
    }

    func skipEventConfirmation(for group: DirectoryEventGroup) {
        for file in group.files {
            file.eventDescription = nil
            file.eventConfirmed = true
        }

        advanceToNextEventConfirmation()
    }

    private func advanceToNextEventConfirmation() {
        currentEventConfirmationIndex += 1

        if currentEventConfirmationIndex >= directoriesNeedingEventConfirmation.count {
            Task {
                await generatePreview()
            }
        }
    }

    // MARK: - Preview Generation

    func generatePreview() async {
        guard let destination = destinationDirectory else { return }

        await duplicateHandler.reset()
        plannedOperations = []
        duplicateCount = 0

        let pathBuilder = DestinationPathBuilder(destinationRoot: destination)

        // Start destination access
        guard destination.startAccessingSecurityScopedResource() else {
            workflowState = .error("Cannot access destination directory. Please select it again.")
            return
        }
        defer { destination.stopAccessingSecurityScopedResource() }

        for file in scannedFiles where file.processingStatus != .skipped {
            guard let date = file.detectedDate else {
                file.processingStatus = .skipped
                continue
            }

            let destPath = pathBuilder.buildDestinationPath(
                filename: file.filename,
                date: date,
                eventDescription: file.eventDescription
            )

            // Check for duplicates
            let duplicateResult = await duplicateHandler.checkForDuplicate(destinationPath: destPath)

            let operation = PlannedOperation(
                sourcePath: file.originalPath,
                destinationPath: destPath.path
            )

            switch duplicateResult {
            case .unique:
                break
            case .duplicate(let original, let newPath, let suffix):
                operation.isDuplicate = true
                operation.originalDestinationPath = original.path
                operation.destinationPath = newPath.path
                operation.duplicateSuffix = suffix
                duplicateCount += 1
            }

            operation.mediaFile = file
            file.plannedOperation = operation
            file.processingStatus = .planned

            plannedOperations.append(operation)
        }

        workflowState = .preview
    }

    // MARK: - Execution

    func executeOperations() async {
        guard let destination = destinationDirectory,
              let source = sourceDirectory else { return }

        workflowState = .executing
        completedOperations = 0
        failedOperations = 0
        operationErrors = []

        // Start security-scoped access
        guard source.startAccessingSecurityScopedResource() else {
            workflowState = .error("Cannot access source directory.")
            return
        }
        guard destination.startAccessingSecurityScopedResource() else {
            source.stopAccessingSecurityScopedResource()
            workflowState = .error("Cannot access destination directory.")
            return
        }

        defer {
            source.stopAccessingSecurityScopedResource()
            destination.stopAccessingSecurityScopedResource()
        }

        do {
            // Execute operations
            let results = try await operationService.execute(operations: plannedOperations) { [weak self] progress in
                Task { @MainActor in
                    self?.executionProgress = progress
                }
            }

            // Process results
            for result in results {
                if result.success {
                    completedOperations += 1
                    if let op = plannedOperations.first(where: { $0.id == result.operationId }) {
                        op.status = .completed
                        op.executedAt = Date()
                        op.mediaFile?.processingStatus = .completed
                    }
                } else {
                    failedOperations += 1
                    if let op = plannedOperations.first(where: { $0.id == result.operationId }) {
                        op.status = .failed
                        op.errorMessage = result.error
                        op.mediaFile?.processingStatus = .failed
                        op.mediaFile?.errorMessage = result.error

                        operationErrors.append((
                            filename: op.sourceFilename,
                            error: result.error ?? "Unknown error"
                        ))
                    }
                }
            }

            // Generate scripts
            await generateScripts()

            workflowState = .completed

        } catch {
            workflowState = .error("Execution failed: \(error.localizedDescription)")
        }
    }

    func pauseExecution() async {
        await operationService.pause()
        workflowState = .paused
    }

    func resumeExecution() async {
        await operationService.resume()
        workflowState = .executing
    }

    func cancelExecution() async {
        await operationService.cancel()
        workflowState = .error("Operation cancelled by user")
    }

    // MARK: - Script Generation

    private func generateScripts() async {
        guard let destination = destinationDirectory else { return }

        do {
            let timestamp = DateFormatters.filenameTimestamp()

            // Create logs directory
            let logsDir = try PathUtilities.logsDirectory(
                for: destination.path,
                sessionId: UUID()
            )
            logsDirectory = logsDir

            let paths = scriptGenerator.scriptPaths(logsDirectory: logsDir, timestamp: timestamp)

            // Generate forward script
            forwardScriptPath = try scriptGenerator.generateForwardScript(
                operations: plannedOperations.filter { $0.status == .completed },
                outputPath: paths.forward
            )

            // Generate undo script
            undoScriptPath = try scriptGenerator.generateUndoScript(
                operations: plannedOperations.filter { $0.status == .completed },
                outputPath: paths.undo
            )

            // Generate duplicate log if needed
            let duplicates = plannedOperations.filter { $0.isDuplicate }
            if !duplicates.isEmpty {
                _ = try scriptGenerator.generateDuplicateLog(
                    operations: duplicates,
                    outputPath: paths.duplicateLog
                )
            }

        } catch {
            print("Failed to generate scripts: \(error)")
        }
    }

    // MARK: - Reset

    func reset() {
        sourceDirectory = nil
        sourceBookmark = nil
        // Keep destination directory - restore from saved bookmark
        loadSavedDestination()
        workflowState = .setup
        scanProgress = DirectoryScanner.ScanProgress()
        scannedFiles = []
        directoriesNeedingDateConfirmation = []
        directoriesNeedingEventConfirmation = []
        plannedOperations = []
        duplicateCount = 0
        completedOperations = 0
        failedOperations = 0
        operationErrors = []
        forwardScriptPath = nil
        undoScriptPath = nil
        logsDirectory = nil
    }
}

// MARK: - Helper Types

struct DirectoryDateGroup: Identifiable {
    let id = UUID()
    let directoryPath: String
    let directoryName: String
    let files: [MediaFile]
    let suggestedDate: Date?

    var fileCount: Int { files.count }

    var sampleFilenames: [String] {
        Array(files.prefix(5).map { $0.filename })
    }
}

struct DirectoryEventGroup: Identifiable {
    let id = UUID()
    let directoryPath: String
    let directoryName: String
    let files: [MediaFile]
    let suggestedEvent: String?

    var fileCount: Int { files.count }

    var dateRange: String {
        let dates = files.compactMap { $0.detectedDate }.sorted()
        guard let first = dates.first else { return "No date" }

        if let last = dates.last, first != last {
            return "\(DateFormatters.displayString(for: first)) - \(DateFormatters.displayString(for: last))"
        }
        return DateFormatters.displayString(for: first)
    }
}
