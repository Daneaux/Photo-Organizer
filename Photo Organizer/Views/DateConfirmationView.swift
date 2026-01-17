import SwiftUI

struct DateConfirmationView: View {
    @Bindable var appState: AppState
    @State private var selectedDate = Date()

    var currentGroup: DirectoryDateGroup? {
        guard appState.currentDateConfirmationIndex < appState.directoriesNeedingDateConfirmation.count else {
            return nil
        }
        return appState.directoriesNeedingDateConfirmation[appState.currentDateConfirmationIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Date Confirmation Required")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Some files don't have date information in their metadata.")
                    .foregroundStyle(.secondary)

                ProgressIndicator(
                    current: appState.currentDateConfirmationIndex + 1,
                    total: appState.directoriesNeedingDateConfirmation.count
                )
            }
            .padding()

            Divider()

            if let group = currentGroup {
                // Directory info
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(Color.accentColor)
                        Text(group.directoryName)
                            .font(.headline)
                        Spacer()
                        Text("\(group.fileCount) files")
                            .foregroundStyle(.secondary)
                    }

                    // Sample files
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sample files:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(group.sampleFilenames, id: \.self) { filename in
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                                Text(filename)
                                    .font(.caption)
                            }
                        }

                        if group.fileCount > 5 {
                            Text("... and \(group.fileCount - 5) more")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .padding()

                Spacer()

                // Date picker
                VStack(spacing: 16) {
                    Text("Select the date for these files:")
                        .font(.headline)

                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .frame(maxWidth: 300)
                    .onAppear {
                        if let suggested = group.suggestedDate {
                            selectedDate = suggested
                        }
                    }

                    if group.suggestedDate != nil {
                        Text("Date suggested from folder name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                Divider()

                // Action buttons
                HStack {
                    Button("Skip These Files") {
                        appState.skipDateConfirmation(for: group)
                    }
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button("Apply Date") {
                        appState.confirmDate(selectedDate, for: group)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
}

struct ProgressIndicator: View {
    let current: Int
    let total: Int

    private var safeProgress: Double {
        guard total > 0 else { return 0 }
        return min(Double(current), Double(total))
    }

    private var safeTotal: Double {
        max(Double(total), 1)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("Step \(current) of \(total)")
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(value: safeProgress, total: safeTotal)
                .frame(width: 100)
        }
    }
}

#Preview {
    DateConfirmationView(appState: AppState())
        .frame(width: 600, height: 700)
}
