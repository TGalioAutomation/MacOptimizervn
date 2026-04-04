import SwiftUI

struct MenuBarDetailContainer: View {
    @ObservedObject var manager: MenuBarManager
    @ObservedObject var systemMonitor: SystemMonitorService
    var route: MenuBarRoute
    
    private var detailSize: CGSize {
        switch route {
        case .customization:
            return CGSize(width: 332, height: 560)
        default:
            return CGSize(width: 360, height: 620)
        }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "1C0C24").ignoresSafeArea()
            
            switch route {
            case .storage:
                StorageDetailView(manager: manager)
            case .memory:
                MemoryDetailView(manager: manager, systemMonitor: systemMonitor)
            case .battery:
                BatteryDetailView(manager: manager, systemMonitor: systemMonitor)
            case .cpu:
                CPUDetailView(manager: manager, systemMonitor: systemMonitor)
            case .network:
                NetworkDetailView(manager: manager, systemMonitor: systemMonitor)
            case .customization:
                MenuBarCustomizationView(manager: manager)
            default:
                EmptyView()
            }
        }
        .frame(width: detailSize.width, height: detailSize.height)
    }
}
