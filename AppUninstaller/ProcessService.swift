import SwiftUI
import AppKit
import Foundation

struct ProcessItem: Identifiable {
    let id = UUID()
    let pid: Int32
    let name: String
    let icon: NSImage?
    let isApp: Bool // true for GUI Apps, false for background processes
    let validationPath: String? // For apps, the bundle path
    let memoryUsage: Int64 // Mức sử dụng bộ nhớ (byte)
    
    var formattedPID: String {
        String(pid)
    }
    
    ///Sử dụng bộ nhớ được định dạng

    var formattedMemory: String {
        ByteCountFormatter.string(fromByteCount: memoryUsage, countStyle: .memory)
    }
}

class ProcessService: ObservableObject {
    @Published var processes: [ProcessItem] = []
    @Published var isScanning = false
    
    // Cache PID vào ánh xạ sử dụng bộ nhớ - sử dụng Set để tra cứu hiệu quả

    private var memoryCache: [Int32: Int64] = [:]
    private var processIdSet: Set<Int32> = []
    
    // UI Update Batching
    private let uiUpdater = BatchedUIUpdater(debounceDelay: 0.05)
    func scanProcesses(showApps: Bool) async {
        await uiUpdater.batch {
            self.isScanning = true
        }
        
        // Trước tiên hãy lấy mức sử dụng bộ nhớ của tất cả các quy trình

        await fetchMemoryUsage()
        
        var items: [ProcessItem] = []
        
        if showApps {
            // Get Running Applications (GUI)
            let apps = NSWorkspace.shared.runningApplications
            for app in apps {
                // Filter out some system daemons that might show up as apps but have no icon or interface
                guard app.activationPolicy == .regular else { continue }
                
                let memory = memoryCache[app.processIdentifier] ?? 0
                
                let item = ProcessItem(
                    pid: app.processIdentifier,
                    name: app.localizedName ?? "Unknown App",
                    icon: app.icon,
                    isApp: true,
                    validationPath: app.bundleURL?.path,
                    memoryUsage: memory
                )
                items.append(item)
            }
        } else {
            // Get Background Processes using ps command
            // We focus on user processes to avoid listing thousands of system kernel threads
            let task = Process()
            task.launchPath = "/bin/ps"
            task.arguments = ["-x", "-o", "pid,rss,comm"] // List processes owned by user, PID, RSS (memory) and Command
            
            let pipe = Pipe()
            task.standardOutput = pipe
            
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: "\n")
                    // Skip header
                    for (index, line) in lines.enumerated() {
                        if index == 0 || line.isEmpty { continue }
                        
                        let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                        guard parts.count >= 3,
                              let pid = Int32(parts[0]),
                              let rssKB = Int64(parts[1]) else { continue }
                        
                        // Extract name (everything after PID and RSS)
                        let cmdParts = parts.dropFirst(2)
                        // Determine name from path (e.g. /usr/sbin/distnoted -> distnoted)
                        let fullPath = cmdParts.joined(separator: " ")
                        let name = URL(fileURLWithPath: fullPath).lastPathComponent
                        
                        // Filter out this app itself
                        if pid == ProcessInfo.processInfo.processIdentifier { continue }
                        
                        // RSS is in KB, convert to bytes
                        let memoryBytes = rssKB * 1024
                        
                        let item = ProcessItem(
                            pid: pid,
                            name: name,
                            icon: nil,
                            isApp: false,
                            validationPath: nil,
                            memoryUsage: memoryBytes
                        )
                        items.append(item)
                    }
                }
            } catch {
                print("Error scanning background processes: \(error)")
            }
        }
        
        // Sort: Apps by memory (descending), then by name
        let sortedItems = items.sorted { 
            if $0.memoryUsage != $1.memoryUsage {
                return $0.memoryUsage > $1.memoryUsage // Những người có trí nhớ lớn hơn sẽ được xếp hạng đầu tiên.
            }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending 
        }
        
        // Update process ID set for efficient lookups
        let pidSet = Set(sortedItems.map { $0.pid })
        
        // Batch UI update
        await uiUpdater.batch {
            self.processes = sortedItems
            self.processIdSet = pidSet
            self.isScanning = false
        }
    }
    
    /// Nhận mức sử dụng bộ nhớ của tất cả các tiến trình

    private func fetchMemoryUsage() async {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-ax", "-o", "pid,rss"] // PID và RSS của tất cả các quy trình (bộ nhớ, KB)
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                var cache: [Int32: Int64] = [:]
                let lines = output.components(separatedBy: "\n")
                for (index, line) in lines.enumerated() {
                    if index == 0 || line.isEmpty { continue }
                    
                    let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    guard parts.count >= 2,
                          let pid = Int32(parts[0]),
                          let rssKB = Int64(parts[1]) else { continue }
                    
                    // RSS is in KB, convert to bytes
                    cache[pid] = rssKB * 1024
                }
                memoryCache = cache
            }
        } catch {
            print("Error fetching memory usage: \(error)")
        }
    }
    
    func terminateProcess(_ item: ProcessItem) {
        if item.isApp {
            // Try nice termination first for Apps
            if let app = NSRunningApplication(processIdentifier: item.pid) {
                app.terminate()
                
                // If not responding ?? Maybe force option later.
                // For now, let's update list after short delay
            }
        } else {
            // Force kill for background processes
            let task = Process()
            task.launchPath = "/bin/kill"
            task.arguments = ["-9", String(item.pid)]
            try? task.run()
        }
        
        // Batch UI removal
        Task {
            await uiUpdater.batch {
                self.processes.removeAll { $0.id == item.id }
                self.processIdSet.remove(item.pid)
            }
        }
    }

    
    func forceTerminateProcess(_ item: ProcessItem) {
        // Always use "kill -9" for force quit
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-9", String(item.pid)]
        try? task.run()
        
        // Batch UI removal
        Task {
            await uiUpdater.batch {
                self.processes.removeAll { $0.id == item.id }
                self.processIdSet.remove(item.pid)
            }
        }
    }

    /// Làm sạch dữ liệu ứng dụng (đặt lại ứng dụng)

    func cleanAppData(for item: ProcessItem) async {
        // 1. Buộc thoát ứng dụng

        forceTerminateProcess(item)
        
        // Đợi quá trình kết thúc

        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        // 2. Xác định thông tin ứng dụng

        guard let pathString = item.validationPath else {
            return
        }
        
        let url = URL(fileURLWithPath: pathString)
        let bundle = Bundle(url: url)
        let bundleId = bundle?.bundleIdentifier
        
        // Nếu không có ID gói, các tệp còn lại có thể không được tìm thấy chính xác, bạn chỉ cần bỏ qua hoặc cố gắng chỉ quét theo tên.

        guard let bId = bundleId else { return }
        
        let icon = item.icon ?? NSImage()
        
        // Tạo mô hình InstalledApp tạm thời để quét

        let app = InstalledApp(
            name: item.name,
            path: url,
            bundleIdentifier: bId,
            icon: icon,
            size: 0
        )
        
        // 3. Quét các tập tin còn sót lại

        let scanner = ResidualFileScanner()
        let files = await scanner.scanResidualFiles(for: app)
        
        // Chọn tất cả các tập tin

        await MainActor.run {
            for file in files {
                file.isSelected = true
            }
            app.residualFiles = files
        }
        
        // 4. Xóa dữ liệu (giữ lại chính ứng dụng)

        let remover = FileRemover()
        _ = await remover.removeResidualFiles(of: app, moveToTrash: true)
    }
}
