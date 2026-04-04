import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var manager: MenuBarManager
    @EnvironmentObject var systemMonitor: SystemMonitorService
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: Recommendations
            VStack(alignment: .leading, spacing: 12) {
                Text("Đề xuất")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    RecommendationCard(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Cập nhật ứng dụng để nhận tính năng mới và độ ổn định cao hơn.",
                        buttonTitle: "Cập nhật ứng dụng"
                    )
                    
                    RecommendationCard(
                        icon: "puzzlepiece.extension",
                        title: "Quản lý plugin, widget và bảng tùy chọn.",
                        buttonTitle: "Quản lý tiện ích"
                    )
                }
            }
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [Color(hex: "4A0E4E"), Color(hex: "2E0836")]), startPoint: .topLeading, endPoint: .bottomTrailing))
            
            // Mac Overview
            VStack(alignment: .leading, spacing: 12) {
                Text("Tổng quan Mac")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Protection Status
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                    Text("Bảo vệ:")
                        .font(.system(size: 12))
                    Text("MacOptimizer")
                        .font(.system(size: 12, weight: .bold))
                    Spacer()
                    Text("An toàn")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color(white: 1.0, opacity: 0.05))
                .cornerRadius(8)
                .padding(.horizontal)
                
                // Real-time monitor (Mock)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Giám sát phần mềm độc hại thời gian thực đang bật")
                        .font(.system(size: 11, weight: .semibold))
                    HStack {
                        Text("Định dạng tệp quét gần nhất: GoogleUpdater")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    HStack {
                        Text("Lần kiểm tra cập nhật cơ sở dữ liệu gần nhất: 3 phút trước")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Kiểm tra ngay")
                            .font(.system(size: 10))
                            .underline()
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Widgets Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 20, height: 20)
                Spacer()
                Text("Mở MacOptimizer")
                    .font(.system(size: 12))
                    .onTapGesture {
                        manager.openMainApp()
                    }
                Spacer()
                Button(action: {
                    manager.showDetail(route: .customization)
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
        
            if systemMonitor.showHighMemoryAlert {
                MemoryAlertView(systemMonitor: systemMonitor, openAppAction: {
                    manager.openMainApp()
                })
                    .padding(.top, 10) // Positioned below the icon roughly
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color.black.opacity(0.01)) // Catch clicks outside if needed, or just let it overlay
            }
        }
        .frame(width: 380)
        .background(Color(hex: "1C0C24")) // Deep purple background
    }
}

// ... RecommendationCard and MenuBarAlertView remain same ...
struct RecommendationCard: View {
    let icon: String
    let title: String
    let buttonTitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.8))
            
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 40, alignment: .topLeading)
            
            Spacer()
            
            Text(buttonTitle)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow) // Warning highlight color
                .cornerRadius(4)
        }
        .padding(10)
        .frame(height: 120)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
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
        .background(Color(hex: "2C2C3E")) // Dark popup background
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal, 10)
    }
}
