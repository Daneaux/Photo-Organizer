import Foundation

struct ScriptGenerator {
    // MARK: - Script Generation

    /// Generates a forward (execute) script for file move operations
    func generateForwardScript(
        operations: [PlannedOperation],
        outputPath: URL
    ) throws -> URL {
        let timestamp = DateFormatters.isoString(for: Date())

        var script = """
        #!/bin/bash
        # Photo Organizer - Forward Script
        # Generated: \(timestamp)
        # Total operations: \(operations.count)
        #
        # This script moves files from their original locations to the organized destination.
        # Run the corresponding undo script to reverse these operations.

        set -e  # Exit on error

        echo "Starting photo organization..."
        echo "Total files to move: \(operations.count)"
        echo ""

        MOVED=0
        FAILED=0

        """

        for (index, operation) in operations.enumerated() {
            let source = PathUtilities.escapeForShell(operation.sourcePath)
            let dest = PathUtilities.escapeForShell(operation.destinationPath)
            let destDir = PathUtilities.escapeForShell(
                URL(fileURLWithPath: operation.destinationPath).deletingLastPathComponent().path
            )

            script += """

            # [\(index + 1)/\(operations.count)] \(operation.sourceFilename)
            if [ -f "\(source)" ]; then
                mkdir -p "\(destDir)"
                if mv "\(source)" "\(dest)"; then
                    echo "[\(index + 1)/\(operations.count)] Moved: \(operation.sourceFilename)"
                    ((MOVED++))
                else
                    echo "[\(index + 1)/\(operations.count)] FAILED: \(operation.sourceFilename)"
                    ((FAILED++))
                fi
            else
                echo "[\(index + 1)/\(operations.count)] SKIPPED (not found): \(operation.sourceFilename)"
                ((FAILED++))
            fi

            """
        }

        script += """

        echo ""
        echo "========================================="
        echo "Organization complete!"
        echo "Files moved successfully: $MOVED"
        echo "Files failed/skipped: $FAILED"
        echo "========================================="
        """

        try script.write(to: outputPath, atomically: true, encoding: .utf8)

        // Make executable
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: outputPath.path
        )

        return outputPath
    }

    /// Generates an undo script that reverses all move operations
    func generateUndoScript(
        operations: [PlannedOperation],
        outputPath: URL
    ) throws -> URL {
        let timestamp = DateFormatters.isoString(for: Date())

        var script = """
        #!/bin/bash
        # Photo Organizer - UNDO Script
        # Generated: \(timestamp)
        # Total operations: \(operations.count)
        #
        # WARNING: This script will move files BACK to their original locations.
        # Only run this if you want to reverse the organization.

        set -e  # Exit on error

        echo "Starting UNDO operation..."
        echo "This will restore \(operations.count) files to their original locations."
        echo ""
        read -p "Are you sure you want to continue? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Undo cancelled."
            exit 1
        fi
        echo ""

        RESTORED=0
        FAILED=0

        """

        // Reverse order for undo
        for (index, operation) in operations.reversed().enumerated() {
            let source = PathUtilities.escapeForShell(operation.destinationPath) // Current location
            let dest = PathUtilities.escapeForShell(operation.sourcePath)        // Original location
            let destDir = PathUtilities.escapeForShell(
                URL(fileURLWithPath: operation.sourcePath).deletingLastPathComponent().path
            )

            script += """

            # [\(index + 1)/\(operations.count)] Restoring: \(operation.sourceFilename)
            if [ -f "\(source)" ]; then
                mkdir -p "\(destDir)"
                if mv "\(source)" "\(dest)"; then
                    echo "[\(index + 1)/\(operations.count)] Restored: \(operation.sourceFilename)"
                    ((RESTORED++))
                else
                    echo "[\(index + 1)/\(operations.count)] FAILED: \(operation.sourceFilename)"
                    ((FAILED++))
                fi
            else
                echo "[\(index + 1)/\(operations.count)] SKIPPED (not found): \(operation.sourceFilename)"
                ((FAILED++))
            fi

            """
        }

        script += """

        echo ""
        echo "========================================="
        echo "Undo complete!"
        echo "Files restored successfully: $RESTORED"
        echo "Files failed/skipped: $FAILED"
        echo "========================================="
        """

        try script.write(to: outputPath, atomically: true, encoding: .utf8)

        // Make executable
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: outputPath.path
        )

        return outputPath
    }

    /// Generates a duplicate log file
    func generateDuplicateLog(
        operations: [PlannedOperation],
        outputPath: URL
    ) throws -> URL {
        let duplicates = operations.filter { $0.isDuplicate }

        guard !duplicates.isEmpty else {
            // No duplicates, don't create the file
            return outputPath
        }

        let timestamp = DateFormatters.isoString(for: Date())

        var log = """
        Photo Organizer - Duplicate Files Log
        Generated: \(timestamp)
        Total duplicates renamed: \(duplicates.count)

        The following files were renamed to avoid conflicts:

        """

        for dup in duplicates {
            log += """

            Original filename: \(URL(fileURLWithPath: dup.sourcePath).lastPathComponent)
            Renamed to: \(dup.destinationFilename)
            Original destination: \(dup.originalDestinationPath ?? "N/A")
            Final destination: \(dup.destinationPath)

            """
        }

        try log.write(to: outputPath, atomically: true, encoding: .utf8)

        return outputPath
    }

    // MARK: - Script Paths

    /// Generates standard script file paths for a session
    func scriptPaths(logsDirectory: URL, timestamp: String) -> (forward: URL, undo: URL, duplicateLog: URL) {
        let forward = logsDirectory.appendingPathComponent("organize_\(timestamp).sh")
        let undo = logsDirectory.appendingPathComponent("undo_\(timestamp).sh")
        let duplicateLog = logsDirectory.appendingPathComponent("duplicates_\(timestamp).txt")

        return (forward, undo, duplicateLog)
    }
}
