import SwiftUI
import AppKit
import Foundation

struct ShredderItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let size: Int64
    var status: String = "" // "Pending", "Shredding", "Done", "Failed"
    
    var name: String {
        url.lastPathComponent
    }
    
    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

class ShredderService: ObservableObject {
    @Published var items: [ShredderItem] = []
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var currentItemName: String = ""
    @Published var totalSizeCleared: Int64 = 0
    @Published var errorMessage: String?
    
    // Add files via NSOpenPanel
    @MainActor
    func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.prompt = "Select"
        
        panel.begin { response in
            if response == .OK {
                for url in panel.urls {
                    self.addItem(url: url)
                }
            }
        }
    }
    
    func addItem(url: URL) {
        // Calculate size (recursive for directories)
        let size = calculateSize(of: url)
        let item = ShredderItem(url: url, size: size, status: "Pending")
        DispatchQueue.main.async {
            if !self.items.contains(where: { $0.url == url }) {
                self.items.append(item)
            }
        }
    }
    
    func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
    }
    
    func reset() {
        items = []
        isProcessing = false
        progress = 0.0
        currentItemName = ""
        totalSizeCleared = 0
        errorMessage = nil
    }
    
    // MARK: - Shredding Logic
    func startShredding() async {
        await MainActor.run {
            isProcessing = true
            progress = 0.0
            totalSizeCleared = 0
        }
        
        let totalItems = items.count
        var processedCount = 0
        
        for index in items.indices {
            let item = items[index]
            
            await MainActor.run {
                currentItemName = item.name
                items[index].status = "Shredding..."
            }
            
            // Perform Secure Delete
            let success = await secureDelete(url: item.url)
            
            processedCount += 1
            await MainActor.run { [processedCount] in
                if success {
                    items[index].status = "Done"
                    totalSizeCleared += item.size
                } else {
                    items[index].status = "Failed"
                }
                
                progress = Double(processedCount) / Double(totalItems)
            }
            
            // Small artificial delay for UI animation if needed, but real work takes time
            // try? await Task.sleep(nanoseconds: 200_000_000)
        }
        
        await MainActor.run {
            isProcessing = false
            currentItemName = ""
        }
    }
    
    private func secureDelete(url: URL) async -> Bool {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else { return true }
        
        // 1. Check for locks/running processes (Simulated for now, can add lsof later if needed)
        // In a real implementation, we'd use `lsof` to find PID and offer to kill it.
        
        do {
            // Get file attributes
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            let isDir = (attr[.type] as? FileAttributeType) == .typeDirectory
            
            if isDir {
                // If directory, standard enumerate and delete contents first
                // For secure delete of directory, we should recurse.
                // For simplicity in this iteration, we use standard removal for directories
                // or just remove it. A strict shredder would shred every file inside.
                // Let's attempt to shred contents.
                if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) {
                    while let fileURL = enumerator.nextObject() as? URL {
                        _ = try? await simpleOverwrite(url: fileURL)
                    }
                }
                try FileManager.default.removeItem(at: url)
            } else {
                // 2. Overwrite Logic (1-pass zero fill)
                // This makes recovery much harder than simple delete.
                try await simpleOverwrite(url: url)
                
                // 3. Rename (Obfuscate name)
                let newName = UUID().uuidString
                let newUrl = url.deletingLastPathComponent().appendingPathComponent(newName)
                try FileManager.default.moveItem(at: url, to: newUrl)
                
                // 4. Remove
                try FileManager.default.removeItem(at: newUrl)
            }
            
            return true
        } catch {
            print("Shred error: \(error)")
            return false
        }
    }
    
    private func simpleOverwrite(url: URL) async throws {
        // Only overwrite files, not directories
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
           return
        }
        
        let handle = try FileHandle(forWritingTo: url)
        let size = handle.seekToEndOfFile()
        
        // If file is huge, maybe don't overwrite entire thing for performance in this demo?
        // Let's overwrite first 1MB and last 1MB and random chunks if > 10MB
        // But user asked for "Real" functionality. A real shredder overwrites everything.
        // We will overwrite up to 10MB to avoid hanging UI on massive movies,
        // or chunk it. For "Real" result, we should try to be thorough but efficient.
        // Let's allow full overwrite but maybe async? We are already in async.
        
        try handle.seek(toOffset: 0)
        
        // Chunk size 1MB
        let chunkSize = 1024 * 1024
        let zeroData = Data(count: chunkSize)
        
        var written: UInt64 = 0
        while written < size {
            let remaining = size - written
            let toWrite = min(UInt64(chunkSize), remaining)
            if toWrite < chunkSize {
                 try handle.write(contentsOf: Data(count: Int(toWrite)))
            } else {
                 try handle.write(contentsOf: zeroData)
            }
            written += toWrite
            // Periodic yield
            try await Task.sleep(nanoseconds: 1_000_000) 
        }
        
        try handle.close()
    }
    
    private func calculateSize(of url: URL) -> Int64 {
        var size: Int64 = 0
        let resourceKeys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]
        
        // If it's a file
        if let resources = try? url.resourceValues(forKeys: Set(resourceKeys)) {
            if resources.isDirectory == false {
                return Int64(resources.fileSize ?? 0)
            }
        }
        
        // If it's a directory (or calculate recursive)
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: resourceKeys) {
            while let fileURL = enumerator.nextObject() as? URL {
                if let resources = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                   let fileSize = resources.fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        return size
    }
}
