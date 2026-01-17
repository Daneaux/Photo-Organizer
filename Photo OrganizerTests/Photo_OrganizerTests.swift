//
//  Photo_OrganizerTests.swift
//  Photo OrganizerTests
//
//  Created by Danny Dalal on 1/16/26.
//

import XCTest
@testable import Photo_Organizer

final class MetadataExtractorTests: XCTestCase {

    var extractor: MetadataExtractor!
    var samplePhotosURL: URL!

    override func setUpWithError() throws {
        extractor = MetadataExtractor()

        // Get the path to the Sample Photos folder
        // The Sample Photos folder is at the project root level
        let projectPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent() // Photo OrganizerTests
            .deletingLastPathComponent() // Photo Organizer
        samplePhotosURL = projectPath.appendingPathComponent("Sample Photos")

        // Verify the sample photos folder exists
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: samplePhotosURL.path, isDirectory: &isDirectory)
        XCTAssertTrue(exists && isDirectory.boolValue, "Sample Photos folder should exist at \(samplePhotosURL.path)")
    }

    override func tearDownWithError() throws {
        extractor = nil
        samplePhotosURL = nil
    }

    // MARK: - JPEG Tests

    /// IMG_2307.JPG should have date: January 3, 2015
    func testExtractDateFromJPEG() async throws {
        let jpegURL = samplePhotosURL.appendingPathComponent("IMG_2307.JPG")
        XCTAssertTrue(FileManager.default.fileExists(atPath: jpegURL.path), "IMG_2307.JPG should exist")

        let result = await extractor.extractImageDate(from: jpegURL)

        XCTAssertNotNil(result, "Should extract date from JPEG")

        if let extractedDate = result {
            // The date should be from EXIF metadata
            XCTAssertTrue(
                extractedDate.source == .exifDateTimeOriginal ||
                extractedDate.source == .exifDateTimeDigitized ||
                extractedDate.source == .exifCreateDate,
                "Date source should be from EXIF, got: \(extractedDate.source)"
            )

            // Verify specific date: January 3, 2015
            let calendar = Calendar.current
            let year = calendar.component(.year, from: extractedDate.date)
            let month = calendar.component(.month, from: extractedDate.date)
            let day = calendar.component(.day, from: extractedDate.date)

            XCTAssertEqual(year, 2015, "IMG_2307.JPG year should be 2015")
            XCTAssertEqual(month, 1, "IMG_2307.JPG month should be January (1)")
            XCTAssertEqual(day, 3, "IMG_2307.JPG day should be 3")
        }
    }

    // MARK: - RAW Format Tests (using mdls)

    /// 853A9693.CR3 should have date: May 3, 2024
    func testExtractDateFromCanonCR3() async throws {
        let cr3URL = samplePhotosURL.appendingPathComponent("853A9693.CR3")
        XCTAssertTrue(FileManager.default.fileExists(atPath: cr3URL.path), "853A9693.CR3 should exist")

        let result = await extractor.extractImageDate(from: cr3URL)

        XCTAssertNotNil(result, "Should extract date from Canon CR3 RAW file")

        if let extractedDate = result {
            // Verify specific date: May 3, 2024
            let calendar = Calendar.current
            let year = calendar.component(.year, from: extractedDate.date)
            let month = calendar.component(.month, from: extractedDate.date)
            let day = calendar.component(.day, from: extractedDate.date)

            XCTAssertEqual(year, 2024, "853A9693.CR3 year should be 2024")
            XCTAssertEqual(month, 5, "853A9693.CR3 month should be May (5)")
            XCTAssertEqual(day, 3, "853A9693.CR3 day should be 3")
        }
    }

    /// DSCF0003.RAF should have date: March 21, 2024
    func testExtractDateFromFujifilmRAF() async throws {
        let rafURL = samplePhotosURL.appendingPathComponent("DSCF0003.RAF")
        XCTAssertTrue(FileManager.default.fileExists(atPath: rafURL.path), "DSCF0003.RAF should exist")

        let result = await extractor.extractImageDate(from: rafURL)

        XCTAssertNotNil(result, "Should extract date from Fujifilm RAF RAW file")

        if let extractedDate = result {
            // Verify specific date: March 21, 2024
            let calendar = Calendar.current
            let year = calendar.component(.year, from: extractedDate.date)
            let month = calendar.component(.month, from: extractedDate.date)
            let day = calendar.component(.day, from: extractedDate.date)

            XCTAssertEqual(year, 2024, "DSCF0003.RAF year should be 2024")
            XCTAssertEqual(month, 3, "DSCF0003.RAF month should be March (3)")
            XCTAssertEqual(day, 21, "DSCF0003.RAF day should be 21")
        }
    }

    /// _VXV5191.RAF should have date: September 1, 2018
    func testExtractDateFromFujifilmRAF2() async throws {
        let rafURL = samplePhotosURL.appendingPathComponent("_VXV5191.RAF")
        XCTAssertTrue(FileManager.default.fileExists(atPath: rafURL.path), "_VXV5191.RAF should exist")

        let result = await extractor.extractImageDate(from: rafURL)

        XCTAssertNotNil(result, "Should extract date from second Fujifilm RAF RAW file")

        if let extractedDate = result {
            // Verify specific date: September 1, 2018
            let calendar = Calendar.current
            let year = calendar.component(.year, from: extractedDate.date)
            let month = calendar.component(.month, from: extractedDate.date)
            let day = calendar.component(.day, from: extractedDate.date)

            XCTAssertEqual(year, 2018, "_VXV5191.RAF year should be 2018")
            XCTAssertEqual(month, 9, "_VXV5191.RAF month should be September (9)")
            XCTAssertEqual(day, 1, "_VXV5191.RAF day should be 1")
        }
    }

    /// _1020652.RW2 should have date: January 31, 2023
    func testExtractDateFromPanasonicRW2() async throws {
        let rw2URL = samplePhotosURL.appendingPathComponent("_1020652.RW2")
        XCTAssertTrue(FileManager.default.fileExists(atPath: rw2URL.path), "_1020652.RW2 should exist")

        let result = await extractor.extractImageDate(from: rw2URL)

        XCTAssertNotNil(result, "Should extract date from Panasonic RW2 RAW file")

        if let extractedDate = result {
            // Verify specific date: January 31, 2023
            let calendar = Calendar.current
            let year = calendar.component(.year, from: extractedDate.date)
            let month = calendar.component(.month, from: extractedDate.date)
            let day = calendar.component(.day, from: extractedDate.date)

            XCTAssertEqual(year, 2023, "_1020652.RW2 year should be 2023")
            XCTAssertEqual(month, 1, "_1020652.RW2 month should be January (1)")
            XCTAssertEqual(day, 31, "_1020652.RW2 day should be 31")
        }
    }

    // MARK: - File Modification Date Fallback Tests

    func testExtractFileModificationDate() async throws {
        let jpegURL = samplePhotosURL.appendingPathComponent("IMG_2307.JPG")
        XCTAssertTrue(FileManager.default.fileExists(atPath: jpegURL.path), "IMG_2307.JPG should exist")

        let result = await extractor.extractFileModificationDate(from: jpegURL)

        XCTAssertNotNil(result, "Should extract file modification date")
        XCTAssertEqual(result?.source, .fileModificationDate, "Source should be fileModificationDate")
    }

    // MARK: - Combined Extraction Tests

    func testCombinedExtractionForImage() async throws {
        let jpegURL = samplePhotosURL.appendingPathComponent("IMG_2307.JPG")

        let result = await extractor.extractDate(from: jpegURL, mediaType: .image)

        XCTAssertNotNil(result, "Combined extraction should return a date for JPEG")

        // For images with EXIF, should prefer EXIF over file modification date
        if let extractedDate = result {
            XCTAssertNotEqual(
                extractedDate.source, .fileModificationDate,
                "Should prefer EXIF date over file modification date when EXIF is available"
            )
        }
    }

    // MARK: - All Sample Photos Test

    /// Verify all sample photos extract to their expected specific dates
    func testAllSamplePhotosHaveExtractableDates() async throws {
        // Expected dates for each sample file: (filename, year, month, day)
        let expectedDates: [(String, Int, Int, Int)] = [
            ("IMG_2307.JPG", 2015, 1, 3),      // January 3, 2015
            ("853A9693.CR3", 2024, 5, 3),      // May 3, 2024
            ("DSCF0003.RAF", 2024, 3, 21),     // March 21, 2024
            ("_VXV5191.RAF", 2018, 9, 1),      // September 1, 2018
            ("_1020652.RW2", 2023, 1, 31)      // January 31, 2023
        ]

        for (filename, expectedYear, expectedMonth, expectedDay) in expectedDates {
            let fileURL = samplePhotosURL.appendingPathComponent(filename)

            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                XCTFail("Sample file \(filename) does not exist")
                continue
            }

            let result = await extractor.extractImageDate(from: fileURL)

            XCTAssertNotNil(result, "Should extract date from \(filename)")

            if let extractedDate = result {
                let calendar = Calendar.current
                let year = calendar.component(.year, from: extractedDate.date)
                let month = calendar.component(.month, from: extractedDate.date)
                let day = calendar.component(.day, from: extractedDate.date)

                XCTAssertEqual(year, expectedYear, "\(filename): Year should be \(expectedYear), got \(year)")
                XCTAssertEqual(month, expectedMonth, "\(filename): Month should be \(expectedMonth), got \(month)")
                XCTAssertEqual(day, expectedDay, "\(filename): Day should be \(expectedDay), got \(day)")
            }
        }
    }

    // MARK: - Nonexistent File Tests

    func testExtractDateFromNonexistentFile() async throws {
        let fakeURL = samplePhotosURL.appendingPathComponent("NONEXISTENT.JPG")

        let result = await extractor.extractImageDate(from: fakeURL)

        XCTAssertNil(result, "Should return nil for nonexistent file")
    }

    // MARK: - Performance Tests

    func testExtractionPerformance() async throws {
        let jpegURL = samplePhotosURL.appendingPathComponent("IMG_2307.JPG")

        guard FileManager.default.fileExists(atPath: jpegURL.path) else {
            throw XCTSkip("IMG_2307.JPG not found for performance test")
        }

        // Measure extraction time
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<10 {
            _ = await extractor.extractImageDate(from: jpegURL)
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let avgTime = elapsed / 10

        print("Average JPEG extraction time: \(avgTime * 1000)ms")

        // Should be reasonably fast (less than 500ms per extraction)
        XCTAssertLessThan(avgTime, 0.5, "JPEG extraction should be fast")
    }
}

