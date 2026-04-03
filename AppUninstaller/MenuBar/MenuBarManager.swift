import SwiftUI
import AppKit
import Combine

enum MenuBarStatusMetric: String, CaseIterable, Identifiable {
    case gpu
    case storage
    case memory
    case cpu
    case network
    case battery
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .gpu: return "GPU"
        case .storage: return "Ổ đĩa"
        case .memory: return "RAM"
        case .cpu: return "CPU"
        case .network: return "Mạng"
        case .battery: return "Pin"
        }
    }
    
    var tooltipDescription: String {
        switch self {
        case .gpu: return "Mức tải GPU hiện tại"
        case .storage: return "Dung lượng trống và đã dùng của ổ đĩa"
        case .memory: return "Phần trăm RAM đang được sử dụng"
        case .cpu: return "Mức tải CPU hiện tại"
        case .network: return "Tốc độ tải xuống và tải lên hiện tại"
        case .battery: return "Phần trăm pin hiện tại"
        }
    }
    
    var symbolName: String {
        switch self {
        case .gpu: return "square.3.layers.3d.top.filled"
        case .storage: return "internaldrive"
        case .memory: return "memorychip"
        case .cpu: return "cpu"
        case .network: return "arrow.up.arrow.down"
        case .battery: return "battery.75"
        }
    }
}

public enum MenuBarRoute {
    case overview
    case storage
    case memory
    case battery
    case cpu
    case network
    case customization
}

class MenuBarManager: NSObject, ObservableObject {
    static let shared = MenuBarManager()
    
    var statusItem: NSStatusItem?
    var popoverWindow: MenuBarWindow?
    var detailWindow: MenuBarWindow?
    var memoryAlertController: MemoryAlertWindowController?
    
    // Shared Source of Truth
    var systemMonitor = SystemMonitorService()
    private let diskManager = DiskSpaceManager.shared
    
    @Published var isOpen: Bool = false
    @Published var currentDetailRoute: MenuBarRoute? = nil
    @Published var selectedStatusMetrics: [MenuBarStatusMetric] = [.gpu, .cpu, .storage, .memory]
    @Published var showsStatusIcon: Bool = true
    
    // Cờ đã hoàn thành khởi tạo hay chưa

    private var isSetupComplete = false
    private var cancellables = Set<AnyCancellable>()
    private var diskRefreshTimer: Timer?
    private let statusMetricsKey = "MenuBar.StatusMetrics"
    private let statusIconKey = "MenuBar.ShowsStatusIcon"
    private lazy var statusBarIconImage: NSImage? = {
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let customIcon = NSImage(contentsOfFile: iconPath) {
            customIcon.size = NSSize(width: 18, height: 18)
            customIcon.isTemplate = true
            return customIcon
        }
        let fallbackIcon = NSImage(systemSymbolName: "macpro.gen3", accessibilityDescription: "MacOptimizer")
        fallbackIcon?.isTemplate = true
        return fallbackIcon
    }()
    
    override init() {
        super.init()
        // Trì hoãn việc khởi tạo để đảm bảo ứng dụng được khởi động hoàn toàn trước khi tạo mục trạng thái

        // Điều này ngăn ngừa sự cố do truy cập NSStatusBar khi ứng dụng khởi động

        DispatchQueue.main.async { [weak self] in
            self?.performDelayedSetup()
        }
    }
    
    /// Cài đặt thực thi bị trì hoãn để đảm bảo NSApp được khởi tạo hoàn toàn

    private func performDelayedSetup() {
        guard !isSetupComplete else { return }
        isSetupComplete = true
        
        loadStatusBarPreferences()
        systemMonitor.configureMenuBarSampling(statusMetrics: selectedStatusMetrics, detailRoute: currentDetailRoute)
        setupStatusItem()
        setupWindow()
        bindStatusBarUpdates()
        systemMonitor.startMonitoring()
        setupAutoClose()
    }
    
    ///Phương thức công khai: Đảm bảo rằng cài đặt đã hoàn tất (đối với các trường hợp yêu cầu sử dụng ngay)

