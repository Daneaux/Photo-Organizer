import Foundation
import AppKit

final class SecurityScopedAccess {
    // MARK: - Bookmark Creation

    /// Creates a security-scoped bookmark for the given URL
    static func createBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    /// Resolves a security-scoped bookmark to a URL
    static func resolveBookmark(_ bookmarkData: Data) throws -> (url: URL, isStale: Bool) {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return (url, isStale)
    }

    // MARK: - Access Control

    /// Starts accessing a security-scoped resource
    @discardableResult
    static func startAccessing(_ url: URL) -> Bool {
        url.startAccessingSecurityScopedResource()
    }

    /// Stops accessing a security-scoped resource
    static func stopAccessing(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
    }

    // MARK: - RAII Wrapper

    /// A wrapper that automatically manages security-scoped access lifetime
    final class ScopedAccess {
        private let url: URL
        private var isAccessing: Bool = false

        var accessURL: URL { url }

        init(url: URL) throws {
            self.url = url
            self.isAccessing = url.startAccessingSecurityScopedResource()
            if !isAccessing {
                throw AccessError.failedToStartAccess(url.path)
            }
        }

        init(bookmarkData: Data) throws {
            var isStale = false
            self.url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                throw AccessError.bookmarkIsStale
            }

            self.isAccessing = url.startAccessingSecurityScopedResource()
            if !isAccessing {
                throw AccessError.failedToStartAccess(url.path)
            }
        }

        deinit {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    // MARK: - Directory Selection

    /// Presents an open panel for directory selection and returns the URL with bookmark data
    @MainActor
    static func selectDirectory(
        message: String,
        prompt: String = "Select"
    ) -> (url: URL, bookmark: Data)? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = message
        panel.prompt = prompt

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        do {
            let bookmark = try createBookmark(for: url)
            return (url, bookmark)
        } catch {
            print("Failed to create bookmark: \(error)")
            return nil
        }
    }

    // MARK: - Errors

    enum AccessError: LocalizedError {
        case failedToStartAccess(String)
        case bookmarkIsStale
        case invalidBookmark

        var errorDescription: String? {
            switch self {
            case .failedToStartAccess(let path):
                return "Failed to access: \(path). Please select the directory again."
            case .bookmarkIsStale:
                return "Access permission has expired. Please select the directory again."
            case .invalidBookmark:
                return "Invalid bookmark data."
            }
        }
    }
}
