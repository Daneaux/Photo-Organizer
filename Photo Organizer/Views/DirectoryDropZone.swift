import SwiftUI
import UniformTypeIdentifiers

struct DirectoryDropZone: View {
    let title: String
    let selectedURL: URL?
    let onSelect: () -> Void

    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: selectedURL == nil ? "folder.badge.plus" : "folder.fill")
                .font(.system(size: 40))
                .foregroundStyle(selectedURL == nil ? .secondary : Color.accentColor)

            if let url = selectedURL {
                Text(url.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)

                Text(url.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            } else {
                Text(title)
                    .font(.headline)

                Text("Drop folder here or click to browse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(
                        lineWidth: 2,
                        dash: selectedURL == nil ? [8] : []
                    )
                )
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDropTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }

            // Verify it's a directory
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                return
            }

            DispatchQueue.main.async {
                onSelect()
            }
        }
        return true
    }
}

#Preview {
    VStack(spacing: 20) {
        DirectoryDropZone(
            title: "Source Directory",
            selectedURL: nil,
            onSelect: {}
        )

        DirectoryDropZone(
            title: "Source Directory",
            selectedURL: URL(fileURLWithPath: "/Users/demo/Photos/Vacation 2024"),
            onSelect: {}
        )
    }
    .padding()
    .frame(width: 400)
}
