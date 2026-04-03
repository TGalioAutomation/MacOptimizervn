import Foundation
import SwiftUI

// MARK: - File Node Model
class FileNode: Identifiable, ObservableObject, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    var size: Int64
    let isDirectory: Bool
    var children: [FileNode] = []
    weak var parent: FileNode?
    
    // UI Properties
    @Published var isSelected: Bool = false
    
    init(url: URL, name: String, size: Int64, isDirectory: Bool) {
        self.url = url
        self.name = name
        self.size = size
        self.isDirectory = isDirectory
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Scanner Service
class SpaceLensScanner: ObservableObject {
    @Published var rootNode: FileNode?
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var currentPath: String = ""
    @Published var totalSize: Int64 = 0
    
    private var shouldStop = false
    
    func stopScan() {
        shouldStop = true
        isScanning = false
    }
    
    func scan(targetURL: URL? = nil) async {
        await MainActor.run {
            self.isScanning = true
            self.scanProgress = 0
            self.totalSize = 0
            self.shouldStop = false
            self.rootNode = nil
        }
        
        // Default to Home if no URL provided, though UI usually provides one.
        let startURL = targetURL ?? FileManager.default.homeDirectoryForCurrentUser
        let isRoot = startURL.path == "/"
        
        let root = FileNode(url: startURL, name: startURL.lastPathComponent, size: 0, isDirectory: true)
        
        // Parallelize scanning for the immediate children of the startURL
        // This ensures that "Users/name" scan is fast because "Documents", "Library", etc. run in parallel.
        
        var topLevelURLs: [URL] = []
        
        if isRoot {
            let candidates = ["Applications", "Library", "System", "Users", "private", "usr", "opt", "bin", "sbin"]
            topLevelURLs = candidates.map { startURL.appendingPathComponent($0) }
        } else {
            // Get contents of the custom target URL to parallelize
            // We include hidden files here too
            if let contents = try? FileManager.default.contentsOfDirectory(at: startURL, includingPropertiesForKeys: [.isDirectoryKey], options: []) {
                topLevelURLs = contents
            } else {
                // Fallback if we can't read listing (e.g. permission)
                // Just try scanning the node itself sequentially (will fail inside scanDirectory likely)
                topLevelURLs = [startURL] 
            }
        }
        
        await withTaskGroup(of: FileNode?.self) { group in
            for url in topLevelURLs {
                // Avoid scanning parent/self if enumerator returned them (contentsOfDirectory doesn't usually)
                if url.path == startURL.path && !isRoot { continue } // Should not happen with contentsOfDirectory
                
                group.addTask {
                    if self.shouldStop { return nil }
                    // Scan children with depth 0 (relative to the new root, effectively depth 1 of the overall tree)
                    // Wait, scanDirectory(url) creates a node for 'url'. 
                    // That node should be a child of 'root'.
                    return await self.scanDirectory(url, depth: 0)
                }
            }
            
            for await node in group {
                guard let node = node else { continue }
                
                // Add as child to root
                root.children.append(node)
                node.parent = root
                root.size += node.size
                
                await MainActor.run {
                    self.totalSize = root.size
                    self.currentPath = node.name // Show progress
                }
            }
        }
        
        // Sort children by size
        root.children.sort { $0.size > $1.size }
        
        await MainActor.run {
            self.rootNode = root
            self.isScanning = false
            self.scanProgress = 1.0
        }
    }
    
    // Recursive scan with depth limit
    private func scanDirectory(_ url: URL, depth: Int) async -> FileNode? {
        if shouldStop { return nil }
        
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            // It's a file passed as a directory? or doesn't exist.
            // If it's a file, make a node.
            if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                return FileNode(url: url, name: url.lastPathComponent, size: size, isDirectory: false)
            }
            return nil
        }
        
        let node = FileNode(url: url, name: url.lastPathComponent, size: 0, isDirectory: true)
        
        // Exclude /Volumes to avoid loops or external drives unless requested (root request handles it)
        if url.path == "/Volumes" || url.path == "/dev" || url.path == "/proc" {
            return node
        }

        // Include hidden files: options: []
        guard let items = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isPackageKey], options: []) else {
            return node
        }
        
        var directorySize: Int64 = 0
        
        // Optimization: Don't build FULL tree for very deep levels if not needed immediately?
        // But for visualization we kind of need it. 
        // We can limit depth for "Detailed Nodes" but keep "Size" calculation?
        // Actually, just calculating size of children is enough.
        
        for item in items {
            if shouldStop { break }
            
            // Check if package
            let resourceValues = try? item.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey, .fileSizeKey])
            let isPackage = resourceValues?.isPackage ?? false
            let isDirectory = resourceValues?.isDirectory ?? false
            
            if isDirectory && !isPackage {
                // If depth < 2, we recurse to build children nodes.
                // If depth >= 2, maybe we just calculate size to save memory?
                // Visualizer needs immediate children. When user clicks, we can scan deeper?
                // "Lazy Loading" is best for Space Lens.
                // Approach: Scan 2 levels deep. Then calculate remaining size?
                // NO, we need TOTAL size. 
                // Let's recursively scan but maybe only keep `children` for top levels in memory?
                // No, Mac apps usually scan everything.
                
                // For this implementation, let's scan 3-4 levels deep efficiently? 
                // Alternatively, define a "Fast Scan" that just sums sizes for deep folders without creating FileNodes for every single file.
                
                if depth < 2 { // Build tree for top levels
                    if let childParams = await scanDirectory(item, depth: depth + 1) {
                        node.children.append(childParams)
                        childParams.parent = node
                        directorySize += childParams.size
                    }
                } else {
                    // Just calculate size
                    directorySize += await fastFolderSize(item)
                }
                
                if depth == 0 {
                    await MainActor.run { self.currentPath = item.path }
                }
                
            } else {
                let size = Int64(resourceValues?.fileSize ?? 0)
                directorySize += size
                // Only add file nodes at top levels to avoid 1M objects
                if depth < 2 {
                    let fileNode = FileNode(url: item, name: item.lastPathComponent, size: size, isDirectory: false)
                    fileNode.parent = node
                    node.children.append(fileNode)
                }
            }
        }
        
        node.size = directorySize
        node.children.sort { $0.size > $1.size }
        
        return node
    }
    
    private func fastFolderSize(_ url: URL) async -> Int64 {
        // Fast enumeration just for size
        // Run in detached task to allow synchronous enumeration without async iterator issues
        return await Task.detached {
            var size: Int64 = 0
            guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: []) else { return 0 }
            
            while let fileURL = enumerator.nextObject() as? URL {
                if Task.isCancelled { break }
                let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
                size += Int64(values?.fileSize ?? 0)
            }
            return size
        }.value
    }
}