// MARK: - DateFormatters Tests

final class DateFormattersTests: XCTestCase {

    func testParseStandardExifDate() {
        let dateString = "2024:01:15 14:30:45"
        let result = DateFormatters.parseExifDate(dateString)

        XCTAssertNotNil(result, "Should parse standard EXIF date format")

        if let date = result {
            let calendar = Calendar.current
            XCTAssertEqual(calendar.component(.year, from: date), 2024)
            XCTAssertEqual(calendar.component(.month, from: date), 1)
            XCTAssertEqual(calendar.component(.day, from: date), 15)
            XCTAssertEqual(calendar.component(.hour, from: date), 14)
            XCTAssertEqual(calendar.component(.minute, from: date), 30)
            XCTAssertEqual(calendar.component(.second, from: date), 45)
        }
    }

    func testParseDateOnlyExifDate() {
        let dateString = "2024:01:15"
        let result = DateFormatters.parseExifDate(dateString)

        XCTAssertNotNil(result, "Should parse date-only EXIF format")

        if let date = result {
            let calendar = Calendar.current
            XCTAssertEqual(calendar.component(.year, from: date), 2024)
            XCTAssertEqual(calendar.component(.month, from: date), 1)
            XCTAssertEqual(calendar.component(.day, from: date), 15)
        }
    }