    func ensureSetup() {
        if !isSetupComplete {
            performDelayedSetup()
        }
    }
    
    private func setupStatusItem() {
        // Hãy chắc chắn rằng bạn đang ở trong luồng chính và NSApp đã sẵn sàng

        guard Thread.isMainThread, NSApp != nil else {
            print("[MenuBarManager] ⚠️ NSApp not ready, deferring status item setup")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.setupStatusItem()
            }
            return
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.action = #selector(toggleWindow)
            button.target = self
            updateStatusItemAppearance()
        }
    }
    
    private func setupWindow() {
        // Main Overview Window
        // Pass self as EnvironmentObject so Views can call showDetail/closeWindow
        let contentView = MenuBarView()
            .environmentObject(self)
            .environmentObject(systemMonitor)
            .edgesIgnoringSafeArea(.all)
        
        let hostingController = NSHostingController(rootView: contentView)
        let window = MenuBarWindow(contentViewController: hostingController)
        self.popoverWindow = window
        window.level = .floating
        
        // Khởi tạo bộ điều khiển cảnh báo bộ nhớ

        memoryAlertController = MemoryAlertWindowController(
            systemMonitor: systemMonitor,
            statusBarButton: statusItem?.button
        )
    }
    
    @objc func toggleWindow() {
        guard let _ = popoverWindow, let button = statusItem?.button else { return }
        
        if isOpen {
            closeWindow()
        } else {
            showWindow(relativeTo: button)
        }
    }
    
    private func showWindow(relativeTo button: NSStatusBarButton) {
        guard let window = popoverWindow else { return }
        
        // Position Logic
        let padding: CGFloat = 12
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowSize = window.frame.size
            
            let xPos = screenFrame.maxX - windowSize.width - padding
            let yPos = screenFrame.maxY - windowSize.height - 5
            
            window.setFrameOrigin(NSPoint(x: xPos, y: yPos))
        }
        
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        isOpen = true
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }
    }
    
    func closeWindow() {
        // Close Detail First
        closeDetail()
        
        guard let window = popoverWindow else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
            self.isOpen = false
        })
    }
    
    // MARK: - Detail Window Logic
    
    func showDetail(route: MenuBarRoute) {
        // If already open with same route, do nothing or maybe just bring to front
        if currentDetailRoute == route && detailWindow != nil { return }
        
        // Close existing detail if different
        if detailWindow != nil {
             // For smooth transition, maybe just update content?
             // But for now, let's close and reopen or just swap root view if possible.
             // Swapping controller is easier.
             updateDetailWindow(route: route)
             return
        }
        
        createAndShowDetailWindow(route: route)
    }
    
    func closeDetail() {
        guard let window = detailWindow else { return }
        currentDetailRoute = nil
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
            self.detailWindow = nil
        })
    }
    
    private func createAndShowDetailWindow(route: MenuBarRoute) {
        let detailView = MenuBarDetailContainer(manager: self, systemMonitor: systemMonitor, route: route)
            .edgesIgnoringSafeArea(.all)
        
        let controller = NSHostingController(rootView: detailView)
        let window = MenuBarWindow(contentViewController: controller)
        self.detailWindow = window
        self.currentDetailRoute = route
        window.level = .floating
        
        // Position: Left of Main Window
        if let mainWindow = popoverWindow {
            let mainFrame = mainWindow.frame
            let gap: CGFloat = 10
            // We need to fetch size from content or set fixed size. 
            // MenuBarDetailContainer has .frame(width: 320, height: 500)
            let detailWidth: CGFloat = 360 
            let detailHeight: CGFloat = 620
            
            // Should align tops? usually.
            // Or center vertically relative to main window?
            // Modern macOS apps usually align top or keep them side-by-side cleanly.
            // Let's align Tops for better visual consistency.
            // Main window height is usually dynamic or ~600.
            
            let xPos = mainFrame.minX - detailWidth - gap
            // Align Tops
            let yPos = mainFrame.maxY - detailHeight
            
            window.setFrame(NSRect(x: xPos, y: yPos, width: detailWidth, height: detailHeight), display: true)
        }
        
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }
    }
    
    private func updateDetailWindow(route: MenuBarRoute) {
        // Just replace the rootViewController
        guard let window = detailWindow else { return }
        
        let detailView = MenuBarDetailContainer(manager: self, systemMonitor: systemMonitor, route: route)
             .edgesIgnoringSafeArea(.all)
        let newController = NSHostingController(rootView: detailView)
        
        window.contentViewController = newController
        currentDetailRoute = route
    }
    
    // MARK: - Open Main App
    
    func openMainApp() {
        // Close menu bar windows
        closeWindow()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Find and show the main window
        // The main app window usually exists if app is running.
        // We need to bring it to front or open it.
        
        // Option 1: Find existing window by looking for ContentView or similar
        for window in NSApp.windows {
            // Skip our own menu bar windows
            if window == popoverWindow || window == detailWindow {
                continue
            }
            
            // Look for the main app window (usually the one with title or specific content)
            if window.contentViewController != nil && window.isVisible == false {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
            
            if window.contentViewController != nil {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
        
        // If no window found, just activate the app (it should open main window automatically)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension MenuBarManager {
    func toggleStatusMetric(_ metric: MenuBarStatusMetric) {
        if let existingIndex = selectedStatusMetrics.firstIndex(of: metric) {
            selectedStatusMetrics.remove(at: existingIndex)
        } else {
            selectedStatusMetrics.append(metric)
        }
    }
    
    func isStatusMetricEnabled(_ metric: MenuBarStatusMetric) -> Bool {
        selectedStatusMetrics.contains(metric)
    }
    
    func toggleStatusIcon() {
        showsStatusIcon.toggle()
    }
    
    func resetStatusBarPreferences() {
        selectedStatusMetrics = [.gpu, .cpu, .storage, .memory]
        showsStatusIcon = true
    }
    
    func setStatusMetrics(_ metrics: [MenuBarStatusMetric]) {
        selectedStatusMetrics = metrics
    }
    
    func moveStatusMetric(_ metric: MenuBarStatusMetric, direction: Int) {
        guard let currentIndex = selectedStatusMetrics.firstIndex(of: metric) else { return }
        let newIndex = currentIndex + direction
        guard selectedStatusMetrics.indices.contains(newIndex) else { return }
        selectedStatusMetrics.move(fromOffsets: IndexSet(integer: currentIndex), toOffset: direction > 0 ? newIndex + 1 : newIndex)
    }
    
    var statusMetricsSummary: String {
        if selectedStatusMetrics.isEmpty {
            return "Chỉ biểu tượng"
        }
        return selectedStatusMetrics.map(\.title).joined(separator: ", ")
    }
    
    var statusItemPreviewText: String {
        let segments = selectedStatusMetrics.map { formattedValueText(for: $0) }.filter { !$0.isEmpty }
        return segments.isEmpty ? "Chỉ biểu tượng" : segments.joined(separator: "   ")
    }
    
    var statusItemTooltipText: String {
        let lines = statusMetricDisplays.map { display in
            switch display.metric {
            case .gpu:
                return "\(display.metric.title): \(display.text) • \(systemMonitor.gpuName)"
            default:
                return "\(display.metric.title): \(display.text)"
            }
        }
        return lines.isEmpty ? "MacOptimizer" : lines.joined(separator: "\n")
    }
    
    private func loadStatusBarPreferences() {
        if let rawValues = UserDefaults.standard.array(forKey: statusMetricsKey) as? [String] {
            let metrics = rawValues.compactMap(MenuBarStatusMetric.init(rawValue:))
            if !metrics.isEmpty {
                selectedStatusMetrics = metrics
            }
        }
        if UserDefaults.standard.object(forKey: statusIconKey) != nil {
            showsStatusIcon = UserDefaults.standard.bool(forKey: statusIconKey)
        }
    }
    
    private func saveStatusBarPreferences() {
        UserDefaults.standard.set(selectedStatusMetrics.map(\.rawValue), forKey: statusMetricsKey)
        UserDefaults.standard.set(showsStatusIcon, forKey: statusIconKey)
    }
    
    private func bindStatusBarUpdates() {
        cancellables.removeAll()
        
        let refreshPublishers: [AnyPublisher<Void, Never>] = [
            systemMonitor.$gpuUsage.map { _ in () }.eraseToAnyPublisher(),
            systemMonitor.$cpuUsage.map { _ in () }.eraseToAnyPublisher(),
            systemMonitor.$memoryUsage.map { _ in () }.eraseToAnyPublisher(),
            systemMonitor.$downloadSpeed.map { _ in () }.eraseToAnyPublisher(),
            systemMonitor.$uploadSpeed.map { _ in () }.eraseToAnyPublisher(),
            systemMonitor.$batteryLevel.map { _ in () }.eraseToAnyPublisher(),
            diskManager.$freeSize.map { _ in () }.eraseToAnyPublisher(),
            diskManager.$usedSize.map { _ in () }.eraseToAnyPublisher(),
            $selectedStatusMetrics.map { _ in () }.eraseToAnyPublisher(),
            $showsStatusIcon.map { _ in () }.eraseToAnyPublisher(),
            $currentDetailRoute.map { _ in () }.eraseToAnyPublisher()
        ]
        
        Publishers.MergeMany(refreshPublishers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateStatusItemAppearance()
            }
            .store(in: &cancellables)
        
        $selectedStatusMetrics
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.systemMonitor.configureMenuBarSampling(statusMetrics: self.selectedStatusMetrics, detailRoute: self.currentDetailRoute)
                self.configureDiskRefreshTimer()
                self.saveStatusBarPreferences()
            }
            .store(in: &cancellables)
        
        $showsStatusIcon
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveStatusBarPreferences()
            }
            .store(in: &cancellables)
        
        $currentDetailRoute
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] route in
                guard let self = self else { return }
                self.systemMonitor.configureMenuBarSampling(statusMetrics: self.selectedStatusMetrics, detailRoute: route)
                self.configureDiskRefreshTimer()
            }
            .store(in: &cancellables)
        
        systemMonitor.$menuBarSamplingConfiguration
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.configureDiskRefreshTimer()
            }
            .store(in: &cancellables)
        
        configureDiskRefreshTimer()
    }

    private func configureDiskRefreshTimer() {
        diskRefreshTimer?.invalidate()
        diskRefreshTimer = nil
        
        let interval = max(systemMonitor.storageRefreshInterval, 5)
        diskRefreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.selectedStatusMetrics.contains(.storage) || self.currentDetailRoute == .storage {
                self.diskManager.updateDiskSpace()
                self.updateStatusItemAppearance()
            }
        }
    }
    
    private func updateStatusItemAppearance() {
        guard let button = statusItem?.button else { return }
        
        let displays = statusMetricDisplays
        let attributedTitle = makeStatusItemAttributedTitle(from: displays)
        let title = displays.map(\.text).joined(separator: "   ")
        
        button.image = showsStatusIcon ? statusBarIconImage : nil
        button.imagePosition = showsStatusIcon ? (title.isEmpty ? .imageOnly : .imageLeading) : .noImage
        button.attributedTitle = attributedTitle
        button.toolTip = statusItemTooltipText
        statusItem?.length = title.isEmpty ? NSStatusItem.squareLength : NSStatusItem.variableLength
    }
    
    struct StatusMetricDisplay: Identifiable {
        let metric: MenuBarStatusMetric
        let text: String
        var id: String { metric.rawValue }
    }
    
    var statusMetricDisplays: [StatusMetricDisplay] {
        selectedStatusMetrics.compactMap { metric in
            let text = formattedValueText(for: metric)
            guard !text.isEmpty else { return nil }
            return StatusMetricDisplay(metric: metric, text: text)
        }
    }
    
    private func formattedValueText(for metric: MenuBarStatusMetric) -> String {
        switch metric {
        case .gpu:
            return "\(Int(systemMonitor.gpuUsage * 100))%"
        case .storage:
            return "F:\(shortByteString(diskManager.freeSize)) U:\(shortByteString(diskManager.usedSize))"
        case .memory:
            return "\(Int(systemMonitor.memoryUsage * 100))%"
        case .cpu:
            return "\(Int(systemMonitor.cpuUsage * 100))%"
        case .network:
            return "↓\(shortSpeedString(systemMonitor.downloadSpeed)) ↑\(shortSpeedString(systemMonitor.uploadSpeed))"
        case .battery:
            return "\(Int(systemMonitor.batteryLevel * 100))%"
        }
    }

    private func makeStatusItemAttributedTitle(from displays: [StatusMetricDisplay]) -> NSAttributedString {
        let title = NSMutableAttributedString()
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]
        
        for (index, display) in displays.enumerated() {
            if index > 0 {
                title.append(NSAttributedString(string: "   ", attributes: textAttributes))
            }
            title.append(symbolAttachment(named: display.metric.symbolName))
            title.append(NSAttributedString(string: " ", attributes: textAttributes))
            title.append(NSAttributedString(string: display.text, attributes: textAttributes))
        }
        
        return title
    }

    private func symbolAttachment(named symbolName: String) -> NSAttributedString {
        guard let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
            return NSAttributedString(string: "")
        }
        
        image.isTemplate = true
        image.size = NSSize(width: 12, height: 12)
        
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = NSRect(x: 0, y: -2, width: 12, height: 12)
        return NSAttributedString(attachment: attachment)
    }
    
    private func shortByteString(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes).replacingOccurrences(of: " ", with: "")
    }
    
    private func shortSpeedString(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond >= 1_000_000_000 {
            return String(format: "%.1fG", bytesPerSecond / 1_000_000_000)
        } else if bytesPerSecond >= 1_000_000 {
            return String(format: "%.1fM", bytesPerSecond / 1_000_000)
        } else if bytesPerSecond >= 1_000 {
            return String(format: "%.0fK", bytesPerSecond / 1_000)
        } else {
            return String(format: "%.0fB", bytesPerSecond)
        }
    }
}

