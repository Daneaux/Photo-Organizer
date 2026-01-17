import SwiftUI

struct ExecutionProgressView: View {
    @Bindable var appState: AppState

    var progressPercent: Double {
        guard appState.executionProgress.total > 0 else { return 0 }
        return Double(appState.executionProgress.current) / Double(appState.executionProgress.total)
    }

    var isPaused: Bool {
        if case .paused = appState.workflowState { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Progress indicator
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: progressPercent)
                        .stroke(
                            isPaused ? Color.orange : Color.accentColor,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: progressPercent)

                    VStack(spacing: 4) {
                        Text("\(Int(progressPercent * 100))%")
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        Text("\(appState.executionProgress.current) of \(appState.executionProgress.total)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 150, height: 150)

                if isPaused {
                    Label("Paused", systemImage: "pause.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                } else {
                    Text("Organizing Files...")
                        .font(.headline)
                }
            }

            // Current file
            if !appState.executionProgress.currentFile.isEmpty {
                VStack(spacing: 4) {
                    Text("Current file:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(appState.executionProgress.currentFile)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 400)
                }
            }

            // Statistics
            HStack(spacing: 40) {
                StatItem(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    value: appState.completedOperations,
                    label: "Completed"
                )

                StatItem(
                    icon: "xmark.circle.fill",
                    iconColor: .red,
                    value: appState.failedOperations,
                    label: "Failed"
                )
            }

            Spacer()

            // Control buttons
            HStack(spacing: 16) {
                Button {
                    Task {
                        await appState.cancelExecution()
                    }
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
                .buttonStyle(.bordered)

                if isPaused {
                    Button {
                        Task {
                            await appState.resumeExecution()
                        }
                    } label: {
                        Label("Resume", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        Task {
                            await appState.pauseExecution()
                        }
                    } label: {
                        Label("Pause", systemImage: "pause.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer()
        }
        .padding()
    }
}

struct StatItem: View {
    let icon: String
    let iconColor: Color
    let value: Int
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.title2)

            VStack(alignment: .leading, spacing: 0) {
                Text("\(value)")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ExecutionProgressView(appState: {
        let state = AppState()
        return state
    }())
    .frame(width: 600, height: 500)
}