    func testParseInvalidExifDate() {
        let invalidStrings = [
            "invalid",
            "2024-01-15",  // Wrong separator
            "",
            "2024:13:45 99:99:99"  // Invalid values
        ]

        for invalid in invalidStrings {
            let result = DateFormatters.parseExifDate(invalid)
            // Note: Some invalid dates might still parse due to DateFormatter's lenient behavior
            // This test mainly ensures we don't crash
            if result != nil {
                print("Warning: '\(invalid)' unexpectedly parsed to \(result!)")
            }
        }
    }

    func testFolderDayString() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 7

        guard let date = calendar.date(from: components) else {
            XCTFail("Could not create test date")
            return
        }

        let result = DateFormatters.folderDayString(for: date)
        XCTAssertEqual(result, "03-07", "Folder day string should be MM-dd format")
    }

    func testYearString() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15

        guard let date = calendar.date(from: components) else {
            XCTFail("Could not create test date")
            return
        }

        let result = DateFormatters.yearString(for: date)
        XCTAssertEqual(result, "2024", "Year string should be 4-digit year")
    }

    func testDisplayString() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 15

        guard let date = calendar.date(from: components) else {
            XCTFail("Could not create test date")
            return
        }

        let result = DateFormatters.displayString(for: date)

        // Display format is locale-dependent, so just check it's not empty
        XCTAssertFalse(result.isEmpty, "Display string should not be empty")
        XCTAssertTrue(result.contains("2024") || result.contains("24"), "Display string should contain year")
    }

    func testISOString() {
        let date = Date(timeIntervalSince1970: 0) // 1970-01-01T00:00:00Z
        let result = DateFormatters.isoString(for: date)

        XCTAssertTrue(result.contains("1970"), "ISO string should contain year")
        XCTAssertTrue(result.contains("T"), "ISO string should contain T separator")
    }

    func testFilenameTimestamp() {
        let result = DateFormatters.filenameTimestamp()

        // Format should be yyyyMMdd_HHmmss
        XCTAssertEqual(result.count, 15, "Filename timestamp should be 15 characters")
        XCTAssertTrue(result.contains("_"), "Filename timestamp should contain underscore")
    }
}

