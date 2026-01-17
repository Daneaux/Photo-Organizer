import SwiftUI
import AppKit

struct CompletionView: View {
    @Bindable var appState: AppState

    var hasErrors: Bool {
        appState.failedOperations > 0
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success/Warning icon
            Image(systemName: hasErrors ? "checkmark.circle.trianglebadge.exclamationmark" : "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(hasErrors ? .orange : .green)

            // Title
            Text(hasErrors ? "Organization Complete with Warnings" : "Organization Complete!")
                .font(.title)
                .fontWeight(.bold)

            // Summary
            VStack(spacing: 12) {
                HStack(spacing: 40) {
                    CompletionStat(
                        icon: "checkmark.circle.fill",
                        iconColor: .green,
                        value: appState.completedOperations,
                        label: "Files Moved"
                    )

                    if appState.failedOperations > 0 {
                        CompletionStat(
                            icon: "xmark.circle.fill",
                            iconColor: .red,
                            value: appState.failedOperations,
                            label: "Failed"
                        )
                    }

                    if appState.duplicateCount > 0 {
                        CompletionStat(
                            icon: "doc.on.doc.fill",
                            iconColor: .orange,
                            value: appState.duplicateCount,
                            label: "Renamed"
                        )
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

            // Error details
            if !appState.operationErrors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Failed Operations:")
                        .font(.headline)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(appState.operationErrors.prefix(10), id: \.filename) { error in
                                HStack {
                                    Image(systemName: "xmark.circle")
                                        .foregroundStyle(.red)
                                    Text(error.filename)
                                        .fontWeight(.medium)
                                    Text("- \(error.error)")
                                        .foregroundStyle(.secondary)
                                }
                                .font(.caption)
                            }

                            if appState.operationErrors.count > 10 {
                                Text("... and \(appState.operationErrors.count - 10) more")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
                .padding()
                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: 500)
            }

            Spacer()

            // Scripts info
            if appState.undoScriptPath != nil || appState.forwardScriptPath != nil {
                VStack(spacing: 12) {
                    Text("Scripts Generated")
                        .font(.headline)

                    Text("Undo and forward scripts have been saved to:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let logsDir = appState.logsDirectory {
                        Button {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: logsDir.path)
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                Text(logsDir.path)
                                    .font(.system(.caption, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        .buttonStyle(.link)
                    }

                    Text("Run the undo script to restore files to their original locations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            // Action buttons
            HStack(spacing: 16) {
                if let destDir = appState.destinationDirectory {
                    Button {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: destDir.path)
                    } label: {
                        Label("Open Destination", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                }

                Button("Organize More Photos") {
                    appState.reset()
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
    }
}

struct CompletionStat: View {
    let icon: String
    let iconColor: Color
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    CompletionView(appState: {
        let state = AppState()
        return state
    }())
    .frame(width: 700, height: 600)
}