// Custom NSWindow with auto-close logic
class MenuBarWindow: NSWindow {
    init(contentViewController: NSViewController) {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .fullSizeContentView], 
            backing: .buffered,
            defer: false
        )
        
        self.contentViewController = contentViewController
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.isMovableByWindowBackground = false
        self.collectionBehavior = [.canJoinAllSpaces, .transient]
    }
    
    override var canBecomeKey: Bool { return true }
    
    // Auto-close handler needs to be managed by Manager via delegate or notification
    // But let's keep it simple: MenuBarManager will subscribe to interruptions.
}

extension MenuBarManager {
    func setupAutoClose() {
        // Monitor global clicks to close if clicked outside
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isOpen else { return event }
            
            if let window = event.window, (window == self.popoverWindow || window == self.detailWindow) {
                // Clicked inside one of our windows, do nothing
                return event
            }
            
            // Clicked outside?
            // "transient" collectionBehavior handles some of this, but not perfectly for custom windows.
            // Actually, the main issue usually is focus.
            
            // Let's rely on standard popup behavior: if user clicks elsewhere, we close.
            // But we have TWO windows.
            
            self.closeWindow()
            return event
        }
        
        // Also listen for ResignKey
        NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: nil, queue: .main) { [weak self] notification in
            guard let self = self, self.isOpen else { return }
            guard let resignedWindow = notification.object as? NSWindow else { return }
            
            // Only care if one of OUR windows resigned key
            if resignedWindow == self.popoverWindow || resignedWindow == self.detailWindow {
                // Check what the NEW key window is.
                // It might need a slight delay to be set?
                DispatchQueue.main.async {
                    let newKeyWindow = NSApp.keyWindow
                    
                    // If the new key window is one of ours, don't close.
                    if newKeyWindow == self.popoverWindow || newKeyWindow == self.detailWindow {
                        return
                    }
                    
                    // If we are still "active" app but focus shifted to maybe a dialog? 
                    // Or if user clicked desktop (newKeyWindow might be nil or Finder).
                    
                    // Simple rule: If neither of our windows is key, close.
                    self.closeWindow()
                }
            }
        }
        
        // Listen for App Deactivation (switching to another app)
        NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.closeWindow()
        }
    }
}
