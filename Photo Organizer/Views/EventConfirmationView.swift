import SwiftUI
import AppKit

struct EventConfirmationView: View {
    @Bindable var appState: AppState

    // Selection state: tracks which directories should use their suggested event
    @State private var selectedDirectoryIDs: Set<UUID> = []
    // Editable event descriptions (keyed by directory ID)
    @State private var editedDescriptions: [UUID: String] = [:]
    // Track last clicked index for shift-select
    @State private var lastClickedIndex: Int?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Event Descriptions")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Select which folders should include event descriptions. Unselected folders will use date-only names.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack {
                    Text("\(appState.directoriesNeedingEventConfirmation.count) folders with suggested descriptions")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(selectedDirectoryIDs.count) selected")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal)
            }
            .padding()

            Divider()

            // Selection controls
            HStack(spacing: 16) {
                Button("Select All") {
                    selectAll()
                }
                .buttonStyle(.borderless)

                Button("Deselect All") {
                    deselectAll()
                }
                .buttonStyle(.borderless)

                Spacer()

                Text("Tip: Hold Shift and click to select a range")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Table
            if appState.directoriesNeedingEventConfirmation.isEmpty {
                Spacer()
                Text("No folders with suggested event descriptions")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                eventTable
            }

            Divider()

            // Action buttons
            HStack {
                Button {
                    appState.reset()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }

                Spacer()

                Button("Skip All (No Descriptions)") {
                    applySelections(useDescriptions: false)
                }
                .foregroundStyle(.secondary)

                Button("Apply Selections") {
                    applySelections(useDescriptions: true)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onAppear {
            initializeState()
        }
    }

    private var eventTable: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    // Checkbox column header
                    Toggle("", isOn: Binding(
                        get: { selectedDirectoryIDs.count == appState.directoriesNeedingEventConfirmation.count },
                        set: { newValue in
                            if newValue {
                                selectAll()
                            } else {
                                deselectAll()
                            }
                        }
                    ))
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                    .frame(width: 40)

                    Text("Source Folder")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 150, alignment: .leading)

                    Text("Event Description")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 150, alignment: .leading)

                    Text("Destination Preview")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 150, alignment: .leading)

                    Text("Files")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1))

                // Data rows
                ForEach(Array(appState.directoriesNeedingEventConfirmation.enumerated()), id: \.element.id) { index, group in
                    EventTableRow(
                        group: group,
                        isSelected: selectedDirectoryIDs.contains(group.id),
                        editedDescription: binding(for: group),
                        onToggle: { handleToggle(at: index, group: group) },
                        onShiftClick: { handleShiftClick(at: index) }
                    )

                    if index < appState.directoriesNeedingEventConfirmation.count - 1 {
                        Divider()
                            .padding(.leading, 40)
                    }
                }
            }
        }
    }

    // MARK: - State Management

    private func initializeState() {
        // By default, select all directories (use their suggested events)
        selectedDirectoryIDs = Set(appState.directoriesNeedingEventConfirmation.map { $0.id })

        // Initialize edited descriptions with suggested events
        for group in appState.directoriesNeedingEventConfirmation {
            editedDescriptions[group.id] = group.suggestedEvent ?? ""
        }
    }

    private func binding(for group: DirectoryEventGroup) -> Binding<String> {
        Binding(
            get: { editedDescriptions[group.id] ?? group.suggestedEvent ?? "" },
            set: { editedDescriptions[group.id] = $0 }
        )
    }

    // MARK: - Selection

    private func selectAll() {
        selectedDirectoryIDs = Set(appState.directoriesNeedingEventConfirmation.map { $0.id })
        lastClickedIndex = nil
    }

    private func deselectAll() {
        selectedDirectoryIDs.removeAll()
        lastClickedIndex = nil
    }

    private func handleToggle(at index: Int, group: DirectoryEventGroup) {
        if selectedDirectoryIDs.contains(group.id) {
            selectedDirectoryIDs.remove(group.id)
        } else {
            selectedDirectoryIDs.insert(group.id)
        }
        lastClickedIndex = index
    }

    private func handleShiftClick(at index: Int) {
        guard let lastIndex = lastClickedIndex else {
            // No previous click, just toggle this one
            let group = appState.directoriesNeedingEventConfirmation[index]
            handleToggle(at: index, group: group)
            return
        }

        // Determine range
        let start = min(lastIndex, index)
        let end = max(lastIndex, index)

        // Get the target state (opposite of current item)
        let currentGroup = appState.directoriesNeedingEventConfirmation[index]
        let targetState = !selectedDirectoryIDs.contains(currentGroup.id)

        // Apply to range
        for i in start...end {
            let group = appState.directoriesNeedingEventConfirmation[i]
            if targetState {
                selectedDirectoryIDs.insert(group.id)
            } else {
                selectedDirectoryIDs.remove(group.id)
            }
        }

        lastClickedIndex = index
    }

    // MARK: - Actions

    private func applySelections(useDescriptions: Bool) {
        for group in appState.directoriesNeedingEventConfirmation {
            let shouldUseDescription = useDescriptions && selectedDirectoryIDs.contains(group.id)
            let description: String?

            if shouldUseDescription {
                let edited = editedDescriptions[group.id] ?? group.suggestedEvent ?? ""
                description = edited.isEmpty ? nil : edited
            } else {
                description = nil
            }

            // Apply to files
            for file in group.files {
                file.eventDescription = description
                file.eventConfirmed = true
            }
        }

        // Move to preview
        appState.finishEventConfirmation()
    }
}

// MARK: - Table Row

struct EventTableRow: View {
    let group: DirectoryEventGroup
    let isSelected: Bool
    @Binding var editedDescription: String
    let onToggle: () -> Void
    let onShiftClick: () -> Void

    @State private var isHovered = false

    private var destinationPreview: String {
        guard let date = group.files.first?.detectedDate else { return "—" }

        let year = Calendar.current.component(.year, from: date)
        let month = Calendar.current.component(.month, from: date)
        let day = Calendar.current.component(.day, from: date)

        var folderName = String(format: "%02d-%02d", month, day)
        if isSelected && !editedDescription.isEmpty {
            folderName += " " + editedDescription
        }

        return "\(year)/\(folderName)/"
    }

    var body: some View {
        HStack(spacing: 0) {
            // Checkbox
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { _ in
                    if NSEvent.modifierFlags.contains(.shift) {
                        onShiftClick()
                    } else {
                        onToggle()
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
            .frame(width: 40)

            // Source folder name
            VStack(alignment: .leading, spacing: 2) {
                Text(group.directoryName)
                    .font(.system(.body))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(group.dateRange)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(minWidth: 150, alignment: .leading)

            // Event description (editable)
            TextField("No description", text: $editedDescription)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 150)
                .disabled(!isSelected)
                .opacity(isSelected ? 1.0 : 0.5)

            // Destination preview
            Text(destinationPreview)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(minWidth: 150, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.middle)

            // File count
            Text("\(group.fileCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color.secondary.opacity(0.05) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#Preview {
    EventConfirmationView(appState: AppState())
        .frame(width: 800, height: 500)
}
