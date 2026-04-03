import Foundation
import AppKit

struct PortItem: Identifiable {
    let id = UUID()
    let command: String      // tên quy trình
    let pid: Int             // ID tiến trình
    let user: String         // người dùng
    let port: Int?           // số cổng
    let `protocol`: String   // TCP/UDP
    let state: String        // LISTEN, ESTABLISHED, etc.
    let address: String      // địa chỉ nghe
    
    var displayName: String {
        // Làm đẹp tên quy trình

        command.replacingOccurrences(of: "\\x", with: "")
    }
    
    var portString: String {
        if let p = port {
            return String(p)
        }
        return "-"
    }
    
    var icon: NSImage? {
        // Cố gắng lấy biểu tượng ứng dụng

        let runningApps = NSWorkspace.shared.runningApplications
        if let app = runningApps.first(where: { $0.processIdentifier == Int32(pid) }) {
            return app.icon
        }
        return nil
    }
}

class PortScannerService: ObservableObject {
    @Published var ports: [PortItem] = []
    @Published var isScanning = false
    @Published var filterListeningOnly = true
    
    func scanPorts() async {
        await MainActor.run { isScanning = true }
        
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-i", "-P", "-n"] // Internet files, No port names, No host names
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: "\n")
                var items: [PortItem] = []
                var seenPorts: Set<String> = [] // Xóa trùng lặp
                
                for (index, line) in lines.enumerated() {
                    if index == 0 || line.isEmpty { continue }
                    
                    // lsof output: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
                    let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                    guard parts.count >= 9 else { continue }
                    
                    let command = String(parts[0])
                    let pidStr = String(parts[1])
                    let user = String(parts[2])
                    let name = parts[8...].joined(separator: " ")
                    
                    guard let pid = Int(pidStr) else { continue }
                    
                    // Phân tích trường TÊN: *:8080 hoặc 127.0.0.1:3306 hoặc *:3306 (LISTEN)

                    var port: Int? = nil
                    var proto = "TCP"
                    var state = ""
                    var address = "*"
                    
                    // Kiểm tra loại giao thức

                    if name.contains("UDP") {
                        proto = "UDP"
                    }
                    
                    // trạng thái phân tích cú pháp

                    if name.contains("(LISTEN)") {
                        state = "LISTEN"
                    } else if name.contains("(ESTABLISHED)") {
                        state = "ESTABLISHED"
                    } else if name.contains("(CLOSE_WAIT)") {
                        state = "CLOSE_WAIT"
                    } else if name.contains("(TIME_WAIT)") {
                        state = "TIME_WAIT"
                    }
                    
                    // Bộ lọc: Chỉ hiển thị trạng thái NGHE

                    if filterListeningOnly && state != "LISTEN" {
                        continue
                    }
                    
                    // Phân tích số cổng - định dạng: địa chỉ:port hoặc *:port

                    let cleanName = name.replacingOccurrences(of: "(LISTEN)", with: "")
                        .replacingOccurrences(of: "(ESTABLISHED)", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    
                    if let colonIndex = cleanName.lastIndex(of: ":") {
                        let portPart = String(cleanName[cleanName.index(after: colonIndex)...])
                            .trimmingCharacters(in: .whitespaces)
                            .components(separatedBy: "->").first ?? ""
                        port = Int(portPart.trimmingCharacters(in: .whitespaces))
                        
                        let addrPart = String(cleanName[..<colonIndex])
                        address = addrPart.isEmpty ? "*" : addrPart
                    }
                    
                    // Chống trùng lặp: Quá trình tương tự và cùng một cổng chỉ được hiển thị một lần

                    let uniqueKey = "\(pid)-\(port ?? 0)"
                    if seenPorts.contains(uniqueKey) { continue }
                    seenPorts.insert(uniqueKey)
                    
                    let item = PortItem(
                        command: command,
                        pid: pid,
                        user: user,
                        port: port,
                        protocol: proto,
                        state: state,
                        address: address
                    )
                    items.append(item)
                }
                
                // Sắp xếp theo số cổng

                items.sort { ($0.port ?? 0) < ($1.port ?? 0) }
                
                await MainActor.run { [items] in
                    self.ports = items
                    self.isScanning = false
                }
            }
        } catch {
            print("Port Scan Error: \(error)")
            await MainActor.run { isScanning = false }
        }
    }
    
    /// Chấm dứt quá trình giải phóng cổng

    func terminateProcess(_ item: PortItem) {
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-9", String(item.pid)]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            // Làm mới danh sách

            Task { await scanPorts() }
        } catch {
            print("Failed to terminate process: \(error)")
        }
    }
}
