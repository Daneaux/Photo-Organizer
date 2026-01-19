import SwiftUI
import AppKit

struct DateConfirmationView: View {
    @Bindable var appState: AppState
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedDay: Int = Calendar.current.component(.day, from: Date())

    private var selectedDate: Date {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = selectedDay
        return Calendar.current.date(from: components) ?? Date()
    }

    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((1990...currentYear).reversed())
    }

    private var availableMonths: [(Int, String)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return (1...12).map { month in
            var components = DateComponents()
            components.month = month
            components.day = 1
            let date = Calendar.current.date(from: components) ?? Date()
            return (month, formatter.string(from: date))
        }
    }

    private var availableDays: [Int] {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        if let date = Calendar.current.date(from: components),
           let range = Calendar.current.range(of: .day, in: .month, for: date) {
            return Array(range)
        }
        return Array(1...31)
    }

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

                    // Clickable directory path
                    Button(action: {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: group.directoryPath)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.badge.gearshape")
                                .font(.caption)
                            Text(group.directoryPath)
                                .font(.caption)
                                .lineLimit(2)
                                .truncationMode(.middle)
                        }
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Click to open in Finder")

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

                    HStack(spacing: 16) {
                        // Year picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Year")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("Year", selection: $selectedYear) {
                                ForEach(availableYears, id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 100)
                        }

                        // Month picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Month")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("Month", selection: $selectedMonth) {
                                ForEach(availableMonths, id: \.0) { month, name in
                                    Text(name).tag(month)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 120)
                        }

                        // Day picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Day")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("Day", selection: $selectedDay) {
                                ForEach(availableDays, id: \.self) { day in
                                    Text(String(day)).tag(day)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 80)
                        }
                    }
                    .onAppear {
                        if let suggested = group.suggestedDate {
                            let calendar = Calendar.current
                            selectedYear = calendar.component(.year, from: suggested)
                            selectedMonth = calendar.component(.month, from: suggested)
                            selectedDay = calendar.component(.day, from: suggested)
                        }
                    }
                    .onChange(of: appState.currentDateConfirmationIndex) { _, _ in
                        if let suggested = currentGroup?.suggestedDate {
                            let calendar = Calendar.current
                            selectedYear = calendar.component(.year, from: suggested)
                            selectedMonth = calendar.component(.month, from: suggested)
                            selectedDay = calendar.component(.day, from: suggested)
                        }
                    }
                    .onChange(of: selectedMonth) { _, _ in
                        // Adjust day if it exceeds the days in the new month
                        if selectedDay > availableDays.count {
                            selectedDay = availableDays.count
                        }
                    }
                    .onChange(of: selectedYear) { _, _ in
                        // Adjust day for leap year changes in February
                        if selectedDay > availableDays.count {
                            selectedDay = availableDays.count
                        }
                    }

                    // Preview of selected date
                    Text(selectedDate, style: .date)
                        .font(.title3)
                        .fontWeight(.medium)
                        .padding(.top, 8)

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
