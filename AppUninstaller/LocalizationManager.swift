import SwiftUI

// MARK: - Language Enum
enum AppLanguage: String, CaseIterable {
    case vietnamese = "vi"
    
    var displayName: String {
        "Tiếng Việt"
    }
    
    var flag: String {
        "🇻🇳"
    }
}

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @AppStorage("app_language") private var languageCode: String = "vi"
    
    @Published var currentLanguage: AppLanguage = .vietnamese
    
    init() {
        languageCode = AppLanguage.vietnamese.rawValue
        currentLanguage = .vietnamese
    }
    
    func setLanguage(_ language: AppLanguage) {
        languageCode = AppLanguage.vietnamese.rawValue
        currentLanguage = .vietnamese
        objectWillChange.send()
    }
    
    // MARK: - Translation Function
    func L(_ key: String) -> String {
        return translations[key]?[.vietnamese] ?? key
    }
    
    // MARK: - Translation Dictionary
    private let translations: [String: [AppLanguage: String]] = [
        // Sidebar Menu
        "monitor": [.vietnamese: "Điều khiển"],
        "uninstaller": [.vietnamese: "Gỡ cài đặt"],
        "deepClean": [.vietnamese: "Dọn dẹp sâu"],
        "cleaner": [.vietnamese: "Rác hệ thống"],
        "optimizer": [.vietnamese: "Tối ưu hệ thống"],
        "largeFiles": [.vietnamese: "Tệp lớn"],
        "fileExplorer": [.vietnamese: "Quản lý tệp"],
        "trash": [.vietnamese: "Thùng rác"],
        "shredder": [.vietnamese: "Hủy tệp"],
        "privacy": [.vietnamese: "Bảo vệ riêng tư"],
        "smartClean": [.vietnamese: "Quét thông minh"],
        
        // Module Descriptions
        "monitor_desc": [.vietnamese: "Giám sát CPU, bộ nhớ, mạng theo thời gian thực"],
        "uninstaller_desc": [.vietnamese: "Xóa hoàn toàn ứng dụng và các tệp tin rác"],
        "deepClean_desc": [.vietnamese: "Quét các tệp tin mồ côi từ ứng dụng đã gỡ cài đặt"],
        "cleaner_desc": [.vietnamese: "Dọn dẹp bộ nhớ đệm và rác hệ thống"],
        "optimizer_desc": [.vietnamese: "Quản lý mục khởi động, giải phóng bộ nhớ"],
        "largeFiles_desc": [.vietnamese: "Tìm và dọn tệp tin lớn"],
        "fileExplorer_desc": [.vietnamese: "Duyệt và quản lý tệp trên đĩa"],
        "trash_desc": [.vietnamese: "Xem và làm trống thùng rác"],
        "shredder_desc": [.vietnamese: "Xóa an toàn các tệp nhạy cảm"],
        
        // Common
        "loading": [.vietnamese: "Đang tải..."],
        "scanning": [.vietnamese: "Đang quét..."],
        "scan": [.vietnamese: "Quét"],
        "clean": [.vietnamese: "Dọn dẹp"],
        "delete": [.vietnamese: "Xóa"],
        "cancel": [.vietnamese: "Hủy"],
        "confirm": [.vietnamese: "Xác nhận"],
        "create": [.vietnamese: "Tạo mới"],
        "rename": [.vietnamese: "Đổi tên"],
        "open": [.vietnamese: "Mở"],
        "refresh": [.vietnamese: "Làm mới"],
        "selectAll": [.vietnamese: "Chọn tất cả"],
        "deselectAll": [.vietnamese: "Bỏ chọn tất cả"],
        "selected": [.vietnamese: "Đã chọn"],
        "total": [.vietnamese: "Tổng cộng"],
        "items": [.vietnamese: "mục"],
        "size": [.vietnamese: "Kích thước"],
        "name": [.vietnamese: "Tên"],
        "date": [.vietnamese: "Ngày"],
        "type": [.vietnamese: "Loại"],
        "path": [.vietnamese: "Đường dẫn"],
        
        // Console
        "cpu_usage": [.vietnamese: "Mức sử dụng CPU"],
        "memory_usage": [.vietnamese: "Mức sử dụng Bộ nhớ"],
        "disk_usage": [.vietnamese: "Mức sử dụng Ổ đĩa"],
        "used": [.vietnamese: "Đã dùng"],
        "free": [.vietnamese: "Trống"],
        "processes": [.vietnamese: "Tiến trình"],
        "ports": [.vietnamese: "Cổng"],
        "stop_process": [.vietnamese: "Dừng tiến trình"],
        "release_port": [.vietnamese: "Giải phóng cổng"],
        
        // Uninstaller
        "installed_apps": [.vietnamese: "Ứng dụng đã cài"],
        "search_apps": [.vietnamese: "Tìm kiếm ứng dụng..."],
        "residual_files": [.vietnamese: "Tệp tin rác"],
        "uninstall": [.vietnamese: "Gỡ cài đặt"],
        "move_to_trash": [.vietnamese: "Chuyển vào thùng rác"],
        "permanently_delete": [.vietnamese: "Xóa vĩnh viễn"],
        
        // Deep Clean
        "deep_clean": [.vietnamese: "Dọn dẹp sâu"],
        "orphaned_files": [.vietnamese: "Tệp mồ côi"],
        "system_clean": [.vietnamese: "Hệ thống đã dọn dẹp sạch"],
        "no_orphaned_files": [.vietnamese: "Không phát hiện tệp rác của ứng dụng đã gỡ bỏ"],
        "app_support": [.vietnamese: "Khung ứng dụng"],
        "cache": [.vietnamese: "Bộ nhớ đệm"],
        "preferences": [.vietnamese: "Tùy chọn"],
        "containers": [.vietnamese: "Vùng chứa"],
        "saved_state": [.vietnamese: "Trạng thái đã lưu"],
        "logs": [.vietnamese: "Nhật ký"],
        "group_containers": [.vietnamese: "Vùng chứa nhóm"],
        "cookies": [.vietnamese: "Cookies"],
        "launch_agents": [.vietnamese: "Quản lý Khởi động"],
        "crash_reports": [.vietnamese: "Báo cáo sự cố"],
        
        // Junk Clean
        "junk_files": [.vietnamese: "Tệp tin rác"],
        "system_cache": [.vietnamese: "Bộ nhớ đệm hệ thống"],
        "app_cache": [.vietnamese: "Bộ nhớ đệm ứng dụng"],
        "browser_cache": [.vietnamese: "Bộ đệm trình duyệt"],
        "log_files": [.vietnamese: "Tệp nhật ký"],
        
        // Optimizer
        "startup_items": [.vietnamese: "Mục khởi động"],
        "free_memory": [.vietnamese: "Giải phóng Bộ nhớ"],
        "optimize": [.vietnamese: "Tối ưu hóa"],
        
        // Large Files
        "large_files": [.vietnamese: "Tệp lớn"],
        "min_size": [.vietnamese: "Cỡ tối thiểu"],
        "scan_directory": [.vietnamese: "Thư mục quét"],
        
        // File Explorer
        "quick_access": [.vietnamese: "Truy cập nhanh"],
        "home": [.vietnamese: "Thư mục nhà"],
        "desktop": [.vietnamese: "Màn hình chính"],
        "documents": [.vietnamese: "Tài liệu"],
        "downloads": [.vietnamese: "Tải xuống"],
        "applications": [.vietnamese: "Ứng dụng"],
        "disk_root": [.vietnamese: "Thư mục gốc"],
        "show_hidden": [.vietnamese: "Hiển thị tệp ẩn"],
        "new_folder": [.vietnamese: "Thư mục mới"],
        "new_file": [.vietnamese: "Tệp mới"],
        "open_in_terminal": [.vietnamese: "Mở trong Terminal"],
        "enter_directory": [.vietnamese: "Vào thư mục"],
        "show_in_finder": [.vietnamese: "Mở trong Finder"],
        "input_path": [.vietnamese: "Nhập đường dẫn..."],
        "go": [.vietnamese: "Đi"],
        "go_back": [.vietnamese: "Lùi lại"],
        "path_not_exist": [.vietnamese: "Đường dẫn không tồn tại hoặc không phải là thư mục"],
        "cannot_access": [.vietnamese: "Không thể truy cập thư mục này"],
        "folder_name": [.vietnamese: "Tên thư mục"],
        "file_name": [.vietnamese: "Tên tệp"],
        "new_name": [.vietnamese: "Tên mới"],
        
        // Trash
        "trash_empty": [.vietnamese: "Thùng rác trống"],
        "empty_trash": [.vietnamese: "Đổ rác"],
        "smart_select": [.vietnamese: "Chọn thông minh"],
        "including": [.vietnamese: "Bao gồm"],
        "trash_on_mac": [.vietnamese: "Thùng rác trên Mac"],
        "view_items": [.vietnamese: "Xem các mục"],
        
        // Shredder
        "shredder_title": [.vietnamese: "Hủy tệp"],
        "shredder_subtitle": [.vietnamese: "Nhanh chóng xóa các tệp và thư mục không mong muốn không để lại dấu vết."],
        "secure_erase": [.vietnamese: "Xóa an toàn dữ liệu nhạy cảm"],
        "secure_erase_desc": [.vietnamese: "Đảm bảo tệp bị xóa không thể khôi phục được bằng tính năng xóa an toàn."],
        "resolve_finder_errors": [.vietnamese: "Khắc phục lỗi Finder"],
        "resolve_finder_errors_desc": [.vietnamese: "Dễ dàng xóa các mục bị khóa do tiến trình đang chạy mà không bị lỗi Finder."],
        "select_files": [.vietnamese: "Chọn tệp..."],
        "restart": [.vietnamese: "Khởi động lại"],
        "assistant": [.vietnamese: "Trợ lý"],
        "shred": [.vietnamese: "Nghiền nát"],
        "remove_now": [.vietnamese: "Xóa ngay lập tức"],
        "cleaning_system": [.vietnamese: "Đang dọn dẹp hệ thống..."],
        "stop": [.vietnamese: "Dừng lại"],
        "cleaning_complete": [.vietnamese: "Dọn dẹp hoàn tất"],
        "cleaned": [.vietnamese: "Đã dọn dẹp"],
        "share_results": [.vietnamese: "Chia sẻ kết quả"],
        "view_log": [.vietnamese: "Xem bản ghi"],
        "free_space_available": [.vietnamese: "Bạn có %.2f GB trống trên đĩa khởi động."],
        
        // Confirm Dialogs
        "confirm_delete": [.vietnamese: "Xóa xác nhận"],
        "confirm_delete_msg": [.vietnamese: "Bạn có chắc chắn muốn xóa không?"],
        "confirm_clean": [.vietnamese: "Dọn dẹp xác nhận"],
        "clean_complete": [.vietnamese: "Dọn dẹp hoàn tất"],
        "cleaned_files": [.vietnamese: "Đã dọn dẹp"],
        "freed_space": [.vietnamese: "Không gian giải phóng"],
        
        // Language
        "language": [.vietnamese: "Ngôn ngữ"],
        "switch_language": [.vietnamese: "Đổi ngôn ngữ"],
    ]
}

// MARK: - Global Localization Function
func L(_ key: String) -> String {
    return LocalizationManager.shared.L(key)
}

// MARK: - Environment Keys
struct LocalizationKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localization: LocalizationManager {
        get { self[LocalizationKey.self] }
        set { self[LocalizationKey.self] = newValue }
    }
}