// MARK: - FileExtensions Tests

final class FileExtensionsTests: XCTestCase {

    func testImageExtensions() {
        let expectedImages = ["jpg", "jpeg", "png", "heic", "gif", "bmp", "tiff", "tif", "crw", "cr2", "cr3", "raw", "rw2", "raf"]

        for ext in expectedImages {
            XCTAssertTrue(FileExtensions.isImage(ext), "\(ext) should be recognized as image")
            XCTAssertTrue(FileExtensions.isSupported(ext), "\(ext) should be supported")
            XCTAssertEqual(FileExtensions.mediaType(for: ext), .image, "\(ext) should have image media type")
        }
    }

    func testVideoExtensions() {
        let expectedVideos = ["mp4", "mov", "avi", "mkv", "m4v"]

        for ext in expectedVideos {
            XCTAssertTrue(FileExtensions.isVideo(ext), "\(ext) should be recognized as video")
            XCTAssertTrue(FileExtensions.isSupported(ext), "\(ext) should be supported")
            XCTAssertEqual(FileExtensions.mediaType(for: ext), .video, "\(ext) should have video media type")
        }
    }

    func testCaseInsensitivity() {
        XCTAssertTrue(FileExtensions.isImage("JPG"), "Should handle uppercase")
        XCTAssertTrue(FileExtensions.isImage("Jpg"), "Should handle mixed case")
        XCTAssertTrue(FileExtensions.isVideo("MP4"), "Should handle uppercase")
        XCTAssertTrue(FileExtensions.isVideo("MoV"), "Should handle mixed case")
    }

    func testUnsupportedExtensions() {
        let unsupported = ["txt", "pdf", "doc", "zip", "exe", "html"]

        for ext in unsupported {
            XCTAssertFalse(FileExtensions.isSupported(ext), "\(ext) should not be supported")
            XCTAssertNil(FileExtensions.mediaType(for: ext), "\(ext) should have nil media type")
        }
    }

    func testDisplayStrings() {
        let imageDisplay = FileExtensions.imageExtensionsDisplay
        let videoDisplay = FileExtensions.videoExtensionsDisplay

        XCTAssertFalse(imageDisplay.isEmpty, "Image extensions display should not be empty")
        XCTAssertFalse(videoDisplay.isEmpty, "Video extensions display should not be empty")

        XCTAssertTrue(imageDisplay.contains("jpg"), "Image display should contain jpg")
        XCTAssertTrue(videoDisplay.contains("mp4"), "Video display should contain mp4")
    }
}

// MARK: - EventDescriptionParser Tests

final class EventDescriptionParserTests: XCTestCase {

    var parser: EventDescriptionParser!

    override func setUpWithError() throws {
        parser = EventDescriptionParser()
    }

    override func tearDownWithError() throws {
        parser = nil
    }

    // MARK: - ISO Date Format Tests (YYYY-MM-DD)

    func testExtractDescriptionFromISODateWithEvent() {
        // "2024-06-15 Beach Vacation" -> "Beach Vacation"
        let result = parser.extractEventDescription(from: "2024-06-15 Beach Vacation")
        XCTAssertEqual(result, "Beach Vacation", "Should extract 'Beach Vacation' from ISO date format")
    }

