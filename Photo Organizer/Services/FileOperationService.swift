import Foundation

actor FileOperationService {
    // MARK: - State

    private var isCancelled = false
    private var isPaused = false

    // MARK: - Progress

    struct OperationProgress: Sendable {
        var current: Int
        var total: Int
        var currentFile: String
        var bytesProcessed: Int64
        var totalBytes: Int64
    }

    // MARK: - Result

    struct OperationResult: Sendable {
        let operationId: UUID
        let success: Bool
        let error: String?
    }

    // MARK: - Control Methods

    func pause() {
        isPaused = true
    }

    func resume() {
        isPaused = false
    }

    func cancel() {
        isCancelled = true
    }

    func reset() {
        isCancelled = false
        isPaused = false
    }

    var paused: Bool {
        isPaused
    }

    var cancelled: Bool {
        isCancelled
    }

    // MARK: - Execution

    /// Executes a batch of file move operations
    func execute(
        operations: [PlannedOperation],
        progressHandler: @escaping @Sendable (OperationProgress) -> Void
    ) async throws -> [OperationResult] {
        reset()
        var results: [OperationResult] = []

        // Calculate total bytes for progress
        var totalBytes: Int64 = 0
        for operation in operations {
            if let size = try? FileManager.default.attributesOfItem(atPath: operation.sourcePath)[.size] as? Int64 {
                totalBytes += size
            }
        }

        var bytesProcessed: Int64 = 0

        for (index, operation) in operations.enumerated() {
            // Check for cancellation
            if isCancelled {
                throw OperationError.cancelled
            }

            // Wait if paused
            while isPaused {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                if isCancelled {
                    throw OperationError.cancelled
                }
            }

            // Report progress
            let progress = OperationProgress(
                current: index + 1,
                total: operations.count,
                currentFile: operation.sourceFilename,
                bytesProcessed: bytesProcessed,
                totalBytes: totalBytes
            )
            progressHandler(progress)

            // Execute the operation
            let result = await executeOperation(operation)
            results.append(result)

            // Update bytes processed
            if let size = try? FileManager.default.attributesOfItem(atPath: operation.sourcePath)[.size] as? Int64 {
                bytesProcessed += size
            }
        }

        return results
    }

    /// Executes a single file move operation
    private func executeOperation(_ operation: PlannedOperation) async -> OperationResult {
        let fileManager = FileManager.default
        let sourceURL = URL(fileURLWithPath: operation.sourcePath)
        let destURL = URL(fileURLWithPath: operation.destinationPath)

        do {
            // Create destination directory if needed
            let destDir = destURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: destDir.path) {
                try fileManager.createDirectory(
                    at: destDir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }

            // Move the file
            try fileManager.moveItem(at: sourceURL, to: destURL)

            // Verify the move
            if !fileManager.fileExists(atPath: destURL.path) {
                return OperationResult(
                    operationId: operation.id,
                    success: false,
                    error: "File was not found at destination after move"
                )
            }

            return OperationResult(
                operationId: operation.id,
                success: true,
                error: nil
            )

        } catch let error as NSError {
            let errorMessage: String

            switch error.code {
            case NSFileWriteNoPermissionError:
                errorMessage = "Permission denied"
            case NSFileWriteOutOfSpaceError:
                errorMessage = "Not enough disk space"
            case NSFileWriteFileExistsError:
                errorMessage = "File already exists at destination"
            case NSFileNoSuchFileError:
                errorMessage = "Source file not found"
            default:
                errorMessage = error.localizedDescription
            }

            return OperationResult(
                operationId: operation.id,
                success: false,
                error: errorMessage
            )
        }
    }

    // MARK: - Errors

    enum OperationError: LocalizedError {
        case cancelled
        case sourceNotFound(String)
        case destinationExists(String)
        case permissionDenied(String)

        var errorDescription: String? {
            switch self {
            case .cancelled:
                return "Operation was cancelled"
            case .sourceNotFound(let path):
                return "Source file not found: \(path)"
            case .destinationExists(let path):
                return "File already exists: \(path)"
            case .permissionDenied(let path):
                return "Permission denied: \(path)"
            }
        }
    }
}
