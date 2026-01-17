import SwiftUI

struct PreviewView: View {
    @Bindable var appState: AppState
    @State private var selectedOperations: Set<UUID> = []
    @State private var filterType: FilterType = .all
    @State private var sortOrder: SortOrder = .sourcePath

    enum FilterType: String, CaseIterable {
        case all = "All"
        case duplicates = "Duplicates"
        case images = "Images"
        case videos = "Videos"
    }

    enum SortOrder: String, CaseIterable {
        case sourcePath = "Source"
        case date = "Date"
        case destinationPath = "Destination"
    }

    var filteredOperations: [PlannedOperation] {
        var result = appState.plannedOperations

        switch filterType {
        case .all:
            break
        case .duplicates:
            result = result.filter { $0.isDuplicate }
        case .images:
            result = result.filter { $0.mediaFile?.mediaType == .image }
        case .videos:
            result = result.filter { $0.mediaFile?.mediaType == .video }
        }

        switch sortOrder {
        case .sourcePath:
            result.sort { $0.sourcePath < $1.sourcePath }
        case .date:
            result.sort {
                ($0.mediaFile?.detectedDate ?? .distantPast) < ($1.mediaFile?.detectedDate ?? .distantPast)
            }
        case .destinationPath:
            result.sort { $0.destinationPath < $1.destinationPath }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Preview Operations")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Review the planned file moves before executing.")
                    .foregroundStyle(.secondary)
            }
            .padding()

            // Summary bar
            HStack(spacing: 20) {
                SummaryItem(
                    icon: "photo.on.rectangle",
                    value: "\(appState.plannedOperations.count)",
                    label: "Total Files"
                )

                SummaryItem(
                    icon: "doc.on.doc",
                    value: "\(appState.duplicateCount)",
                    label: "Duplicates",
                    highlight: appState.duplicateCount > 0
                )

                Spacer()

                // Filters
                Picker("Filter", selection: $filterType) {
                    ForEach(FilterType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)

                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .frame(width: 120)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.05))

            Divider()

            // Operations table
            Table(filteredOperations, selection: $selectedOperations) {
                TableColumn("Type") { operation in
                    Image(systemName: operation.mediaFile?.mediaType == .video ? "video.fill" : "photo.fill")
                        .foregroundStyle(operation.mediaFile?.mediaType == .video ? .purple : .blue)
                }
                .width(40)

                TableColumn("Source Path") { operation in
                    Text(operation.sourcePath)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                        .truncationMode(.head)
                        .help(operation.sourcePath)
                }
                .width(min: 250, ideal: 350)

                TableColumn("Date") { operation in
                    if let date = operation.mediaFile?.detectedDate {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(date, style: .date)
                                .font(.caption)
                            Text(operation.mediaFile?.displayDateSource ?? "")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("No date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .width(min: 90, ideal: 110)

                TableColumn("Destination Path") { operation in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(operation.destinationPath)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(2)
                            .truncationMode(.head)
                            .help(operation.destinationPath)

                        if operation.isDuplicate {
                            Text("Renamed to avoid conflict")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .width(min: 250, ideal: 350)

                TableColumn("Status") { operation in
                    StatusBadge(operation: operation)
                }
                .width(80)
            }

            Divider()

            // Action buttons
            HStack {
                Button("Back to Setup") {
                    appState.reset()
                }

                Spacer()

                if appState.duplicateCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                        Text("\(appState.duplicateCount) files will be renamed to avoid conflicts")
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                }

                Button("Organize \(appState.plannedOperations.count) Files") {
                    Task {
                        await appState.executeOperations()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.plannedOperations.isEmpty)
            }
            .padding()
        }
    }
}

struct SummaryItem: View {
    let icon: String
    let value: String
    let label: String
    var highlight: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(highlight ? .orange : .secondary)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.headline)
                    .foregroundStyle(highlight ? .orange : .primary)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct StatusBadge: View {
    let operation: PlannedOperation

    var body: some View {
        HStack(spacing: 4) {
            if operation.isDuplicate {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Rename")
                    .font(.caption)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Ready")
                    .font(.caption)
            }
        }
    }
}

#Preview {
    PreviewView(appState: AppState())
        .frame(width: 1100, height: 600)
}
