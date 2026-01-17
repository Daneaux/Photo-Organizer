import SwiftUI
import AppKit

struct FolderSelectionView: View {
    @Bindable var appState: AppState

    // Track last clicked index for shift-select
    @State private var lastClickedID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Selection controls
            controlsSection

            Divider()

            // Folder tree or progress
            if appState.folderEnumerationProgress.isComplete {
                folderTreeSection
            } else {
                enumerationProgressSection
            }

            Divider()

            // Action buttons
            actionButtonsSection
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Select Folders to Process")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Choose which folders should be scanned for photos and videos.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let root = appState.folderHierarchy {
                HStack {
                    Text("\(root.recursiveFileCount) media files in \(appState.folderEnumerationProgress.foldersScanned) folders")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(root.countSelectedFiles()) files selected")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }

    // MARK: - Controls

    private var controlsSection: some View {
        HStack(spacing: 16) {
            Button("Select All") {
                appState.folderHierarchy?.setSelectedRecursively(true)
            }
            .buttonStyle(.borderless)

            Button("Deselect All") {
                appState.folderHierarchy?.setSelectedRecursively(false)
            }
            .buttonStyle(.borderless)

            Button("Expand All") {
                appState.folderHierarchy?.setExpandedRecursively(true)
            }
            .buttonStyle(.borderless)

            Button("Collapse All") {
                appState.folderHierarchy?.setExpandedRecursively(false)
            }
            .buttonStyle(.borderless)

            Spacer()

            Text("Tip: Hold Shift and click to select a range")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Folder Tree

    private var folderTreeSection: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let root = appState.folderHierarchy {
                    // Root folder row
                    FolderTreeRow(
                        node: root,
                        isRoot: true,
                        onToggle: { handleToggle($0) },
                        onShiftClick: { handleShiftClick($0) }
                    )

                    // Child folders (visible based on expansion state)
                    ForEach(root.flattenVisible()) { node in
                        FolderTreeRow(
                            node: node,
                            isRoot: false,
                            onToggle: { handleToggle($0) },
                            onShiftClick: { handleShiftClick($0) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Progress Section

    private var enumerationProgressSection: some View {
        VStack(spacing: 16) {
            Spacer()

            ProgressView()
                .scaleEffect(1.2)

            Text("Scanning folder structure...")
                .font(.headline)

            VStack(spacing: 8) {
                Text("\(appState.folderEnumerationProgress.foldersScanned) folders scanned")
                Text("\(appState.folderEnumerationProgress.totalMediaFiles) media files found")
                    .foregroundStyle(.blue)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !appState.folderEnumerationProgress.currentFolder.isEmpty {
                Text(appState.folderEnumerationProgress.currentFolder)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        HStack {
            Button {
                appState.backToSetup()
            } label: {
                Label("Back", systemImage: "chevron.left")
            }

            Spacer()

            Button("Continue to Scan") {
                Task {
                    await appState.proceedToScan()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.folderHierarchy?.countSelectedFiles() == 0)
        }
        .padding()
    }

    // MARK: - Selection Handling

    private func handleToggle(_ node: FolderNode) {
        node.isSelected.toggle()
        // Propagate to children
        for child in node.children {
            child.setSelectedRecursively(node.isSelected)
        }
        lastClickedID = node.id
    }

    private func handleShiftClick(_ node: FolderNode) {
        guard let lastID = lastClickedID,
              let root = appState.folderHierarchy else {
            handleToggle(node)
            return
        }

        // Flatten tree including root for index calculation
        let allNodes = [root] + root.flattenAll()

        guard let lastIndex = allNodes.firstIndex(where: { $0.id == lastID }),
              let currentIndex = allNodes.firstIndex(where: { $0.id == node.id }) else {
            handleToggle(node)
            return
        }

        let start = min(lastIndex, currentIndex)
        let end = max(lastIndex, currentIndex)
        let targetState = !node.isSelected

        for i in start...end {
            allNodes[i].isSelected = targetState
        }

        lastClickedID = node.id
    }
}

// MARK: - Folder Tree Row

struct FolderTreeRow: View {
    @Bindable var node: FolderNode
    let isRoot: Bool
    let onToggle: (FolderNode) -> Void
    let onShiftClick: (FolderNode) -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            // Indentation
            if !isRoot {
                Color.clear
                    .frame(width: CGFloat(node.depth) * 20)
            }

            // Expand/collapse chevron
            if node.hasChildren {
                Button {
                    node.isExpanded.toggle()
                } label: {
                    Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 20)
            }

            // Checkbox
            Toggle("", isOn: Binding(
                get: { node.isSelected },
                set: { _ in
                    if NSEvent.modifierFlags.contains(.shift) {
                        onShiftClick(node)
                    } else {
                        onToggle(node)
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
            .frame(width: 24)

            // Folder icon
            Image(systemName: isRoot ? "folder.fill" : "folder")
                .foregroundStyle(node.isSelected ? Color.accentColor : .secondary)
                .frame(width: 24)

            // Folder name
            Text(node.name)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(node.isSelected ? .primary : .secondary)

            Spacer()

            // File count badge
            if node.recursiveFileCount > 0 {
                HStack(spacing: 4) {
                    if node.directFileCount > 0 {
                        Text("\(node.directFileCount)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(node.isSelected ? .blue : .secondary)
                    }
                    if node.hasChildren && node.recursiveFileCount != node.directFileCount {
                        Text("(\(node.recursiveFileCount) total)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isHovered ? Color.secondary.opacity(0.05) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#Preview {
    FolderSelectionView(appState: AppState())
        .frame(width: 700, height: 500)
}