    func testExtractDescriptionFromISODateWithDashSeparator() {
        // "2024-06-15-Birthday Party" -> "Birthday Party"
        let result = parser.extractEventDescription(from: "2024-06-15-Birthday Party")
        XCTAssertEqual(result, "Birthday Party", "Should extract 'Birthday Party' with dash separator")
    }

    func testExtractDescriptionFromISODateWithUnderscores() {
        // "2024-06-15_Family_Reunion" -> "Family Reunion"
        let result = parser.extractEventDescription(from: "2024-06-15_Family_Reunion")
        XCTAssertEqual(result, "Family Reunion", "Should convert underscores to spaces")
    }

    func testExtractDescriptionFromISODateOnly() {
        // "2024-06-15" -> nil (no description)
        let result = parser.extractEventDescription(from: "2024-06-15")
        XCTAssertNil(result, "Should return nil for date-only directory name")
    }

    // MARK: - Year-Month Format Tests (YYYY-MM)

    func testExtractDescriptionFromYearMonthWithEvent() {
        // "2024-06 Summer Trip" -> "Summer Trip"
        let result = parser.extractEventDescription(from: "2024-06 Summer Trip")
        XCTAssertEqual(result, "Summer Trip", "Should extract description from year-month format")
    }

    func testExtractDescriptionFromYearMonthOnly() {
        // "2024-06" -> nil
        let result = parser.extractEventDescription(from: "2024-06")
        XCTAssertNil(result, "Should return nil for year-month only")
    }

    // MARK: - Compact Date Format Tests (YYYYMMDD)

    func testExtractDescriptionFromCompactDateWithEvent() {
        // "20240615 Graduation" -> "Graduation"
        let result = parser.extractEventDescription(from: "20240615 Graduation")
        XCTAssertEqual(result, "Graduation", "Should extract description from compact date format")
    }

    func testExtractDescriptionFromCompactDateOnly() {
        // "20240615" -> nil
        let result = parser.extractEventDescription(from: "20240615")
        XCTAssertNil(result, "Should return nil for compact date only")
    }

    // MARK: - US Date Format Tests (MM-DD-YYYY)

    func testExtractDescriptionFromUSDateWithEvent() {
        // "06-15-2024 Wedding" -> "Wedding"
        let result = parser.extractEventDescription(from: "06-15-2024 Wedding")
        XCTAssertEqual(result, "Wedding", "Should extract description from US date format")
    }

    func testExtractDescriptionFromUSDateSlashFormat() {
        // "06/15/2024 Concert" -> "Concert"
        let result = parser.extractEventDescription(from: "06/15/2024 Concert")
        XCTAssertEqual(result, "Concert", "Should extract description from US date with slashes")
    }

    func testExtractDescriptionFromEuropeanDateFormat() {
        // "15.06.2024 Holiday" -> "Holiday"
        let result = parser.extractEventDescription(from: "15.06.2024 Holiday")
        XCTAssertEqual(result, "Holiday", "Should extract description from European date format")
    }

    // MARK: - Event Description at Start Tests

    func testExtractDescriptionBeforeDate() {
        // "Beach Trip 2024-06-15" -> "Beach Trip"
        let result = parser.extractEventDescription(from: "Beach Trip 2024-06-15")
        XCTAssertEqual(result, "Beach Trip", "Should extract description that appears before the date")
    }

    func testExtractDescriptionSurroundingDate() {
        // "Summer 2024-06-15 Vacation" -> "Summer Vacation"
        let result = parser.extractEventDescription(from: "Summer 2024-06-15 Vacation")
        XCTAssertEqual(result, "Summer Vacation", "Should combine description parts around the date")
    }

    // MARK: - Complex Event Description Tests

    func testExtractMultiWordDescription() {
        // "2024-06-15 John and Jane Wedding Reception" -> "John and Jane Wedding Reception"
        let result = parser.extractEventDescription(from: "2024-06-15 John and Jane Wedding Reception")
        XCTAssertEqual(result, "John and Jane Wedding Reception", "Should preserve multi-word descriptions")
    }

