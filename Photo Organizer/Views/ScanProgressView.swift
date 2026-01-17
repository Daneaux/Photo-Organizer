import SwiftUI

struct ScanProgressView: View {
    let progress: DirectoryScanner.ScanProgress

    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    private var phaseTitle: String {
        switch progress.phase {
        case .discovering:
            return "Discovering Files..."
        case .extractingMetadata:
            return "Extracting Metadata..."
        }
    }

    private var phaseIcon: String {
        switch progress.phase {
        case .discovering:
            return "magnifyingglass"
        case .extractingMetadata:
            return "doc.text.magnifyingglass"
        }
    }

    private var metadataProgress: Double {
        guard progress.totalFilesToProcess > 0 else { return 0 }
        return Double(progress.filesProcessed) / Double(progress.totalFilesToProcess)
    }

    private var timeSinceLastUpdate: TimeInterval {
        Date().timeIntervalSince(progress.lastUpdateTime)
    }

    private var isStuck: Bool {
        timeSinceLastUpdate > 10 // Consider stuck if no update for 10 seconds
    }

    var body: some View {
        VStack(spacing: 16) {
            // Phase indicator with animated icon
            HStack(spacing: 8) {
                Image(systemName: phaseIcon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, isActive: true)

                Text(phaseTitle)
                    .font(.headline)
            }

            // Progress indicator
            switch progress.phase {
            case .discovering:
                discoveringPhaseView
            case .extractingMetadata:
                extractingPhaseView
            }

            // Current activity indicator
            currentActivityView

            // Stuck warning
            if isStuck {
                stuckWarningView
            }

            // Elapsed time
            Text("Elapsed: \(formattedElapsedTime)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private var discoveringPhaseView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(progress.directoriesScanned)")
                        .font(.title2.monospacedDigit())
                        .fontWeight(.semibold)
                    Text("Folders")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(progress.filesFound)")
                        .font(.title2.monospacedDigit())
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    Text("Media Files")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var extractingPhaseView: some View {
        VStack(spacing: 12) {
            // Progress bar with percentage
            VStack(spacing: 4) {
                ProgressView(value: metadataProgress)
                    .progressViewStyle(.linear)

                HStack {
                    Text("\(progress.filesProcessed) of \(progress.totalFilesToProcess)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(metadataProgress * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            // Stats row
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(progress.filesProcessed)")
                        .font(.title3.monospacedDigit())
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                    Text("Processed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(progress.totalFilesToProcess - progress.filesProcessed)")
                        .font(.title3.monospacedDigit())
                        .fontWeight(.semibold)
                    Text("Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if progress.skippedFiles > 0 {
                    VStack(spacing: 4) {
                        Text("\(progress.skippedFiles)")
                            .font(.title3.monospacedDigit())
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                        Text("Skipped")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var currentActivityView: some View {
        VStack(spacing: 4) {
            switch progress.phase {
            case .discovering:
                if !progress.currentDirectory.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(progress.currentDirectory)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    if !progress.currentDirectoryPath.isEmpty {
                        Text(progress.currentDirectoryPath)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

            case .extractingMetadata:
                if !progress.currentFile.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "doc")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(progress.currentFile)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    private var stuckWarningView: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("Processing may be stuck (no update for \(Int(timeSinceLastUpdate))s)")
                .font(.caption)
                .foregroundStyle(.orange)
        }
        .padding(8)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
    }

    private var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }

    private func startTimer() {
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview("Discovering Phase") {
    ScanProgressView(
        progress: DirectoryScanner.ScanProgress(
            phase: .discovering,
            directoriesScanned: 42,
            filesFound: 1234,
            currentDirectory: "2023-06-15 Beach Vacation",
            currentDirectoryPath: "/Users/photos/2023-06-15 Beach Vacation",
            lastUpdateTime: Date()
        )
    )
    .padding()
    .frame(width: 400)
}

#Preview("Extracting Phase") {
    ScanProgressView(
        progress: DirectoryScanner.ScanProgress(
            phase: .extractingMetadata,
            directoriesScanned: 100,
            filesFound: 5000,
            currentDirectory: "",
            currentDirectoryPath: "",
            filesProcessed: 2500,
            totalFilesToProcess: 5000,
            currentFile: "IMG_2307.JPG",
            lastUpdateTime: Date()
        )
    )
    .padding()
    .frame(width: 400)
}

#Preview("Stuck Warning") {
    ScanProgressView(
        progress: DirectoryScanner.ScanProgress(
            phase: .extractingMetadata,
            directoriesScanned: 100,
            filesFound: 5000,
            filesProcessed: 2500,
            totalFilesToProcess: 5000,
            currentFile: "problem_file.RAF",
            lastUpdateTime: Date().addingTimeInterval(-15)
        )
    )
    .padding()
    .frame(width: 400)
}
