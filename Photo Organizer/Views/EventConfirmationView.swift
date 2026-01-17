import SwiftUI

struct EventConfirmationView: View {
    @Bindable var appState: AppState
    @State private var eventDescription = ""

    var currentGroup: DirectoryEventGroup? {
        guard appState.currentEventConfirmationIndex < appState.directoriesNeedingEventConfirmation.count else {
            return nil
        }
        return appState.directoriesNeedingEventConfirmation[appState.currentEventConfirmationIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Event Description")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Add optional event names to make your folders more descriptive.")
                    .foregroundStyle(.secondary)

                ProgressIndicator(
                    current: appState.currentEventConfirmationIndex + 1,
                    total: appState.directoriesNeedingEventConfirmation.count
                )
            }
            .padding()

            Divider()

            if let group = currentGroup {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Directory info
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(Color.accentColor)
                                Text(group.directoryName)
                                    .font(.headline)
                            }

                            HStack(spacing: 16) {
                                Label("\(group.fileCount) files", systemImage: "photo.on.rectangle")
                                Label(group.dateRange, systemImage: "calendar")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        // Preview of destination
                        if let date = group.files.first?.detectedDate {
                            DestinationPreview(
                                date: date,
                                eventDescription: eventDescription.isEmpty ? nil : eventDescription
                            )
                        }

                        // Event description input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Description (optional)")
                                .font(.headline)

                            TextField("e.g., Beach Vacation, Birthday Party", text: $eventDescription)
                                .textFieldStyle(.roundedBorder)

                            if group.suggestedEvent != nil {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(.yellow)
                                    Text("Suggested from folder name")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                }

                Divider()

                // Action buttons
                HStack {
                    Button("Skip (No Description)") {
                        appState.skipEventConfirmation(for: group)
                    }
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button("Apply to All Remaining") {
                        // Apply current description to all remaining
                        for i in appState.currentEventConfirmationIndex..<appState.directoriesNeedingEventConfirmation.count {
                            let g = appState.directoriesNeedingEventConfirmation[i]
                            appState.confirmEvent(eventDescription.isEmpty ? nil : eventDescription, for: g)
                        }
                    }
                    .disabled(appState.directoriesNeedingEventConfirmation.count - appState.currentEventConfirmationIndex <= 1)

                    Button("Apply") {
                        appState.confirmEvent(eventDescription.isEmpty ? nil : eventDescription, for: group)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .onAppear {
            // Initialize with current group's suggested event
            eventDescription = currentGroup?.suggestedEvent ?? ""
        }
        .onChange(of: appState.currentEventConfirmationIndex) { _, _ in
            // Update description when moving to next directory
            eventDescription = currentGroup?.suggestedEvent ?? ""
        }
    }
}

struct DestinationPreview: View {
    let date: Date
    let eventDescription: String?

    var previewPath: String {
        let year = Calendar.current.component(.year, from: date)
        let month = Calendar.current.component(.month, from: date)
        let day = Calendar.current.component(.day, from: date)

        var folderName = String(format: "%02d-%02d", month, day)
        if let event = eventDescription, !event.isEmpty {
            folderName += " " + event
        }

        return "\(year)/\(folderName)/"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Destination Preview")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(Color.accentColor)
                Text(previewPath)
                    .font(.system(.body, design: .monospaced))
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
        }
    }
}

#Preview {
    EventConfirmationView(appState: AppState())
        .frame(width: 600, height: 500)
}
