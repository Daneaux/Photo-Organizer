import SwiftUI

struct ScanProgressView: View {
    let progress: DirectoryScanner.ScanProgress

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Scanning...")
                .font(.headline)

            VStack(spacing: 8) {
                HStack {
                    Label("\(progress.directoriesScanned)", systemImage: "folder")
                    Text("directories scanned")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("\(progress.filesFound)", systemImage: "photo.on.rectangle")
                    Text("media files found")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)

            if !progress.currentDirectory.isEmpty {
                Text(progress.currentDirectory)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        }
    }
}

#Preview {
    ScanProgressView(
        progress: DirectoryScanner.ScanProgress(
            directoriesScanned: 42,
            filesFound: 1234,
            currentDirectory: "2023-06-15 Beach Vacation"
        )
    )
    .padding()
    .frame(width: 400)
}
