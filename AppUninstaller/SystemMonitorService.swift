import Foundation
import Combine
import AppKit

struct HighMemoryApp: Identifiable {
    let id: pid_t
    let name: String
    let usage: Double // GB
    let icon: NSImage?
}

enum SamplingProfile: String, CaseIterable, Identifiable, Codable {
    case economy
    case balanced
    case live
    case custom
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .economy: return "Tiết kiệm"
        case .balanced: return "Cân bằng"
        case .live: return "Theo dõi sát"
        case .custom: return "Tùy chỉnh"
        }
    }
    
    var subtitle: String {
        switch self {
        case .economy: return "Ưu tiên giảm tác động nền"
        case .balanced: return "Mặc định, đủ mượt cho hầu hết máy"
        case .live: return "Cập nhật nhanh hơn khi cần quan sát sát"
        case .custom: return "Bạn tự đặt nhịp lấy mẫu cho từng loại"
        }
    }
}

enum SamplingMetricKind: String, CaseIterable, Identifiable, Codable {
    case storage
    case gpu
    case cpu
    case memory
    case network
    case battery
    case processes
    case alerts
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .storage: return "Ổ đĩa"
        case .gpu: return "GPU"
        case .cpu: return "CPU"
        case .memory: return "RAM"
        case .network: return "Mạng"
        case .battery: return "Pin"
        case .processes: return "Top tiến trình"
        case .alerts: return "Cảnh báo RAM"
        }
    }
    
    var subtitle: String {
        switch self {
        case .storage: return "Dùng cho DISK trên thanh menu và panel ổ đĩa"
        case .gpu: return "Mức tải GPU hiện tại"
        case .cpu: return "Tải CPU tổng cho status item và widget"
        case .memory: return "Mức dùng RAM tổng và thống kê bộ nhớ"
        case .network: return "Tốc độ mạng và lịch sử truyền nhận"
        case .battery: return "Mức pin và trạng thái sạc"
        case .processes: return "Danh sách app nặng để force quit"
        case .alerts: return "Quét app dùng RAM vượt ngưỡng"
        }
    }
    
    var range: ClosedRange<Double> {
        switch self {
        case .storage: return 10...60
        case .gpu: return 1...6
        case .cpu: return 1...5
        case .memory: return 1...6
        case .network: return 1...6
        case .battery: return 15...120
        case .processes: return 5...30
        case .alerts: return 5...30
        }
    }
    
    var step: Double {
        switch self {
        case .gpu, .cpu, .memory, .network:
            return 0.5
        case .storage, .processes, .alerts:
            return 5
        case .battery:
            return 15
        }
    }
}

struct MenuBarSamplingConfiguration: Codable, Equatable {
    var storageInterval: TimeInterval
    var gpuInterval: TimeInterval
    var cpuInterval: TimeInterval
    var memoryInterval: TimeInterval
    var networkInterval: TimeInterval
    var batteryInterval: TimeInterval
    var processInterval: TimeInterval
    var alertInterval: TimeInterval
    
    static func preset(_ profile: SamplingProfile) -> MenuBarSamplingConfiguration {
        switch profile {
        case .economy:
            return MenuBarSamplingConfiguration(
                storageInterval: 30,
                gpuInterval: 3.0,
                cpuInterval: 3.0,
                memoryInterval: 4.0,
                networkInterval: 5.0,
                batteryInterval: 90.0,
                processInterval: 20.0,
                alertInterval: 20.0
            )
        case .balanced, .custom:
            return MenuBarSamplingConfiguration(
                storageInterval: 15,
                gpuInterval: 2.0,
                cpuInterval: 1.5,
                memoryInterval: 2.0,
                networkInterval: 2.5,
                batteryInterval: 45.0,
                processInterval: 8.0,
                alertInterval: 12.0
            )
        case .live:
            return MenuBarSamplingConfiguration(
                storageInterval: 10,
                gpuInterval: 1.5,
                cpuInterval: 1.0,
                memoryInterval: 1.5,
                networkInterval: 1.5,
                batteryInterval: 30.0,
                processInterval: 5.0,
                alertInterval: 8.0
            )
        }
    }
    
    func interval(for kind: SamplingMetricKind) -> TimeInterval {
        switch kind {
        case .storage: return storageInterval
        case .gpu: return gpuInterval
        case .cpu: return cpuInterval
        case .memory: return memoryInterval
        case .network: return networkInterval
        case .battery: return batteryInterval
        case .processes: return processInterval
        case .alerts: return alertInterval
        }
    }
    
    mutating func setInterval(_ interval: TimeInterval, for kind: SamplingMetricKind) {
        switch kind {
        case .storage: storageInterval = interval
        case .gpu: gpuInterval = interval
        case .cpu: cpuInterval = interval
        case .memory: memoryInterval = interval
        case .network: networkInterval = interval
        case .battery: batteryInterval = interval
        case .processes: processInterval = interval
        case .alerts: alertInterval = interval
        }
    }

    init(
        storageInterval: TimeInterval,
        gpuInterval: TimeInterval,
        cpuInterval: TimeInterval,
        memoryInterval: TimeInterval,
        networkInterval: TimeInterval,
        batteryInterval: TimeInterval,
        processInterval: TimeInterval,
        alertInterval: TimeInterval
    ) {
        self.storageInterval = storageInterval
        self.gpuInterval = gpuInterval
        self.cpuInterval = cpuInterval
        self.memoryInterval = memoryInterval
        self.networkInterval = networkInterval
        self.batteryInterval = batteryInterval
        self.processInterval = processInterval
        self.alertInterval = alertInterval
    }

