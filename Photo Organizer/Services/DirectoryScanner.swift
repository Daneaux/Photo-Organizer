import Foundation

actor DirectoryScanner {
    // MARK: - Progress Reporting

    struct ScanProgress: Sendable {
        var directoriesScanned: Int = 0
        var filesFound: Int = 0
        var currentDirectory: String = ""
    }

    // MARK: - Discovered File

    struct DiscoveredFile: Sendable {
        let url: URL
        let mediaType: MediaType
        let parentDirectoryName: String
        let parentDirectoryPath: String
        let fileSizeBytes: Int64
    }

    // MARK: - Scanning

    private var isCancelled = false

    func cancel() {
        isCancelled = true
    }

    func scan(
        directory: URL,
        progressHandler: @escaping @Sendable (ScanProgress) -> Void
    ) async throws -> [DiscoveredFile] {
        isCancelled = false
        var discoveredFiles: [DiscoveredFile] = []
        var progress = ScanProgress()

        let fileManager = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .isRegularFileKey
        ]

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw ScanError.failedToEnumerate(directory.path)
        }

        var lastProgressUpdate = Date()
        let progressUpdateInterval: TimeInterval = 0.1 // 100ms

        for case let fileURL as URL in enumerator {
            // Check for cancellation
            if isCancelled {
                throw ScanError.cancelled
            }

            // Get file attributes
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys) else {
                continue
            }

            // Skip directories
            if resourceValues.isDirectory == true {
                progress.directoriesScanned += 1
                progress.currentDirectory = fileURL.lastPathComponent

                // Report progress periodically
                if Date().timeIntervalSince(lastProgressUpdate) >= progressUpdateInterval {
                    progressHandler(progress)
                    lastProgressUpdate = Date()
                }
                continue
            }

            // Check if it's a supported file type
            let fileExtension = fileURL.pathExtension.lowercased()
            guard let mediaType = FileExtensions.mediaType(for: fileExtension) else {
                continue
            }

            // Create discovered file
            let parentURL = fileURL.deletingLastPathComponent()
            let fileSize = Int64(resourceValues.fileSize ?? 0)

            let discovered = DiscoveredFile(
                url: fileURL,
                mediaType: mediaType,
                parentDirectoryName: parentURL.lastPathComponent,
                parentDirectoryPath: parentURL.path,
                fileSizeBytes: fileSize
            )

            discoveredFiles.append(discovered)
            progress.filesFound += 1

            // Report progress periodically
            if Date().timeIntervalSince(lastProgressUpdate) >= progressUpdateInterval {
                progressHandler(progress)
                lastProgressUpdate = Date()
            }
        }

        // Final progress update
        progressHandler(progress)

        return discoveredFiles
    }

    // MARK: - Errors

    enum ScanError: LocalizedError {
        case failedToEnumerate(String)
        case cancelled

        var errorDescription: String? {
            switch self {
            case .failedToEnumerate(let path):
                return "Failed to scan directory: \(path)"
            case .cancelled:
                return "Scan was cancelled"
            }
        }
    }
}
