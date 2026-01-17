import Foundation

actor DuplicateHandler {
    // MARK: - State

    private var plannedDestinations: Set<String> = []

    // MARK: - Result Types

    enum DuplicateResult {
        case unique(path: URL)
        case duplicate(originalPath: URL, newPath: URL, suffix: String)
    }

    // MARK: - Public Methods

    /// Resets the handler for a new session
    func reset() {
        plannedDestinations.removeAll()
    }

    /// Checks if a destination path would be a duplicate and returns the appropriate path
    func checkForDuplicate(destinationPath: URL) -> DuplicateResult {
        let normalizedPath = destinationPath.path.lowercased()

        // Check against existing files in destination
        let fileExists = FileManager.default.fileExists(atPath: destinationPath.path)

        // Check against other planned operations
        let alreadyPlanned = plannedDestinations.contains(normalizedPath)

        if fileExists || alreadyPlanned {
            let newPath = generateUniquePath(for: destinationPath)
            let suffix = extractSuffix(original: destinationPath, new: newPath)
            return .duplicate(originalPath: destinationPath, newPath: newPath, suffix: suffix)
        }

        // Mark this path as planned
        plannedDestinations.insert(normalizedPath)
        return .unique(path: destinationPath)
    }

    /// Registers a path as planned without checking for duplicates
    /// (useful when user manually edits a destination)
    func registerPath(_ path: URL) {
        plannedDestinations.insert(path.path.lowercased())
    }

    /// Unregisters a path (when an operation is cancelled or modified)
    func unregisterPath(_ path: URL) {
        plannedDestinations.remove(path.path.lowercased())
    }

    // MARK: - Private Methods

    private func generateUniquePath(for url: URL) -> URL {
        let directory = url.deletingLastPathComponent()
        let filename = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        var counter = 1
        var newURL: URL

        repeat {
            let newFilename: String
            if ext.isEmpty {
                newFilename = "\(filename)_duplicate_\(counter)"
            } else {
                newFilename = "\(filename)_duplicate_\(counter).\(ext)"
            }
            newURL = directory.appendingPathComponent(newFilename)
            counter += 1
        } while FileManager.default.fileExists(atPath: newURL.path) ||
                plannedDestinations.contains(newURL.path.lowercased())

        // Register the new unique path
        plannedDestinations.insert(newURL.path.lowercased())

        return newURL
    }

    private func extractSuffix(original: URL, new: URL) -> String {
        let originalFilename = original.deletingPathExtension().lastPathComponent
        let newFilename = new.deletingPathExtension().lastPathComponent

        if newFilename.hasPrefix(originalFilename) {
            return String(newFilename.dropFirst(originalFilename.count))
        }
        return ""
    }

    // MARK: - Statistics

    var plannedCount: Int {
        plannedDestinations.count
    }
}
