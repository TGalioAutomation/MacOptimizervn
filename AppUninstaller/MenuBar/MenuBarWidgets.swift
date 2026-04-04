import SwiftUI

struct MenuBarGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.black.opacity(0.22))
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                }
            )
    }
}

extension View {
    func menuBarGlassCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(MenuBarGlassCardModifier(cornerRadius: cornerRadius))
    }
}

private struct MenuBarIconTile: View {
    let symbol: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.14))
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))
        }
        .frame(width: 48, height: 48)
    }
}

private struct MenuBarProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.18))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.82), Color.white.opacity(0.45)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(26, proxy.size.width * max(0.08, min(progress, 1.0))))
            }
        }
        .frame(height: 13)
    }
}

struct MenuBarPrimaryPillButton: View {
    let title: String
    let colors: [Color]
    
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.black.opacity(0.85))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
            .shadow(color: colors.first?.opacity(0.35) ?? .clear, radius: 10, y: 4)
    }
}

private struct MenuBarMetricCard: View {
    let icon: String
    let title: String
    let primaryText: String
    let secondaryText: String?
    let progress: Double?
    let actionTitle: String?
    let actionColors: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                MenuBarIconTile(symbol: icon)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text(primaryText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.88))
                }
                Spacer(minLength: 0)
            }
            
            if let progress {
                MenuBarProgressBar(progress: progress)
            }
            
            if let secondaryText {
                Text(secondaryText)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.72))
                    .lineLimit(2)
            }
            
            if let actionTitle {
                MenuBarPrimaryPillButton(title: actionTitle, colors: actionColors)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .menuBarGlassCard()
    }
}

struct StorageWidget: View {
    @ObservedObject var diskManager = DiskSpaceManager.shared
    
    var body: some View {
        MenuBarMetricCard(
            icon: "internaldrive.fill",
            title: "Dung lượng",
            primaryText: "\(shortBytes(diskManager.usedSize)) / \(shortBytes(diskManager.totalSize))",
            secondaryText: "Trống \(shortBytes(diskManager.freeSize))",
            progress: diskManager.usagePercentage,
            actionTitle: "Dọn ngay",
            actionColors: [Color(hex: "31D8FF"), Color(hex: "10A6E9")]
        )
    }
    
    private func shortBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useTB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes).replacingOccurrences(of: " ", with: " ")
    }
}

struct MemoryWidget: View {
    @ObservedObject var systemMonitor: SystemMonitorService
    
    var body: some View {
        MenuBarMetricCard(
            icon: "memorychip.fill",
            title: "Bộ nhớ",
            primaryText: "\(systemMonitor.memoryUsedString) / \(systemMonitor.memoryTotalString)",
            secondaryText: "Áp lực \(Int(systemMonitor.memoryPressure * 100))%",
            progress: systemMonitor.memoryUsage,
            actionTitle: "Giải phóng",
            actionColors: [Color(hex: "31D8FF"), Color(hex: "10A6E9")]
        )
    }
}

struct BatteryWidget: View {
    @ObservedObject var systemMonitor: SystemMonitorService
    
    var body: some View {
        MenuBarMetricCard(
            icon: systemMonitor.isCharging ? "battery.100.bolt" : "battery.100",
            title: "Pin",
            primaryText: "\(Int(systemMonitor.batteryLevel * 100))% còn lại",
            secondaryText: systemMonitor.batteryState,
            progress: nil,
            actionTitle: nil,
            actionColors: []
        )
        .frame(minHeight: 104)
    }
}

struct CPUWidget: View {
    @ObservedObject var systemMonitor: SystemMonitorService
    
    var body: some View {
        MenuBarMetricCard(
            icon: "cpu",
            title: "CPU",
            primaryText: "Mức dùng \(Int(systemMonitor.cpuUsage * 100))%",
            secondaryText: "Hoạt động \(formatUptime(systemMonitor.systemUptime))",
            progress: nil,
            actionTitle: nil,
            actionColors: []
        )
        .frame(minHeight: 104)
    }
    
    private func formatUptime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours) giờ \(minutes) phút"
    }
}

struct NetworkWidget: View {
    @ObservedObject var systemMonitor: SystemMonitorService
    
    var body: some View {
        MenuBarMetricCard(
            icon: "wifi",
            title: "Wi-Fi",
            primaryText: "Lưu lượng thời gian thực",
            secondaryText: "↑ \(systemMonitor.formatSpeed(systemMonitor.uploadSpeed))   ↓ \(systemMonitor.formatSpeed(systemMonitor.downloadSpeed))",
            progress: nil,
            actionTitle: nil,
            actionColors: []
        )
        .frame(minHeight: 104)
    }
}

struct ConnectedDevicesWidget: View {
    var body: some View {
        MenuBarMetricCard(
            icon: "display.2",
            title: "Thiết bị kết nối",
            primaryText: "1 thiết bị",
            secondaryText: "Menu bar MacOptimizer đang hoạt động",
            progress: nil,
            actionTitle: nil,
            actionColors: []
        )
        .frame(minHeight: 104)
    }
}
