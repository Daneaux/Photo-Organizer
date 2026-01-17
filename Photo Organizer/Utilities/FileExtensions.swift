import Foundation

nonisolated(unsafe) struct FileExtensions: Sendable {
    // MARK: - Image Extensions

    static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "gif", "bmp", "tiff", "tif",
        "crw", "cr2", "cr3", "raw", "rw2", "raf"
    ]

    // MARK: - Video Extensions

    static let videoExtensions: Set<String> = [
        "mp4", "mov", "avi", "mkv", "m4v"
    ]

    // MARK: - All Supported Extensions

    static let allSupportedExtensions: Set<String> = {
        imageExtensions.union(videoExtensions)
    }()

    // MARK: - Helper Methods

    static func mediaType(for extension: String) -> MediaType? {
        let ext = `extension`.lowercased()
        if imageExtensions.contains(ext) {
            return .image
        } else if videoExtensions.contains(ext) {
            return .video
        }
        return nil
    }

    static func isSupported(_ extension: String) -> Bool {
        allSupportedExtensions.contains(`extension`.lowercased())
    }

    static func isImage(_ extension: String) -> Bool {
        imageExtensions.contains(`extension`.lowercased())
    }

    static func isVideo(_ extension: String) -> Bool {
        videoExtensions.contains(`extension`.lowercased())
    }

    // MARK: - Display Strings

    static var imageExtensionsDisplay: String {
        imageExtensions.sorted().joined(separator: ", ")
    }

    static var videoExtensionsDisplay: String {
        videoExtensions.sorted().joined(separator: ", ")
    }
}
