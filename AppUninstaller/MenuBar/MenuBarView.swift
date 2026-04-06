import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var manager: MenuBarManager
    @EnvironmentObject var systemMonitor: SystemMonitorService
    
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    @State private var selectedFooterShortcut: FooterShortcut = .home
    
    var body: some View {
        ZStack {
            menuBarBackground
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    proposalsSection
                    overviewSection
                    widgetGrid
                    footerBar
                }
                .padding(14)
                .padding(.bottom, 6)
            }
            
            if systemMonitor.showHighMemoryAlert {
                VStack {
                    MemoryAlertView(systemMonitor: systemMonitor, openAppAction: {
                        manager.openMainApp()
                    })
                    Spacer()
                }
                .padding(.top, 70)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(20)
            }
        }
        .frame(width: 390, height: 690)
        .background(Color.black)
    }
    
    private var menuBarBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "07111F"), Color(hex: "090611"), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Circle()
                .fill(Color(hex: "2CB7FF").opacity(0.28))
                .blur(radius: 70)
                .frame(width: 220, height: 220)
                .offset(x: -120, y: -210)
            
            Circle()
                .fill(Color(hex: "8D34FF").opacity(0.24))
                .blur(radius: 90)
                .frame(width: 240, height: 240)
                .offset(x: 40, y: -150)
            
            Circle()
                .fill(Color(hex: "2CB7FF").opacity(0.18))
                .blur(radius: 85)
                .frame(width: 220, height: 220)
                .offset(x: 110, y: 90)
            
            Circle()
                .fill(Color(hex: "FFB46B").opacity(0.20))
                .blur(radius: 70)
                .frame(width: 120, height: 120)
                .offset(x: 70, y: -10)
        }
    }
    
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Bảng điều khiển hệ thống")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Theo dõi nhanh, dọn dẹp tức thì và kiểm tra trạng thái máy ngay trên thanh menu.")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.58))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: {
                manager.showDetail(route: .customization)
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.78))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
    
    private var proposalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Đề xuất")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ProposalCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Cập nhật ứng dụng để nhận tính năng mới và bản vá ổn định.",
                    buttonTitle: "Cập nhật",
                    buttonColors: [Color(hex: "FFE76A"), Color(hex: "FFC936")],
                    glowColor: Color(hex: "2CB7FF").opacity(0.28),
                    action: {
                        manager.openMainApp(module: .updater)
                    }
                )
                
                ProposalCard(
                    icon: "brain.head.profile",
                    title: "Xem model Ollama và LM Studio đang chiếm bao nhiêu GB, rồi xóa nhanh khi cần.",
                    buttonTitle: "Model AI",
                    buttonColors: [Color(hex: "7DEBCE"), Color(hex: "4DB7FF")],
                    glowColor: Color(hex: "8D34FF").opacity(0.26),
                    action: {
                        selectedFooterShortcut = .clean
                        manager.openMainApp(module: .aiModels)
                    }
                )
            }
        }
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tổng quan hệ thống")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "6EFFA7"), Color(hex: "36D06A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: Color(hex: "6EFFA7").opacity(0.3), radius: 18, y: 8)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.55))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Thiết bị được bảo vệ")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("MacOptimizer đang bảo vệ hệ thống")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.88))
                    Text("Bảo vệ thời gian thực và giám sát nền đang hoạt động.")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.58))
                }
                
                Spacer()
            }
            .padding(14)
            .menuBarGlassCard(cornerRadius: 26)
        }
    }
    
    private var widgetGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            StorageWidget()
                .onTapGesture { manager.showDetail(route: .storage) }
            MemoryWidget(systemMonitor: systemMonitor)
                .onTapGesture { manager.showDetail(route: .memory) }
            BatteryWidget(systemMonitor: systemMonitor)
                .onTapGesture { manager.showDetail(route: .battery) }
            CPUWidget(systemMonitor: systemMonitor)
                .onTapGesture { manager.showDetail(route: .cpu) }
            NetworkWidget(systemMonitor: systemMonitor)
                .onTapGesture { manager.showDetail(route: .network) }
            ConnectedDevicesWidget()
                .onTapGesture { manager.openMainApp() }
        }
    }
    
    private var footerBar: some View {
        HStack(spacing: 8) {
            FooterNavItem(icon: "house.fill", title: "Trang chủ", isActive: selectedFooterShortcut == .home) {
                selectedFooterShortcut = .home
                manager.openMainApp(module: .smartClean)
            }
            FooterNavItem(icon: "sparkles", title: "Dọn", isActive: selectedFooterShortcut == .clean) {
                selectedFooterShortcut = .clean
                manager.showDetail(route: .forceQuitApps)
            }
            FooterNavItem(icon: "bolt.fill", title: "Tăng tốc", isActive: selectedFooterShortcut == .boost) {
                selectedFooterShortcut = .boost
                manager.openMainApp(module: .optimizer)
            }
            FooterNavItem(icon: "checkmark.shield.fill", title: "Bảo vệ", isActive: selectedFooterShortcut == .protect) {
                selectedFooterShortcut = .protect
                manager.openMainApp(module: .malware)
            }
            FooterNavItem(icon: "gearshape.fill", title: "Cài đặt", isActive: selectedFooterShortcut == .settings) {
                selectedFooterShortcut = .settings
                manager.showDetail(route: .customization)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .menuBarGlassCard(cornerRadius: 24)
    }
}

private enum FooterShortcut {
    case home
    case clean
    case boost
    case protect
    case settings
}

private struct ProposalCard: View {
    let icon: String
    let title: String
    let buttonTitle: String
    let buttonColors: [Color]
    let glowColor: Color
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                glowColor
                    .blur(radius: 30)
                    .frame(width: 88, height: 88)
                    .offset(x: 12, y: 24)
                
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 52, height: 52)
                    Spacer()
                }
            }
            .frame(height: 52)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 0)
            
            Button(action: action) {
                MenuBarPrimaryPillButton(title: buttonTitle, colors: buttonColors)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 162, alignment: .topLeading)
        .menuBarGlassCard()
    }
}

private struct FooterNavItem: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isActive ? .white : .white.opacity(0.45))
                Text(title)
                    .font(.system(size: 10, weight: isActive ? .semibold : .medium))
                    .foregroundColor(isActive ? .white : .white.opacity(0.45))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isActive ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }
}

struct MenuBarAlertView: View {
    @ObservedObject var systemMonitor: SystemMonitorService
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = systemMonitor.highMemoryApp?.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(systemMonitor.highMemoryApp?.name ?? "Ứng dụng không rõ")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text("Đang dùng nhiều bộ nhớ (\(String(format: "%.1f", systemMonitor.highMemoryApp?.usage ?? 0)) GB)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button("Giải phóng") {
                withAnimation {
                    systemMonitor.terminateHighMemoryApp()
                }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .cornerRadius(6)
            
            Button(action: {
                withAnimation {
                    systemMonitor.ignoreCurrentHighMemoryApp()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(Color(hex: "2C2C3E"))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal, 10)
    }
}
