import SwiftUI

struct MenuBarCustomizationView: View {
    @ObservedObject var manager: MenuBarManager
    @ObservedObject private var systemMonitor: SystemMonitorService
    @State private var selectedSection: CustomizerSection = .display
    
    private let compactColumns = [GridItem(.adaptive(minimum: 108), spacing: 8)]
    private let sectionTitleFont = Font.system(size: 14, weight: .semibold, design: .rounded)
    private let primaryBodyFont = Font.system(size: 12, weight: .regular)
    private let secondaryBodyFont = Font.system(size: 11, weight: .regular)
    private let itemTitleFont = Font.system(size: 13, weight: .semibold)
    private let badgeFont = Font.system(size: 12, weight: .semibold)
    
    init(manager: MenuBarManager) {
        self.manager = manager
        self._systemMonitor = ObservedObject(wrappedValue: manager.systemMonitor)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            sectionPicker
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    sectionContent
                }
                .padding(16)
            }
        }
        .background(Color(hex: "1C0C24"))
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tùy chỉnh thanh menu")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text("Chọn thông tin bạn muốn luôn nhìn thấy trên thanh menu.")
                    .font(primaryBodyFont)
                    .lineSpacing(1)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Button(action: {
                manager.closeDetail()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var sectionPicker: some View {
        HStack(spacing: 8) {
            ForEach(CustomizerSection.allCases) { section in
                Button(action: {
                    selectedSection = section
                }) {
                    Text(section.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(selectedSection == section ? .black.opacity(0.8) : .white.opacity(0.72))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(selectedSection == section ? Color.white.opacity(0.95) : Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .display:
            previewCard
            presetsCard
            selectedMetricsCard
            availableMetricsCard
        case .sampling:
            samplingProfilesCard
            samplingIntervalsCard
        case .options:
            customSamplingSummaryCard
            optionsCard
        }
    }
    
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Xem trước")
                .font(sectionTitleFont)
                .foregroundColor(.white)
            
            HStack(spacing: 10) {
                if let previewImage = manager.statusItemPreviewImage() {
                    Image(nsImage: previewImage)
                        .interpolation(.high)
                } else if manager.statusMetricDisplays.isEmpty {
                    Text("Chỉ biểu tượng")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(manager.statusMetricDisplays) { display in
                                HStack(spacing: 4) {
                                    Image(systemName: display.metric.symbolName)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                    Text(display.text)
                                        .font(.system(size: 12, weight: .medium))
                                        .monospacedDigit()
                                        .foregroundColor(.white)
                                }
                                .help("\(display.metric.title): \(display.text)\n\(display.metric.tooltipDescription)")
                            }
                        }
                    }
                    .frame(height: 20)
                }
                
                Spacer()
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var presetsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preset hiển thị")
                .font(sectionTitleFont)
                .foregroundColor(.white)
            Text("Nhóm này chỉ quyết định thông tin nào hiện trên thanh menu, không đổi nhịp lấy mẫu.")
                .font(secondaryBodyFont)
                .lineSpacing(1)
                .foregroundColor(.white.opacity(0.55))
            
            LazyVGrid(columns: compactColumns, spacing: 10) {
                presetButton(title: "Mặc định", subtitle: "GPU + CPU + DISK + RAM") {
                    manager.setStatusMetrics([.gpu, .cpu, .storage, .memory])
                    manager.showsStatusIcon = true
                }
                
                presetButton(title: "Làm việc", subtitle: "GPU + CPU + RAM") {
                    manager.setStatusMetrics([.gpu, .cpu, .memory])
                    manager.showsStatusIcon = true
                }
                
                presetButton(title: "Giám sát", subtitle: "Hiện tất cả") {
                    manager.setStatusMetrics(MenuBarStatusMetric.allCases)
                    manager.showsStatusIcon = true
                }
                
                presetButton(title: "Tối giản", subtitle: "Chỉ biểu tượng") {
                    manager.setStatusMetrics([])
                    manager.showsStatusIcon = true
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var samplingProfilesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nhịp lấy mẫu")
                .font(sectionTitleFont)
                .foregroundColor(.white)
            Text("Mỗi profile đổi tốc độ thu thập CPU, RAM, Mạng, Pin, DISK và danh sách tiến trình.")
                .font(secondaryBodyFont)
                .lineSpacing(1)
                .foregroundColor(.white.opacity(0.55))
            
            LazyVGrid(columns: compactColumns, spacing: 10) {
                ForEach([SamplingProfile.economy, .balanced, .live]) { profile in
                    profileButton(profile)
                }
            }
            
            if systemMonitor.samplingProfile == .custom {
                HStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.white.opacity(0.8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bạn đang dùng nhịp lấy mẫu tùy chỉnh")
                            .font(itemTitleFont)
                            .foregroundColor(.white)
                        Text("Các chỉnh sửa phía dưới sẽ được lưu lại cho lần mở sau.")
                            .font(secondaryBodyFont)
                            .lineSpacing(1)
                            .foregroundColor(.white.opacity(0.55))
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var samplingIntervalsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tùy chỉnh theo từng loại")
                .font(sectionTitleFont)
                .foregroundColor(.white)
            Text("Chu kỳ càng ngắn thì số liệu càng mới, nhưng tốn tài nguyên nền hơn.")
                .font(secondaryBodyFont)
                .lineSpacing(1)
                .foregroundColor(.white.opacity(0.55))
            Text("Chỉ những metric đang bật hoặc panel đang mở mới được lấy mẫu.")
                .font(secondaryBodyFont)
                .foregroundColor(.green.opacity(0.85))
            
            VStack(spacing: 10) {
                ForEach(SamplingMetricKind.allCases) { kind in
                    samplingIntervalRow(for: kind)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    private var customSamplingSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trạng thái hiện tại")
                .font(sectionTitleFont)
                .foregroundColor(.white)
            
            HStack(spacing: 10) {
                Image(systemName: systemMonitor.samplingProfile == .custom ? "slider.horizontal.3" : "waveform.path.ecg")
                    .foregroundColor(.white.opacity(0.8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(systemMonitor.samplingProfile.title)
                        .font(itemTitleFont)
                        .foregroundColor(.white)
                    Text(systemMonitor.samplingProfile.subtitle)
                        .font(secondaryBodyFont)
                        .foregroundColor(.white.opacity(0.58))
                }
                Spacer()
            }
            .padding(12)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var selectedMetricsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thứ tự đang hiển thị")
                .font(sectionTitleFont)
                .foregroundColor(.white)
            
            if manager.selectedStatusMetrics.isEmpty {
                Text("Hiện chưa có metric nào được bật. Bạn vẫn có thể giữ lại biểu tượng ứng dụng trên thanh menu.")
                    .font(primaryBodyFont)
                    .lineSpacing(1)
                    .foregroundColor(.white.opacity(0.6))
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(manager.selectedStatusMetrics.enumerated()), id: \.element) { index, metric in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 20, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(metric.title)
                                    .font(itemTitleFont)
                                    .foregroundColor(.white)
                                Text(exampleText(for: metric))
                                    .font(secondaryBodyFont)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            Button(action: { manager.moveStatusMetric(metric, direction: -1) }) {
                                Image(systemName: "arrow.up")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .disabled(index == 0)
                            
                            Button(action: { manager.moveStatusMetric(metric, direction: 1) }) {
                                Image(systemName: "arrow.down")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .disabled(index == manager.selectedStatusMetrics.count - 1)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(12)
                        .help("\(metric.title)\n\(metric.tooltipDescription)")
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var availableMetricsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thông tin có thể hiển thị")
                .font(sectionTitleFont)
                .foregroundColor(.white)
            
            ForEach(MenuBarStatusMetric.allCases) { metric in
                Button(action: { manager.toggleStatusMetric(metric) }) {
                    HStack(spacing: 12) {
                        Image(systemName: manager.isStatusMetricEnabled(metric) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(manager.isStatusMetricEnabled(metric) ? .green : .white.opacity(0.4))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(metric.title)
                                .font(itemTitleFont)
                                .foregroundColor(.white)
                            Text(exampleText(for: metric))
                                .font(secondaryBodyFont)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .help("\(metric.title)\n\(metric.tooltipDescription)")
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tùy chọn khác")
                .font(sectionTitleFont)
                .foregroundColor(.white)
            
            Toggle(isOn: Binding(
                get: { manager.showsStatusIcon },
                set: { _ in manager.toggleStatusIcon() }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hiện biểu tượng ứng dụng")
                        .font(itemTitleFont)
                        .foregroundColor(.white)
                    Text("Giữ lại biểu tượng app ở đầu status item.")
                        .font(secondaryBodyFont)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .toggleStyle(.switch)
            .tint(.purple)
            
            Button(action: {
                manager.resetStatusBarPreferences()
                systemMonitor.applySamplingProfile(.balanced)
            }) {
                Text("Khôi phục cấu hình mặc định")
                    .font(itemTitleFont)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func presetButton(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(itemTitleFont)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(secondaryBodyFont)
                    .lineSpacing(1)
                    .foregroundColor(.white.opacity(0.6))
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private func profileButton(_ profile: SamplingProfile) -> some View {
        let isActive = systemMonitor.samplingProfile == profile
        
        return Button(action: {
            systemMonitor.applySamplingProfile(profile)
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(profile.title)
                        .font(itemTitleFont)
                        .foregroundColor(.white)
                    Spacer()
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                Text(profile.subtitle)
                    .font(secondaryBodyFont)
                    .lineSpacing(1)
                    .foregroundColor(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(isActive ? Color.white.opacity(0.14) : Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.green.opacity(0.8) : Color.clear, lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private func samplingIntervalRow(for kind: SamplingMetricKind) -> some View {
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(kind.title)
                        .font(itemTitleFont)
                        .foregroundColor(.white)
                    Text(kind.subtitle)
                        .font(secondaryBodyFont)
                        .lineSpacing(1)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Text(systemMonitor.formattedSamplingInterval(for: kind))
                    .font(badgeFont)
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(999)
            }
            
            Stepper(
                value: Binding(
                    get: { systemMonitor.menuBarSamplingConfiguration.interval(for: kind) },
                    set: { systemMonitor.updateSamplingInterval(for: kind, to: $0) }
                ),
                in: kind.range,
                step: kind.step
            ) {
                Text("Điều chỉnh nhịp lấy mẫu")
                    .font(secondaryBodyFont)
                    .foregroundColor(.white.opacity(0.55))
            }
            .tint(.green)
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
        .help("\(kind.title)\n\(kind.subtitle)")
    }
    
    private func exampleText(for metric: MenuBarStatusMetric) -> String {
        switch metric {
        case .gpu:
            return "Ví dụ: icon + 53%"
        case .storage:
            return "Ví dụ: icon + F:36.6GB U:357.8GB"
        case .memory:
            return "Ví dụ: icon + 61%"
        case .cpu:
            return "Ví dụ: icon + 64%"
        case .network:
            return "Ví dụ: icon + ↓2.4M ↑350K"
        case .battery:
            return "Ví dụ: icon + 82%"
        }
    }
}

private enum CustomizerSection: String, CaseIterable, Identifiable {
    case display
    case sampling
    case options
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .display: return "Hiển thị"
        case .sampling: return "Lấy mẫu"
        case .options: return "Khác"
        }
    }
}
