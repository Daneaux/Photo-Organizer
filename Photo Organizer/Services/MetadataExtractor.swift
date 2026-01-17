import Foundation
import ImageIO
import AVFoundation
import CoreGraphics

actor MetadataExtractor {
    // MARK: - Extracted Date

    struct ExtractedDate: Sendable {
        let date: Date
        let source: DateSource
    }

    // RAW formats that often cause ImageIO errors - use mdls instead
    private static let problematicRawExtensions: Set<String> = [
        "cr2", "cr3", "crw", "raw", "rw2", "raf", "nef", "arw", "dng", "orf", "pef", "srw"
    ]

    // MARK: - Image Date Extraction (using ImageIO)

    func extractImageDate(from url: URL) async -> ExtractedDate? {
        let fileExtension = url.pathExtension.lowercased()

        // For problematic RAW formats, try mdls (Spotlight metadata) first
        if Self.problematicRawExtensions.contains(fileExtension) {
            if let date = extractDateUsingMdls(from: url) {
                return date
            }
            // Fall through to try ImageIO anyway, but errors will be suppressed
        }

        return extractDateUsingImageIO(from: url)
    }

    // MARK: - ImageIO Extraction

    private func extractDateUsingImageIO(from url: URL) -> ExtractedDate? {
        // Use minimal options to avoid triggering image decode
        let sourceOptions: [String: Any] = [
            kCGImageSourceShouldCache as String: false,
            kCGImageSourceShouldAllowFloat as String: false
        ]

        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, sourceOptions as CFDictionary) else {
            return nil
        }

        // Try to get properties - this may still log errors for some RAW formats but won't crash
        let propertyOptions: [String: Any] = [
            kCGImageSourceShouldCache as String: false
        ]

        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, propertyOptions as CFDictionary) as? [String: Any] else {
            return nil
        }

        return extractDateFromProperties(properties)
    }

    private func extractDateFromProperties(_ properties: [String: Any]) -> ExtractedDate? {
        // Check EXIF dictionary
        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            // Priority 1: DateTimeOriginal (when the photo was actually taken)
            if let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String,
               let date = DateFormatters.parseExifDate(dateString) {
                return ExtractedDate(date: date, source: .exifDateTimeOriginal)
            }

            // Priority 2: DateTimeDigitized (when the image was digitized)
            if let dateString = exif[kCGImagePropertyExifDateTimeDigitized as String] as? String,
               let date = DateFormatters.parseExifDate(dateString) {
                return ExtractedDate(date: date, source: .exifDateTimeDigitized)
            }
        }

        // Check TIFF dictionary for DateTime
        if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let dateString = tiff[kCGImagePropertyTIFFDateTime as String] as? String,
           let date = DateFormatters.parseExifDate(dateString) {
            return ExtractedDate(date: date, source: .exifCreateDate)
        }

        // Check for GPS timestamp as last resort for EXIF
        if let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
           let dateString = gps[kCGImagePropertyGPSDateStamp as String] as? String {
            // GPS date format is typically "YYYY:MM:DD"
            if let date = DateFormatters.parseExifDate(dateString + " 00:00:00") {
                return ExtractedDate(date: date, source: .exifCreateDate)
            }
        }

        return nil
    }

    // MARK: - mdls Extraction (Spotlight metadata - works well for RAW files)

    private func extractDateUsingMdls(from url: URL) -> ExtractedDate? {
        // Use Spotlight metadata which is pre-indexed and doesn't require decoding
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdls")
        process.arguments = [
            "-name", "kMDItemContentCreationDate",
            "-name", "kMDItemDateTimeOriginal",
            "-raw",
            url.path
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return nil
            }

            // Parse mdls output - with -raw, values are separated by spaces or newlines
            // Handle both "(null)" values and actual dates like "2024-03-21 18:35:26 +0000"
            // Also remove any null bytes that might be in the output
            // Split by "(null)" first to separate values, then try to parse each
            let cleanedOutput = output
                .replacingOccurrences(of: "\0", with: "")
                .replacingOccurrences(of: "(null)", with: "\n")
            let parts = cleanedOutput
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            for part in parts {
                if let date = parseMdlsDate(part) {
                    return ExtractedDate(date: date, source: .exifDateTimeOriginal)
                }
            }
        } catch {
            // mdls failed, will fall back to ImageIO
        }

        return nil
    }

    private func parseMdlsDate(_ string: String) -> Date? {
        // mdls date format: "2024-01-15 14:30:45 +0000"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        if let date = formatter.date(from: string) {
            return date
        }

        // Try ISO8601
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: string) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: string)
    }

    // MARK: - Video Date Extraction (using AVFoundation)

    func extractVideoDate(from url: URL) async -> ExtractedDate? {
        let asset = AVURLAsset(url: url)

        // Try loading creation date
        do {
            let creationDate = try await asset.load(.creationDate)
            if let date = creationDate?.dateValue {
                return ExtractedDate(date: date, source: .videoCreationDate)
            }
        } catch {
            // Creation date not available, try common metadata
        }

        // Fallback: Check common metadata
        do {
            let metadata = try await asset.load(.commonMetadata)
            for item in metadata {
                if item.commonKey == .commonKeyCreationDate {
                    if let dateValue = try? await item.load(.dateValue) {
                        return ExtractedDate(date: dateValue, source: .videoCreationDate)
                    }
                }
            }
        } catch {
            // Metadata extraction failed
        }

        // Fallback: Try mdls (Spotlight metadata) for older video formats like AVI
        // that AVFoundation may not fully support
        if let date = extractDateUsingMdls(from: url) {
            return ExtractedDate(date: date.date, source: .videoCreationDate)
        }

        return nil
    }

    // MARK: - File Modification Date (Fallback)

    func extractFileModificationDate(from url: URL) -> ExtractedDate? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let modDate = attributes[.modificationDate] as? Date {
                return ExtractedDate(date: modDate, source: .fileModificationDate)
            }
        } catch {
            // Failed to get file attributes
        }
        return nil
    }

    // MARK: - Combined Extraction

    /// Extracts date from any supported media file using the best available method
    func extractDate(from url: URL, mediaType: MediaType) async -> ExtractedDate? {
        // First, try the appropriate metadata extraction
        let metadataDate: ExtractedDate?

        switch mediaType {
        case .image:
            metadataDate = await extractImageDate(from: url)
        case .video:
            metadataDate = await extractVideoDate(from: url)
        }

        // If we got a date from metadata, return it
        if let date = metadataDate {
            return date
        }

        // Fallback to file modification date (low confidence)
        return extractFileModificationDate(from: url)
    }
}
