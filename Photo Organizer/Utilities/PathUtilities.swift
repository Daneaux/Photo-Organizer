import Foundation

struct PathUtilities {
    // MARK: - Path Manipulation

    /// Extracts the parent directory name from a path
    static func parentDirectoryName(for path: String) -> String {
        URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent
    }

    /// Extracts the parent directory path from a path
    static func parentDirectoryPath(for path: String) -> String {
        URL(fileURLWithPath: path).deletingLastPathComponent().path
    }

    /// Gets filename without extension
    static func filenameWithoutExtension(for path: String) -> String {
        URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }

    /// Gets the file extension (lowercase, without dot)
    static func fileExtension(for path: String) -> String {
        URL(fileURLWithPath: path).pathExtension.lowercased()
    }

    /// Sanitizes a string for use in a filename/path
    static func sanitizeForPath(_ string: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let sanitized = string
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Replace multiple underscores with single
        return sanitized.replacingOccurrences(
            of: "_+",
            with: "_",
            options: .regularExpression
        )
    }

    /// Creates a relative path from a base path
    static func relativePath(from basePath: String, to fullPath: String) -> String {
        guard fullPath.hasPrefix(basePath) else { return fullPath }

        var relative = String(fullPath.dropFirst(basePath.count))
        if relative.hasPrefix("/") {
            relative = String(relative.dropFirst())
        }
        return relative
    }

    /// Escapes a path for use in shell scripts
    static func escapeForShell(_ path: String) -> String {
        path
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "!", with: "\\!")
    }

    // MARK: - Directory Operations

    /// Ensures a directory exists, creating it if necessary
    static func ensureDirectoryExists(at path: String) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
            if !isDirectory.boolValue {
                throw PathError.pathExistsAsFile(path)
            }
        } else {
            try fileManager.createDirectory(
                atPath: path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    /// Checks if a path is a directory
    static func isDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return exists && isDir.boolValue
    }

    /// Checks if a file exists at path
    static func fileExists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    // MARK: - Logs Directory

    /// Gets or creates the logs directory for an organization session
    static func logsDirectory(for destinationPath: String, sessionId: UUID) throws -> URL {
        let destURL = URL(fileURLWithPath: destinationPath)
        let logsURL = destURL
            .appendingPathComponent(".photo-organizer-logs")
            .appendingPathComponent(sessionId.uuidString)

        try ensureDirectoryExists(at: logsURL.path)
        return logsURL
    }

    // MARK: - Errors

    enum PathError: LocalizedError {
        case pathExistsAsFile(String)
        case invalidPath(String)

        var errorDescription: String? {
            switch self {
            case .pathExistsAsFile(let path):
                return "Path exists as a file, not a directory: \(path)"
            case .invalidPath(let path):
                return "Invalid path: \(path)"
            }
        }
    }
}