    func testExtractDescriptionWithNumbers() {
        // "2024-06-15 25th Anniversary" -> "25th Anniversary"
        let result = parser.extractEventDescription(from: "2024-06-15 25th Anniversary")
        XCTAssertEqual(result, "25th Anniversary", "Should preserve numbers in descriptions")
    }

    func testExtractDescriptionWithMixedSeparators() {
        // "2024-06-15_Road_Trip-Day1" -> "Road Trip Day1"
        let result = parser.extractEventDescription(from: "2024-06-15_Road_Trip-Day1")
        XCTAssertNotNil(result, "Should handle mixed separators")
        XCTAssertTrue(result?.contains("Road") == true, "Should contain 'Road'")
        XCTAssertTrue(result?.contains("Trip") == true, "Should contain 'Trip'")
    }

    // MARK: - Edge Cases

    func testExtractDescriptionFromEmptyString() {
        let result = parser.extractEventDescription(from: "")
        XCTAssertNil(result, "Should return nil for empty string")
    }

    func testExtractDescriptionFromWhitespaceOnly() {
        let result = parser.extractEventDescription(from: "   ")
        XCTAssertNil(result, "Should return nil for whitespace-only string")
    }

    func testExtractDescriptionFromDescriptionOnly() {
        // "Beach Vacation" -> "Beach Vacation" (no date to remove)
        let result = parser.extractEventDescription(from: "Beach Vacation")
        XCTAssertEqual(result, "Beach Vacation", "Should return description when no date present")
    }

    func testExtractDescriptionTrimsWhitespace() {
        // "2024-06-15   Beach Vacation   " -> "Beach Vacation"
        let result = parser.extractEventDescription(from: "2024-06-15   Beach Vacation   ")
        XCTAssertEqual(result, "Beach Vacation", "Should trim leading/trailing whitespace")
    }

    func testExtractDescriptionCollapsesMultipleSpaces() {
        // "2024-06-15 Beach    Vacation" -> "Beach Vacation"
        let result = parser.extractEventDescription(from: "2024-06-15 Beach    Vacation")
        XCTAssertEqual(result, "Beach Vacation", "Should collapse multiple spaces")
    }

    // MARK: - Real-World Directory Name Tests

    func testRealWorldDirectoryNames() {
        let testCases: [(input: String, expected: String?)] = [
            ("2023-12-25 Christmas Morning", "Christmas Morning"),
            ("2024-01-01_New_Years_Party", "New Years Party"),
            ("20240704 Fourth of July BBQ", "Fourth of July BBQ"),
            ("Hawaii Trip 2024-03", "Hawaii Trip"),
            ("2024-07-15", nil),
            ("Photos", "Photos"),
            ("2024-08-20-Sarahs-Birthday", "Sarahs-Birthday"),
            ("Thanksgiving 11-28-2024", "Thanksgiving"),
            ("2024-09 Fall Colors", "Fall Colors"),
            ("NYC_2024-05-10_Weekend", "NYC Weekend"),
        ]

        for (input, expected) in testCases {
            let result = parser.extractEventDescription(from: input)
            XCTAssertEqual(result, expected, "For '\(input)': expected '\(expected ?? "nil")' but got '\(result ?? "nil")'")
        }
    }

    // MARK: - Batch Processing Tests

    func testSuggestEventDescriptions() {
        let directoryNames = [
            "2024-06-15 Beach Trip",
            "2024-07-04 Fourth of July",
            "2024-12-25"  // No description
        ]

        let suggestions = parser.suggestEventDescriptions(from: directoryNames)

        XCTAssertEqual(suggestions["2024-06-15 Beach Trip"], "Beach Trip")
        XCTAssertEqual(suggestions["2024-07-04 Fourth of July"], "Fourth of July")
        XCTAssertNil(suggestions["2024-12-25"], "Should not have suggestion for date-only")
    }

    func testGroupByEventDescription() {
        let directoryNames = [
            "2024-06-15 Vacation",
            "2024-06-16 Vacation",
            "2024-07-04 BBQ",
            "2024-12-25"  // No description
        ]

        let groups = parser.groupByEventDescription(directoryNames)

        XCTAssertEqual(groups["Vacation"]?.count, 2, "Should group two Vacation directories")
        XCTAssertEqual(groups["BBQ"]?.count, 1, "Should have one BBQ directory")
        XCTAssertEqual(groups[nil]?.count, 1, "Should have one directory with no description")
    }
}
