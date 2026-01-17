import Foundation

struct DestinationPathBuilder {
    let destinationRoot: URL

    // MARK: - Path Building

    /// Builds the destination path for a file based on its date and optional event description
    func buildDestinationPath(
        filename: String,
        date: Date,
        eventDescription: String?
    ) -> URL {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // Build folder name: "MM-DD" or "MM-DD Event Description"
        var folderName = String(format: "%02d-%02d", month, day)

        if let event = eventDescription?.trimmingCharacters(in: .whitespaces),
           !event.isEmpty {
            // Sanitize the event description for use in path
            let sanitizedEvent = PathUtilities.sanitizeForPath(event)
            folderName += " " + sanitizedEvent
        }

        // Build full path: destination/YYYY/MM-DD [Event]/filename
        return destinationRoot
            .appendingPathComponent(String(year))
            .appendingPathComponent(folderName)
            .appendingPathComponent(filename)
    }

    /// Builds just the directory portion of the destination path (without filename)
    func buildDestinationDirectory(
        date: Date,
        eventDescription: String?
    ) -> URL {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        var folderName = String(format: "%02d-%02d", month, day)

        if let event = eventDescription?.trimmingCharacters(in: .whitespaces),
           !event.isEmpty {
            let sanitizedEvent = PathUtilities.sanitizeForPath(event)
            folderName += " " + sanitizedEvent
        }

        return destinationRoot
            .appendingPathComponent(String(year))
            .appendingPathComponent(folderName)
    }

    /// Returns a human-readable description of the destination structure
    func describeDestination(date: Date, eventDescription: String?) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        var folderName = String(format: "%02d-%02d", month, day)

        if let event = eventDescription?.trimmingCharacters(in: .whitespaces),
           !event.isEmpty {
            folderName += " " + event
        }

        return "\(year)/\(folderName)"
    }
}
