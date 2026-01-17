import Foundation

@Observable
final class FolderNode: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let depth: Int

    // File counts
    var directFileCount: Int = 0       // Media files directly in this folder
    var recursiveFileCount: Int = 0    // Media files including all subfolders

    // Tree structure
    weak var parent: FolderNode?
    var children: [FolderNode] = []

    // UI state
    var isExpanded: Bool = true        // Default expanded for visibility
    var isSelected: Bool = true        // Default selected (process all)

    // Computed properties
    var hasChildren: Bool { !children.isEmpty }

    init(url: URL, name: String, depth: Int, parent: FolderNode? = nil) {
        self.url = url
        self.name = name
        self.depth = depth
        self.parent = parent
    }

    /// Propagate selection changes to all children recursively
    func setSelectedRecursively(_ selected: Bool) {
        isSelected = selected
        for child in children {
            child.setSelectedRecursively(selected)
        }
    }

    /// Calculate recursive file count from children (call after tree is built)
    func calculateRecursiveCount() {
        recursiveFileCount = directFileCount
        for child in children {
            child.calculateRecursiveCount()
            recursiveFileCount += child.recursiveFileCount
        }
    }

    /// Get all selected folder paths (for filtering during scan)
    func allSelectedPaths() -> Set<String> {
        var paths = Set<String>()
        if isSelected && directFileCount > 0 {
            paths.insert(url.path)
        }
        for child in children {
            paths.formUnion(child.allSelectedPaths())
        }
        return paths
    }

    /// Flatten tree into array for display (respecting expansion state)
    func flattenVisible() -> [FolderNode] {
        var result: [FolderNode] = []
        for child in children {
            result.append(child)
            if child.isExpanded {
                result.append(contentsOf: child.flattenVisible())
            }
        }
        return result
    }

    /// Flatten entire tree into array (ignoring expansion state)
    func flattenAll() -> [FolderNode] {
        var result: [FolderNode] = []
        for child in children {
            result.append(child)
            result.append(contentsOf: child.flattenAll())
        }
        return result
    }

    /// Count total selected files
    func countSelectedFiles() -> Int {
        var count = isSelected ? directFileCount : 0
        for child in children {
            count += child.countSelectedFiles()
        }
        return count
    }

    /// Set expansion state for all nodes
    func setExpandedRecursively(_ expanded: Bool) {
        isExpanded = expanded
        for child in children {
            child.setExpandedRecursively(expanded)
        }
    }
}
