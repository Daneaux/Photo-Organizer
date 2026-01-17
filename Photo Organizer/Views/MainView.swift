import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appState = AppState()

    var body: some View {
        Group {
            switch appState.workflowState {
            case .setup:
                SetupView(appState: appState)

            case .scanning:
                ScanningView(appState: appState)

            case .dateConfirmation:
                DateConfirmationView(appState: appState)

            case .eventConfirmation:
                EventConfirmationView(appState: appState)

            case .preview:
                PreviewView(appState: appState)

            case .executing, .paused:
                ExecutionProgressView(appState: appState)

            case .completed:
                CompletionView(appState: appState)

            case .error(let message):
                ErrorView(message: message, appState: appState)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

// MARK: - Setup View

struct SetupView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)

                Text("Photo Organizer")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Organize your photos by date into a clean folder structure")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

            Spacer()

            // Directory Selection
            HStack(spacing: 20) {
                DirectoryDropZone(
                    title: "Source Folder",
                    selectedURL: appState.sourceDirectory,
                    onSelect: { appState.selectSourceDirectory() }
                )

                Image(systemName: "arrow.right")
                    .font(.title)
                    .foregroundStyle(.secondary)

                DirectoryDropZone(
                    title: "Destination Folder",
                    selectedURL: appState.destinationDirectory,
                    onSelect: { appState.selectDestinationDirectory() }
                )
            }
            .padding(.horizontal, 40)

            Spacer()

            // Action Button
            Button {
                Task {
                    await appState.startScan()
                }
            } label: {
                Label("Scan for Photos", systemImage: "magnifyingglass")
                    .frame(minWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!appState.canStartScan)

            // Help text
            if !appState.canStartScan {
                Text("Select both source and destination folders to continue")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Scanning View

struct ScanningView: View {
    @Bindable var appState: AppState
    @State private var showCancelConfirmation = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ScanProgressView(progress: appState.scanProgress)
                .frame(maxWidth: 400)

            Text("Please wait while scanning your photos...")
                .foregroundStyle(.secondary)

            Button(role: .cancel) {
                showCancelConfirmation = true
            } label: {
                Label("Cancel", systemImage: "xmark.circle")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .confirmationDialog(
            "Cancel Scanning?",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel Scan", role: .destructive) {
                Task {
                    await appState.cancelScan()
                }
            }
            Button("Continue Scanning", role: .cancel) {}
        } message: {
            Text("All progress will be lost and you'll return to the main screen.")
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button("Start Over") {
                appState.reset()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    MainView()
        .modelContainer(for: [MediaFile.self, PlannedOperation.self, OrganizeSession.self])
}