    private enum CodingKeys: String, CodingKey {
        case storageInterval
        case gpuInterval
        case cpuInterval
        case memoryInterval
        case networkInterval
        case batteryInterval
        case processInterval
        case alertInterval
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = MenuBarSamplingConfiguration.preset(.balanced)
        storageInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .storageInterval) ?? defaults.storageInterval
        gpuInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .gpuInterval) ?? defaults.gpuInterval
        cpuInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .cpuInterval) ?? defaults.cpuInterval
        memoryInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .memoryInterval) ?? defaults.memoryInterval
        networkInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .networkInterval) ?? defaults.networkInterval
        batteryInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .batteryInterval) ?? defaults.batteryInterval
        processInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .processInterval) ?? defaults.processInterval
        alertInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .alertInterval) ?? defaults.alertInterval
    }
}

class SystemMonitorService: ObservableObject {
    private struct SamplingNeeds {
        var gpu: Bool
        var cpu: Bool
        var memory: Bool
        var network: Bool
        var networkDetails: Bool
        var battery: Bool
        var processDetails: Bool
        var detailedMemory: Bool
        var batteryDetails: Bool
        var highMemoryAlerts: Bool
        
        static let dashboard = SamplingNeeds(
            gpu: false,
            cpu: true,
            memory: true,
            network: true,
            networkDetails: false,
            battery: false,
            processDetails: true,
            detailedMemory: false,
            batteryDetails: false,
            highMemoryAlerts: true
        )
    }

    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0 // Percentage
    @Published var memoryUsedString: String = "0 GB"
    @Published var memoryTotalString: String = "0 GB"
    
    // High Memory Alert
    @Published var highMemoryApp: HighMemoryApp?
    @Published var showHighMemoryAlert: Bool = false
    // Threshold set to 2GB as requested
    private let memoryThresholdGB: Double = 2.0 
    private var ignoredPids: Set<pid_t> = []
    
    // Mới: nhắc nhở theo lịch trình và bỏ qua vĩnh viễn

    private var snoozedUntil: Date?  // Tạm ẩn lời nhắc cho đến thời điểm này
    private var permanentlyIgnoredApps: Set<String> = []  // Danh sách tên ứng dụng vĩnh viễn bỏ qua
    private let ignoredAppsKey = "MemoryMonitor.IgnoredApps"
    
    // Network Speed Monitoring
    @Published var downloadSpeed: Double = 0.0 // bytes per second
    @Published var uploadSpeed: Double = 0.0   // bytes per second
    @Published var downloadSpeedHistory: [Double] = Array(repeating: 0, count: 20)
    @Published var uploadSpeedHistory: [Double] = Array(repeating: 0, count: 20)
    
    private var lastBytesReceived: UInt64 = 0
    private var lastBytesSent: UInt64 = 0
    private var lastNetworkCheck: Date = Date()
    
    // Battery Monitoring
    @Published var batteryLevel: Double = 1.0
    @Published var isCharging: Bool = false
    @Published var batteryState: String = "Không xác định" 
    @Published var gpuUsage: Double = 0.0
    @Published var gpuName: String = "GPU"
    @Published private(set) var samplingProfile: SamplingProfile = .balanced
    @Published private(set) var menuBarSamplingConfiguration: MenuBarSamplingConfiguration = .preset(.balanced)

    private var gpuTimer: Timer?
    private var cpuTimer: Timer?
    private var memoryTimer: Timer?
    private var networkTimer: Timer?
    private var batteryTimer: Timer?
    private var processTimer: Timer?
    private var alertTimer: Timer?
    private var isMonitoring = false
    private var samplingNeeds: SamplingNeeds = .dashboard
    private let samplingProfileKey = "MenuBar.SamplingProfile"
    private let samplingConfigurationKey = "MenuBar.SamplingConfiguration"
    
    // UI Update Batching
    private let uiUpdater = BatchedUIUpdater(debounceDelay: 0.05)

    // Process Monitoring
    struct AppProcess: Identifiable {
        let id: pid_t
        let name: String
        let icon: NSImage?
        let cpu: Double // Percentage
        let memory: Double // GB
    }
    
    @Published var topMemoryProcesses: [AppProcess] = []
    @Published var topCPUProcesses: [AppProcess] = []
    
    // Speed Test
    @Published var isTestingSpeed: Bool = false
    @Published var speedTestResult: Double = 0.0 // Mbps
    @Published var speedTestProgress: Double = 0.0
    
    // WiFi Info
    @Published var wifiSSID: String = "Wi-Fi"
    @Published var wifiSecurity: String = "WPA2 Personal" // Default/Mock for now
    @Published var wifiSignalStrength: String = "Tốt"
    @Published var connectionDuration: String = "0 giờ 0 phút 0 giây"
    private var connectionStartTime: Date = Date()
    
    // Total Traffic
    @Published var totalDownload: String = "0 KB"
    @Published var totalUpload: String = "0 KB"
    
    // ... updateStats logic ...
    
    private func fetchUserProcesses() {
        // 1. Get User Apps from NSWorkspace (GUI Apps)
        let runningApps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        
        // 2. Scan ALL user processes to build a process tree
        // ps -x -o pid,ppid,%cpu,rss,comm
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "ps -x -o pid,ppid,%cpu,rss,comm | tail -n +2"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Parse all processes
                struct ProcessInfo {
                    let pid: Int32
                    let ppid: Int32
                    let cpu: Double
                    let rss: Double // GB
                    let name: String
                }
                
                var allProcesses: [Int32: ProcessInfo] = [:]
                var childrenMap: [Int32: [Int32]] = [:] // Parent -> [Children]
                
                let lines = output.components(separatedBy: "\n")
                for line in lines {
                    let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if parts.count >= 5,
                       let pid = Int32(parts[0]),
                       let ppid = Int32(parts[1]),
                       let cpu = Double(parts[2]),
                       let rssKB = Double(parts[3]) {
                        
                        // Extract name (rest of the line)
                        let nameParts = parts.dropFirst(4)
                        let fullPath = nameParts.joined(separator: " ")
                        let name = URL(fileURLWithPath: fullPath).lastPathComponent
                        
                        let info = ProcessInfo(pid: pid, ppid: ppid, cpu: cpu, rss: rssKB / 1024.0 / 1024.0, name: name)
                        allProcesses[pid] = info
                        
                        // Build tree
                        childrenMap[ppid, default: []].append(pid)
                    }
                }
                
                // Helper to calculate total stats recursively
                func getAggregatedStats(for pid: Int32, visited: inout Set<Int32>) -> (cpu: Double, mem: Double) {
                    if visited.contains(pid) { return (0, 0) }
                    visited.insert(pid)
                    
                    var totalCPU = 0.0
                    var totalMem = 0.0
                    
                    if let process = allProcesses[pid] {
                        totalCPU += process.cpu
                        totalMem += process.rss
                    }
                    
                    if let children = childrenMap[pid] {
                        for child in children {
                            let childStats = getAggregatedStats(for: child, visited: &visited)
                            totalCPU += childStats.cpu
                            totalMem += childStats.mem
                        }
                    }
                    
                    return (totalCPU, totalMem)
                }
                
                // 3. Aggregate stats for each App
                var appProcesses: [AppProcess] = []

                
                for app in runningApps {
                    let pid = app.processIdentifier
                    // Only process if valid and not already counted (though unlikely for main apps to duplicate)
                    
                    var visited = Set<Int32>() // Visited for this app's tree
                    let stats = getAggregatedStats(for: pid, visited: &visited)
                    
                    // Add app stats
                    appProcesses.append(AppProcess(
                        id: pid,
                        name: app.localizedName ?? "Không rõ",
                        icon: app.icon,
                        cpu: stats.cpu,
                        memory: stats.mem
                    ))
                    
                    // Mark these PIDs as processed if we want to avoid double counting if we were scanning all processes.
                    // But here we only care about the Apps list from NSWorkspace.
                }
                
                // Sort and Update
                let sortedByMem = appProcesses.sorted { $0.memory > $1.memory }.prefix(10)
                let sortedByCPU = appProcesses.sorted { $0.cpu > $1.cpu }.prefix(10)
                
                DispatchQueue.main.async {
                    self.topMemoryProcesses = Array(sortedByMem)
                    self.topCPUProcesses = Array(sortedByCPU)
                }
            }
        } catch {
            print("User Process Scan Error: \(error)")
        }
    }
    
    func runSpeedTest() {
        guard !isTestingSpeed else { return }
        isTestingSpeed = true
        speedTestResult = 0
        speedTestProgress = 0
        
        // Simple download test (download a 10MB file or similar)
        // Using a reliable CDN test file (e.g., Cloudflare)
        guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=10000000") else { return }
        
        let startTime = Date()
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isTestingSpeed = false
                self?.speedTestProgress = 1.0
                
                if let data = data {
                    let duration = Date().timeIntervalSince(startTime)
                    let bits = Double(data.count) * 8
                    let mbps = (bits / duration) / 1_000_000
                    self?.speedTestResult = mbps
                }
            }
        }
        
        // Fake Progress or delegate? simpler for now just wait.
        // Or implement delegate for progress.
        task.resume()
    }
    
    // ... add fetchUserProcesses() to updateStats ...
    
    init() {
        // Disable high memory alert for the first 30 seconds after app launch
        snoozedUntil = Date().addingTimeInterval(30)
        
        loadIgnoredApps()
        loadSamplingPreferences()
    }
    
    deinit {
        stopMonitoring()
    }
    
    /// Tải danh sách ứng dụng bị bỏ qua vĩnh viễn từ UserDefaults

    private func loadIgnoredApps() {
        if let savedApps = UserDefaults.standard.array(forKey: ignoredAppsKey) as? [String] {
            permanentlyIgnoredApps = Set(savedApps)
        }
    }
    
    /// Lưu danh sách ứng dụng bị bỏ qua vĩnh viễn vào UserDefaults

    private func saveIgnoredApps() {
        UserDefaults.standard.set(Array(permanentlyIgnoredApps), forKey: ignoredAppsKey)
    }
    
    func startMonitoring() {
        guard !isMonitoring else {
            refreshSamplingSchedule(runImmediately: false)
            return
        }
        
        isMonitoring = true
        refreshSamplingSchedule(runImmediately: true)
    }
    
    func stopMonitoring() {
        isMonitoring = false
        [gpuTimer, cpuTimer, memoryTimer, networkTimer, batteryTimer, processTimer, alertTimer].forEach { $0?.invalidate() }
        gpuTimer = nil
        cpuTimer = nil
        memoryTimer = nil
        networkTimer = nil
        batteryTimer = nil
        processTimer = nil
        alertTimer = nil
    }
    
    func configureDashboardSampling() {
        samplingNeeds = .dashboard
        refreshSamplingSchedule(runImmediately: isMonitoring)
    }
    
    func configureMenuBarSampling(statusMetrics: [MenuBarStatusMetric], detailRoute: MenuBarRoute?, isMenuBarWindowOpen: Bool) {
        let metricSet = Set(statusMetrics)
        samplingNeeds = SamplingNeeds(
            gpu: metricSet.contains(.gpu),
            cpu: metricSet.contains(.cpu) || detailRoute == .cpu || isMenuBarWindowOpen,
            memory: metricSet.contains(.memory) || detailRoute == .memory || isMenuBarWindowOpen,
            network: metricSet.contains(.network) || detailRoute == .network || isMenuBarWindowOpen,
            networkDetails: detailRoute == .network,
            battery: metricSet.contains(.battery) || detailRoute == .battery || isMenuBarWindowOpen,
            processDetails: detailRoute == .cpu || detailRoute == .memory,
            detailedMemory: detailRoute == .memory,
            batteryDetails: detailRoute == .battery,
            highMemoryAlerts: true
        )
        refreshSamplingSchedule(runImmediately: isMonitoring)
    }
    
    var storageRefreshInterval: TimeInterval {
        menuBarSamplingConfiguration.interval(for: .storage)
    }
    
    func formattedSamplingInterval(for kind: SamplingMetricKind) -> String {
        let seconds = menuBarSamplingConfiguration.interval(for: kind)
        if seconds.rounded(.towardZero) == seconds {
            return "\(Int(seconds)) giây"
        }
        return String(format: "%.1f giây", seconds)
    }
    
    func applySamplingProfile(_ profile: SamplingProfile) {
        samplingProfile = profile
        menuBarSamplingConfiguration = MenuBarSamplingConfiguration.preset(profile == .custom ? .balanced : profile)
        saveSamplingPreferences()
        refreshSamplingSchedule(runImmediately: isMonitoring)
    }
    
    func updateSamplingInterval(for kind: SamplingMetricKind, to newValue: Double) {
        let normalizedValue = normalizeInterval(newValue, for: kind)
        menuBarSamplingConfiguration.setInterval(normalizedValue, for: kind)
        samplingProfile = .custom
        saveSamplingPreferences()
        refreshSamplingSchedule(runImmediately: isMonitoring)
    }
    
    private func normalizeInterval(_ value: Double, for kind: SamplingMetricKind) -> Double {
        let step = kind.step
        let range = kind.range
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        let rounded = (clamped / step).rounded() * step
        return min(max(rounded, range.lowerBound), range.upperBound)
    }
    
    private func loadSamplingPreferences() {
        if let rawValue = UserDefaults.standard.string(forKey: samplingProfileKey),
           let profile = SamplingProfile(rawValue: rawValue) {
            samplingProfile = profile
        }
        
        if let data = UserDefaults.standard.data(forKey: samplingConfigurationKey),
           let configuration = try? JSONDecoder().decode(MenuBarSamplingConfiguration.self, from: data) {
            menuBarSamplingConfiguration = configuration
        } else {
            menuBarSamplingConfiguration = MenuBarSamplingConfiguration.preset(samplingProfile == .custom ? .balanced : samplingProfile)
        }
    }
    
    private func saveSamplingPreferences() {
        UserDefaults.standard.set(samplingProfile.rawValue, forKey: samplingProfileKey)
        if let data = try? JSONEncoder().encode(menuBarSamplingConfiguration) {
            UserDefaults.standard.set(data, forKey: samplingConfigurationKey)
        }
    }
    
    // Định dạng tốc độ mạng

    func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond >= 1_000_000_000 {
            return String(format: "%.1f GB/s", bytesPerSecond / 1_000_000_000)
        } else if bytesPerSecond >= 1_000_000 {
            return String(format: "%.1f MB/s", bytesPerSecond / 1_000_000)
        } else if bytesPerSecond >= 1_000 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1_000)
        } else {
            return String(format: "%.0f B/s", bytesPerSecond)
        }
    }

    private func refreshSamplingSchedule(runImmediately: Bool) {
        guard isMonitoring else { return }
        
        configureTimer(&gpuTimer, enabled: samplingNeeds.gpu, interval: menuBarSamplingConfiguration.interval(for: .gpu), runImmediately: runImmediately) { [weak self] in
            self?.sampleGPUUsage()
        }
        
        configureTimer(&cpuTimer, enabled: samplingNeeds.cpu, interval: menuBarSamplingConfiguration.interval(for: .cpu), runImmediately: runImmediately) { [weak self] in
            self?.sampleCPUUsage()
        }
        
        configureTimer(&memoryTimer, enabled: samplingNeeds.memory, interval: menuBarSamplingConfiguration.interval(for: .memory), runImmediately: runImmediately) { [weak self] in
            self?.sampleMemoryUsage(includeDetailedStats: self?.samplingNeeds.detailedMemory ?? false)
        }
        
        configureTimer(&networkTimer, enabled: samplingNeeds.network, interval: menuBarSamplingConfiguration.interval(for: .network), runImmediately: runImmediately) { [weak self] in
            self?.sampleNetworkUsage(includeDetails: self?.samplingNeeds.networkDetails ?? false)
        }
        
        configureTimer(&batteryTimer, enabled: samplingNeeds.battery, interval: menuBarSamplingConfiguration.interval(for: .battery), runImmediately: runImmediately) { [weak self] in
            self?.sampleBatteryStatus(includeDetails: self?.samplingNeeds.batteryDetails ?? false)
        }
        
        configureTimer(&processTimer, enabled: samplingNeeds.processDetails, interval: menuBarSamplingConfiguration.interval(for: .processes), runImmediately: runImmediately) { [weak self] in
            self?.fetchUserProcesses()
        }
        
        configureTimer(&alertTimer, enabled: samplingNeeds.highMemoryAlerts, interval: menuBarSamplingConfiguration.interval(for: .alerts), runImmediately: runImmediately) { [weak self] in
            self?.sampleMemoryUsage(includeDetailedStats: false)
            self?.checkHighMemoryApps()
        }
    }
    
    private func configureTimer(
        _ timer: inout Timer?,
        enabled: Bool,
        interval: TimeInterval,
        runImmediately: Bool,
        action: @escaping () -> Void
    ) {
        timer?.invalidate()
        timer = nil
        
        guard enabled else { return }
        
        if runImmediately {
            action()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            action()
        }
    }
    
    private func sampleCPUUsage() {
        let cpuTask = Process()
        cpuTask.launchPath = "/bin/bash"
        cpuTask.arguments = ["-c", "ps -A -o %cpu | awk '{s+=$1} END {print s}'"]
        
        let pipe = Pipe()
        cpuTask.standardOutput = pipe
        
        do {
            try cpuTask.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               let totalCPU = Double(output) {
                let coreCount = Double(ProcessInfo.processInfo.activeProcessorCount)
                let cpuUsageValue = min((totalCPU / coreCount) / 100.0, 1.0)
                
                Task {
                    await self.uiUpdater.batch {
                        self.cpuUsage = cpuUsageValue
                    }
                }
            }
        } catch {
            print("CPU Scan Error: \(error)")
        }
    }

    private func sampleGPUUsage() {
        let gpuTask = Process()
        gpuTask.launchPath = "/usr/sbin/ioreg"
        gpuTask.arguments = ["-r", "-d", "1", "-w", "0", "-c", "IOAccelerator"]
        
        let pipe = Pipe()
        gpuTask.standardOutput = pipe
        
        do {
            try gpuTask.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let deviceUtilization = extractIntegerValue(for: "\"Device Utilization %\"", in: output)
                let rendererUtilization = extractIntegerValue(for: "\"Renderer Utilization %\"", in: output)
                let tilerUtilization = extractIntegerValue(for: "\"Tiler Utilization %\"", in: output)
                let usage = deviceUtilization ?? max(rendererUtilization ?? 0, tilerUtilization ?? 0)
                let name = extractQuotedValue(for: "\"model\"", in: output) ?? gpuName
                
                Task {
                    await self.uiUpdater.batch {
                        self.gpuUsage = Double(usage) / 100.0
                        self.gpuName = name
                    }
                }
            }
        } catch {
            print("GPU Scan Error: \(error)")
        }
    }
    
    private func extractIntegerValue(for key: String, in output: String) -> Int? {
        guard let keyRange = output.range(of: key) else { return nil }
        let tail = output[keyRange.upperBound...]
        guard let match = tail.range(of: "\\d+", options: .regularExpression) else { return nil }
        return Int(tail[match])
    }
    
    private func extractQuotedValue(for key: String, in output: String) -> String? {
        guard let keyRange = output.range(of: key) else { return nil }
        let tail = output[keyRange.upperBound...]
        guard let firstQuote = tail.firstIndex(of: "\"") else { return nil }
        let afterFirstQuote = tail.index(after: firstQuote)
        guard let secondQuote = tail[afterFirstQuote...].firstIndex(of: "\"") else { return nil }
        return String(tail[afterFirstQuote..<secondQuote])
    }
    
    private func sampleMemoryUsage(includeDetailedStats: Bool) {
        let memTask = Process()
        memTask.launchPath = "/usr/bin/vm_stat"
        
        let memPipe = Pipe()
        memTask.standardOutput = memPipe
        
        do {
            try memTask.run()
            let data = memPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: "\n")
                var pageSize: UInt64 = 16384
                var pagesActive: UInt64 = 0
                var pagesInactive: UInt64 = 0
                var pagesSpeculative: UInt64 = 0
                var pagesWired: UInt64 = 0
                var pagesCompressed: UInt64 = 0
                
                for line in lines {
                    if line.contains("page size of") {
                        if let match = line.range(of: "\\d+", options: .regularExpression),
                           let size = UInt64(line[match]) {
                            pageSize = size
                        }
                    } else if line.hasPrefix("Pages active:") {
                        pagesActive = extractPageCount(line)
                    } else if line.hasPrefix("Pages inactive:") {
                        pagesInactive = extractPageCount(line)
                    } else if line.hasPrefix("Pages speculative:") {
                        pagesSpeculative = extractPageCount(line)
                    } else if line.hasPrefix("Pages wired down:") {
                        pagesWired = extractPageCount(line)
                    } else if line.hasPrefix("Pages occupied by compressor:") {
                        pagesCompressed = extractPageCount(line)
                    }
                }
                
                let totalRAM = ProcessInfo.processInfo.physicalMemory
                let usedPages = pagesActive + pagesWired + pagesCompressed + pagesSpeculative
                let usedRAM = usedPages * pageSize
                
                let memoryUsageValue = Double(usedRAM) / Double(totalRAM)
                let memoryUsedStringValue = ByteCountFormatter.string(fromByteCount: Int64(usedRAM), countStyle: .memory)
                let memoryTotalStringValue = ByteCountFormatter.string(fromByteCount: Int64(totalRAM), countStyle: .memory)
                
                Task {
                    await self.uiUpdater.batch {
                        self.memoryUsage = memoryUsageValue
                        self.memoryUsedString = memoryUsedStringValue
                        self.memoryTotalString = memoryTotalStringValue
                    }
                }
                
                if includeDetailedStats {
                    self.updateDetailedStats(
                        pagesActive: pagesActive + pagesInactive + pagesSpeculative,
                        pagesWired: pagesWired,
                        pagesCompressed: pagesCompressed,
                        pageSize: pageSize,
                        totalRAM: totalRAM
                    )
                }
            }
        } catch {
            print("Memory Scan Error: \(error)")
        }
    }
    
    private func sampleNetworkUsage(includeDetails: Bool) {
        let netTask = Process()
        netTask.launchPath = "/bin/bash"
        netTask.arguments = ["-c", "netstat -ib | awk '/en0/ && $7 > 0 {print $7, $10; exit}'"]
        
        let netPipe = Pipe()
        netTask.standardOutput = netPipe
        
        do {
            try netTask.run()
            let data = netPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty {
                let parts = output.components(separatedBy: " ").filter { !$0.isEmpty }
                if parts.count >= 2,
                   let bytesIn = UInt64(parts[0]),
                   let bytesOut = UInt64(parts[1]) {
                    
                    let now = Date()
                    let timeDiff = now.timeIntervalSince(lastNetworkCheck)
                    
                    if timeDiff > 0 && lastBytesReceived > 0 {
                        let downloadDelta = bytesIn > lastBytesReceived ? Double(bytesIn - lastBytesReceived) : 0
                        let uploadDelta = bytesOut > lastBytesSent ? Double(bytesOut - lastBytesSent) : 0
                        
                        let downloadRate = downloadDelta / timeDiff
                        let uploadRate = uploadDelta / timeDiff
                        let totalDownloadStr = ByteCountFormatter.string(fromByteCount: Int64(bytesIn), countStyle: .file)
                        let totalUploadStr = ByteCountFormatter.string(fromByteCount: Int64(bytesOut), countStyle: .file)
                        
                        Task {
                            await self.uiUpdater.batch {
                                self.downloadSpeed = downloadRate
                                self.uploadSpeed = uploadRate
                                self.totalDownload = totalDownloadStr
                                self.totalUpload = totalUploadStr
                                self.downloadSpeedHistory.removeFirst()
                                self.downloadSpeedHistory.append(downloadRate)
                                self.uploadSpeedHistory.removeFirst()
                                self.uploadSpeedHistory.append(uploadRate)
                            }
                        }
                    }
                    
                    lastBytesReceived = bytesIn
                    lastBytesSent = bytesOut
                    lastNetworkCheck = now
                }
            }
        } catch {
            print("Network Scan Error: \(error)")
        }
        
        if includeDetails {
            fetchWiFiInfo()
            updateConnectionDuration()
        }
    }
    
    private func sampleBatteryStatus(includeDetails: Bool) {
        updateBatteryStatus()
        if includeDetails {
            updateBatteryDetails()
        }
    }
    
    // Fetch WiFi Info using airport utility
    private func fetchWiFiInfo() {
        let task = Process()
        task.launchPath = "/bin/bash"
        // Use standard path for airport utility on macOS
        task.arguments = ["-c", "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk -F': ' '/ SSID/ {print $2}'"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                Task {
                    await uiUpdater.batch {
                        self.wifiSSID = output
                    }
                }
            } else {
                 Task {
                    await uiUpdater.batch {
                        self.wifiSSID = "Wi-Fi Not Connected"
                    }
                }
            }
        } catch {
             // Fallback
        }
    }
    
    private func updateConnectionDuration() {
        let duration = Date().timeIntervalSince(connectionStartTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        let connectionDurationValue = String(format: "%d giờ %d phút %d giây", hours, minutes, seconds)
        
        Task {
            await uiUpdater.batch {
                self.connectionDuration = connectionDurationValue
            }
        }
    }
    
    private func updateBatteryStatus() {
        // Use pmset -g batt
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["-g", "batt"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Example output:
                // Now drawing from 'AC Power'
                // -InternalBattery-0 (id=1234567)	98%; charging; 0:10 remaining present: true
                
                let lines = output.components(separatedBy: "\n")
                if lines.count >= 2 {
                    let statusLine = lines[1]
                    
                    // Parse Percentage
                    var batteryLevelValue: Double = 1.0
                    var isChargingValue = false
                    var batteryStateValue = "Không xác định"
                    
                    if let range = statusLine.range(of: "\\d+%", options: .regularExpression) {
                        let percentString = String(statusLine[range]).dropLast()
                        if let percent = Double(percentString) {
                            batteryLevelValue = percent / 100.0
                        }
                    }
                    
                    // Parse Charging State
                    if output.contains("AC Power") {
                        isChargingValue = true
                        if statusLine.contains("charging") {
                            batteryStateValue = "Đang sạc"
                        } else {
                            batteryStateValue = "Đã cắm nguồn"
                        }
                    } else {
                        isChargingValue = false
                        batteryStateValue = "Đang dùng pin"
                    }
                    
                    // Batch battery status update
                    Task {
                        await self.uiUpdater.batch {
                            self.batteryLevel = batteryLevelValue
                            self.isCharging = isChargingValue
                            self.batteryState = batteryStateValue
                        }
                    }
                }
            }
        } catch {
            print("Battery Scan Error: \(error)")
        }
    }
    

    func checkHighMemoryApps() {
        // Kiểm tra xem trong khi tạm dừng

        if let snoozedUntil = snoozedUntil, Date() < snoozedUntil {
            return  // Không phát hiện được khi tạm dừng
        }
        
        // Use ps to get pid and rss
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "ps -aceo pid,rss,comm"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: "\n")
                // Skip header (PID RSS COMM)
                
                var maxRSS: Double = 0
                var maxPID: pid_t = 0
                var maxName: String = ""
                
                for line in lines.dropFirst() {
                    let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if parts.count >= 3 {
                        if let pid = pid_t(parts[0]),
                           let rssKB = Double(parts[1]) {
                            
                            // Check ignore list and self
                            if pid == ProcessInfo.processInfo.processIdentifier { continue }
                            if ignoredPids.contains(pid) { continue }
                            
                            // Nhận tên ứng dụng để kiểm tra danh sách bỏ qua vĩnh viễn

                            let tempName = parts[2...].joined(separator: " ")
                            var appName = tempName
                            if let app = NSRunningApplication(processIdentifier: pid) {
                                appName = app.localizedName ?? tempName
                            }
                            
                            // Kiểm tra xem nó có nằm trong danh sách bỏ qua vĩnh viễn không

                            if permanentlyIgnoredApps.contains(appName) {
                                continue
                            }
                                                        
                            let rssGB = rssKB / 1024.0 / 1024.0
                            
                            if rssGB > memoryThresholdGB && rssGB > maxRSS {
                                maxRSS = rssGB
                                maxPID = pid
                                maxName = appName
                            }
                        }
                    }
                }
                
                if maxRSS > 0 {
                    // Batch high memory app update
                    Task {
                        await self.uiUpdater.batch { [weak self] in
                            guard let self = self else { return }
                            // Only update if it's a new alert or different app
                            if self.highMemoryApp?.id != maxPID {
                                var appIcon: NSImage?
                                
                                if let app = NSRunningApplication(processIdentifier: maxPID) {
                                    appIcon = app.icon
                                }
                                
                                self.highMemoryApp = HighMemoryApp(id: maxPID, name: maxName, usage: maxRSS, icon: appIcon)
                                self.showHighMemoryAlert = true
                            }
                        }
                    }
                }
            }
        } catch {
            print("Process Scan Error: \(error)")
        }
    }
    
    func ignoreCurrentHighMemoryApp() {
        if let app = highMemoryApp {
            ignoredPids.insert(app.id)
            
            Task {
                await uiUpdater.batch {
                    self.highMemoryApp = nil
                    self.showHighMemoryAlert = false
                }
            }
        }
    }
    
    /// Tạm dừng cảnh báo bộ nhớ trong một khoảng thời gian (nhắc nhở theo lịch trình)

    /// - Tham số phút: Số phút tạm dừng

    func snoozeAlert(minutes: Int) {
        snoozedUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
        
        // Tạm thời tắt cảnh báo hiện tại

        Task {
            await uiUpdater.batch {
                self.highMemoryApp = nil
                self.showHighMemoryAlert = false
            }
        }
        
        print("[MemoryMonitor] Snoozed for \(minutes) minutes until \(snoozedUntil!)")
    }
    
    /// Bỏ qua vĩnh viễn ứng dụng có bộ nhớ cao hiện tại

    func ignoreAppPermanently() {
        guard let app = highMemoryApp else { return }
        
        // Thêm vào danh sách bỏ qua vĩnh viễn

        permanentlyIgnoredApps.insert(app.name)
        saveIgnoredApps()
        
        // Tắt cảnh báo

        Task {
            await uiUpdater.batch {
                self.highMemoryApp = nil
                self.showHighMemoryAlert = false
            }
        }
        
        print("[MemoryMonitor] Permanently ignored app: \(app.name)")
    }
    
    /// Xóa vĩnh viễn các ứng dụng bị bỏ qua (đối với giao diện cài đặt)

    /// - Tham số appName: tên ứng dụng

    func removeFromIgnoredApps(_ appName: String) {
        permanentlyIgnoredApps.remove(appName)
        saveIgnoredApps()
    }
    
    /// Nhận danh sách tất cả các ứng dụng bị bỏ qua vĩnh viễn

    func getIgnoredApps() -> [String] {
        return Array(permanentlyIgnoredApps).sorted()
    }
    
    /// Xóa tất cả các ứng dụng bị bỏ qua vĩnh viễn

    func clearAllIgnoredApps() {
        permanentlyIgnoredApps.removeAll()
        saveIgnoredApps()
    }
    
    func terminateHighMemoryApp() {
        guard let app = highMemoryApp else { return }
        forceQuitProcess(app.id, dismissAlert: true)
    }
    
    func forceQuitProcess(_ pid: pid_t, dismissAlert: Bool = false) {
        if let runningApp = NSRunningApplication(processIdentifier: pid) {
            _ = runningApp.forceTerminate()
        } else {
            let killTask = Process()
            killTask.launchPath = "/bin/kill"
            killTask.arguments = ["-9", "\(pid)"]
            try? killTask.run()
        }
        
        ignoredPids.insert(pid)
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            if dismissAlert {
                await uiUpdater.batch {
                    if self.highMemoryApp?.id == pid {
                        self.highMemoryApp = nil
                        self.showHighMemoryAlert = false
                    }
                }
            }
            
            self.fetchUserProcesses()
            self.checkHighMemoryApps()
        }
    }
    
    // Detailed Stats
    @Published var systemUptime: TimeInterval = 0
    @Published var memoryApp: Double = 0
    @Published var memoryWired: Double = 0
    @Published var memoryCompressed: Double = 0
    @Published var memoryPressure: Double = 0.0 // Percentage
    @Published var memorySwapUsed: String = "0 B"
    @Published var memorySwapTotal: String = "0 B"
    @Published var batteryHealth: String = "Good"
    @Published var batteryCycleCount: Int = 0
    @Published var batteryCondition: String = "Normal"
    
    // ... existing extractPageCount ...
    private func extractPageCount(_ line: String) -> UInt64 {
        let parts = line.components(separatedBy: ":")
        if parts.count == 2 {
            let numberPart = parts[1].replacingOccurrences(of: ".", with: "").trimmingCharacters(in: .whitespaces)
            return UInt64(numberPart) ?? 0
        }
        return 0
    }
    
    // Add logic to updateStats
    private func updateDetailedStats(pagesActive: UInt64, pagesWired: UInt64, pagesCompressed: UInt64, pageSize: UInt64, totalRAM: UInt64) {
        let memoryAppValue = Double(pagesActive * pageSize) / Double(totalRAM)
        let memoryWiredValue = Double(pagesWired * pageSize) / Double(totalRAM)
        let memoryCompressedValue = Double(pagesCompressed * pageSize) / Double(totalRAM)
        
        // Uptime
        var boottime = timeval()
        var size = MemoryLayout<timeval>.stride
        var systemUptimeValue: TimeInterval = 0
        if sysctlbyname("kern.boottime", &boottime, &size, nil, 0) == 0 {
            let bootDate = Date(timeIntervalSince1970: Double(boottime.tv_sec) + Double(boottime.tv_usec) / 1_000_000.0)
            systemUptimeValue = Date().timeIntervalSince(bootDate)
        }
        
        // Batch detailed stats update
        Task {
            await self.uiUpdater.batch {
                self.memoryApp = memoryAppValue
                self.memoryWired = memoryWiredValue
                self.memoryCompressed = memoryCompressedValue
                self.systemUptime = systemUptimeValue
            }
        }
        
        updateMemoryPressureAndSwap()
    }
    
    private func updateMemoryPressureAndSwap() {
        // Memory Pressure
        let pressureTask = Process()
        pressureTask.launchPath = "/usr/bin/memory_pressure"
        pressureTask.arguments = ["-Q"]
        
        let pressurePipe = Pipe()
        pressureTask.standardOutput = pressurePipe
        
        DispatchQueue.global(qos: .background).async {
            do {
                try pressureTask.run()
                let data = pressurePipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    // Output: "System-wide memory free percentage: 48%"
                    if let range = output.range(of: "\\d+%", options: .regularExpression) {
                        let percentString = String(output[range]).dropLast()
                        if let freePercent = Double(percentString) {
                            let memoryPressureValue = (100.0 - freePercent) / 100.0
                            
                            // Batch pressure update
                            Task {
                                await self.uiUpdater.batch {
                                    self.memoryPressure = memoryPressureValue
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Memory Pressure Error: \(error)")
            }
        }
        
        // Swap Usage
        // sysctl vm.swapusage
        let swapTask = Process()
        swapTask.launchPath = "/usr/sbin/sysctl"
        swapTask.arguments = ["vm.swapusage"]
        
        let swapPipe = Pipe()
        swapTask.standardOutput = swapPipe
        
        DispatchQueue.global(qos: .background).async {
            do {
                try swapTask.run()
                let data = swapPipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    // vm.swapusage: total = 5120.00M  used = 4426.56M  free = 693.44M  (encrypted)
                    let components = output.components(separatedBy: " ")
                    var usedStr = ""
                    
                    for (index, comp) in components.enumerated() {
                        if comp == "used" && index + 2 < components.count {
                             // index+1 is "=", index+2 is value
                             usedStr = components[index + 2]
                        }
                    }
                    
                    // Batch swap update
                    if !usedStr.isEmpty {
                        Task {
                            await self.uiUpdater.batch {
                                self.memorySwapUsed = usedStr
                            }
                        }
                    }
                }
            } catch {
                print("Swap Usage Error: \(error)")
            }
        }
    }
    
    private func updateBatteryDetails() {
         let task = Process()
         task.launchPath = "/usr/sbin/system_profiler"
         task.arguments = ["SPPowerDataType"]
         
         let pipe = Pipe()
         task.standardOutput = pipe
         
         // Run asynchronously to avoid blocking main thread heavy task
         DispatchQueue.global(qos: .background).async {
             do {
                 try task.run()
                 let data = pipe.fileHandleForReading.readDataToEndOfFile()
                 if let output = String(data: data, encoding: .utf8) {
                     // Parse Cycle Count and Condition
                     // "Cycle Count: 123"
                     // "Condition: Normal"
                     var cycleCount = 0
                     var condition = "Normal"
                     var maxCapacity = 100
                     
                     let lines = output.components(separatedBy: "\n")
                     for line in lines {
                         if line.contains("Cycle Count:") {
                             if let val = Int(line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "") {
                                 cycleCount = val
                             }
                         } else if line.contains("Condition:") {
                             condition = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "Normal"
                         } else if line.contains("Maximum Capacity:") {
                              if let val = Int(line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "%", with: "") ?? "") {
                                 maxCapacity = val
                             }
                         }
                     }
                     
                     // Batch battery details update
                     Task {
                         await self.uiUpdater.batch {
                             self.batteryCycleCount = cycleCount
                             self.batteryCondition = condition
                             self.batteryHealth = "\(maxCapacity)%"
                         }
                     }
                 }
             } catch {
                 print("Battery Detail Error: \(error)")
             }
    }
    
    func formatSpeed(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true
        return formatter.string(fromByteCount: Int64(bytes)) + "/s"
    }
}
}
