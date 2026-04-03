import Foundation
import AppKit
import SQLite3

// MARK: - Tiện ích mở rộng phân tích cơ sở dữ liệu trình duyệt


extension PrivacyScannerService {
    
    // MARK: - Phương thức phụ trợ thao tác cơ sở dữ liệu

    
    /// Đếm số hàng trong bảng cơ sở dữ liệu

    func countRows(db: OpaquePointer?, table: String) -> Int {
        let query = "SELECT COUNT(*) FROM \(table)"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            return 0
        }
        
        return Int(sqlite3_column_int(statement, 0))
    }
    
    /// Thực hiện truy vấn và ánh xạ kết quả tới một mảng từ điển (để gỡ lỗi/chi tiết)

    func executeQuery(db: OpaquePointer?, query: String) -> [[String: Any]] {
        var statement: OpaquePointer?
        var results: [[String: Any]] = []
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(statement) }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            let columns = sqlite3_column_count(statement)
            
            for i in 0..<columns {
                let name = String(cString: sqlite3_column_name(statement, i))
                let type = sqlite3_column_type(statement, i)
                
                switch type {
                case SQLITE_INTEGER:
                    row[name] = Int(sqlite3_column_int(statement, i))
                case SQLITE_FLOAT:
                    row[name] = Double(sqlite3_column_double(statement, i))
                case SQLITE_TEXT:
                    if let cString = sqlite3_column_text(statement, i) {
                        row[name] = String(cString: cString)
                    }
                default:
                    break
                }
            }
            results.append(row)
        }
        return results
    }
    
    // MARK: - Thu thập biểu tượng ứng dụng

    
    /// Lấy icon thật của ứng dụng

    func getAppIcon(for browser: BrowserType) -> NSImage? {
        let bundleIds: [BrowserType: String] = [
            .chrome: "com.google.Chrome",
            .safari: "com.apple.Safari",
            .firefox: "org.mozilla.firefox"
        ]
        
        guard let bundleId = bundleIds[browser],
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }
        
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
    
    // MARK: - Phân tích cơ sở dữ liệu Chrome

    
    /// Phân tích cơ sở dữ liệu Lịch sử Chrome (sao chép vào vị trí tạm thời để tránh sự cố khóa)

    func parseChromeHistory(at url: URL) -> (visits: Int, downloads: Int, searches: Int) {
        // Cơ sở dữ liệu sẽ bị khóa khi Chrome đang chạy và cần được sao chép vào một vị trí tạm thời trước khi đọc.

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("chrome_history_\(UUID().uuidString).db")
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        do {
            try FileManager.default.copyItem(at: url, to: tempURL)
        } catch {
            print("❌ Failed to copy Chrome History for reading: \(error.localizedDescription)")
            return (0, 0, 0)
        }
        
        var db: OpaquePointer?
        guard sqlite3_open(tempURL.path, &db) == SQLITE_OK else {
            print("❌ Failed to open Chrome History copy: \(tempURL.path)")
            return (0, 0, 0)
        }
        defer { sqlite3_close(db) }
        
        let visits = countRows(db: db, table: "visits")
        let downloads = countRows(db: db, table: "downloads")
        let searches = countRows(db: db, table: "keyword_search_terms")
        
        return (visits, downloads, searches)
    }
    
    /// Sao chép cơ sở dữ liệu đến một vị trí tạm thời và mở nó (để tránh sự cố khóa khi trình duyệt đang chạy)

    private func openDatabaseCopy(at url: URL) -> (db: OpaquePointer?, tempURL: URL?) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("db_copy_\(UUID().uuidString).db")
        
        do {
            try FileManager.default.copyItem(at: url, to: tempURL)
        } catch {
            return (nil, nil)
        }
        
        var db: OpaquePointer?
        guard sqlite3_open(tempURL.path, &db) == SQLITE_OK else {
            try? FileManager.default.removeItem(at: tempURL)
            return (nil, nil)
        }
        
        return (db, tempURL)
    }
    
    /// Đóng cơ sở dữ liệu và dọn dẹp các tập tin tạm thời

    private func closeDatabaseCopy(db: OpaquePointer?, tempURL: URL?) {
        if let db = db { sqlite3_close(db) }
        if let tempURL = tempURL { try? FileManager.default.removeItem(at: tempURL) }
    }
    
    /// Phân tích cơ sở dữ liệu Chrome Cookies

    func parseChromeCookies(at url: URL) -> Int {
        let (db, tempURL) = openDatabaseCopy(at: url)
        defer { closeDatabaseCopy(db: db, tempURL: tempURL) }
        
        guard let db = db else { return 0 }
        return countRows(db: db, table: "cookies")
    }
    
    /// Phân tích chi tiết Cookie Chrome (được nhóm theo tên miền)

    func parseChromeCookiesDetails(at url: URL) -> [(domain: String, count: Int)] {
        let (db, tempURL) = openDatabaseCopy(at: url)
        defer { closeDatabaseCopy(db: db, tempURL: tempURL) }
        
        guard let db = db else { return [] }
        
        let query = "SELECT host_key, count(*) as count FROM cookies GROUP BY host_key ORDER BY count DESC LIMIT 100"
        let results = executeQuery(db: db, query: query)
        
        return results.compactMap { row in
            guard let domain = row["host_key"] as? String,
                  let count = row["count"] as? Int else { return nil }
            return (domain, count)
        }
    }
    
    /// Phân tích dữ liệu đăng nhập Chrome (mật khẩu)

    func parseChromePasswords(at url: URL) -> Int {
        let (db, tempURL) = openDatabaseCopy(at: url)
        defer { closeDatabaseCopy(db: db, tempURL: tempURL) }
        
        guard let db = db else { return 0 }
        return countRows(db: db, table: "logins")
    }
    
    /// Phân tích dữ liệu web Chrome (tự động hoàn thành)

    func parseChromeAutofill(at url: URL) -> Int {
        let (db, tempURL) = openDatabaseCopy(at: url)
        defer { closeDatabaseCopy(db: db, tempURL: tempURL) }
        
        guard let db = db else { return 0 }
        return countRows(db: db, table: "autofill")
    }
    
    // MARK: - Phân tích cơ sở dữ liệu Safari

    
    /// Phân tích cơ sở dữ liệu Lịch sử Safari

    func parseSafariHistory(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_close(db) }
        
        return countRows(db: db, table: "history_visits")
    }
    
    /// Phân tích danh sách tải xuống Safari (plist)

    func parseSafariDownloads(at url: URL) -> Int {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let downloads = plist["DownloadHistory"] as? [[String: Any]] else {
            return 0
        }
        return downloads.count
    }
    
    // MARK: - Phân tích cơ sở dữ liệu Firefox

    
    /// Phân tích lịch sử Firefox (places.sqlite)

    func parseFirefoxHistory(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_close(db) }
        
        // moz_historyvisits chứa tất cả các bản ghi lượt truy cập

        return countRows(db: db, table: "moz_historyvisits")
    }
    
    /// Phân tích cookie Firefox (cookies.sqlite)

    func parseFirefoxCookies(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_close(db) }
        
        return countRows(db: db, table: "moz_cookies")
    }
    
    /// Phân tích lịch sử biểu mẫu Firefox (formhistory.sqlite)

    func parseFirefoxFormHistory(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_close(db) }
        
        return countRows(db: db, table: "moz_formhistory")
    }
    
    // MARK: - Dọn dẹp dữ liệu trình duyệt thông minh (dùng SQL DELETE thay vì xóa file)

    
    ///Thực thi câu lệnh DELETE SQL

    private func executeDelete(db: OpaquePointer?, sql: String) -> Bool {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        defer { sqlite3_finalize(statement) }
        
        return sqlite3_step(statement) == SQLITE_DONE
    }
    
    /// Xóa lịch sử duyệt Chrome (dùng SQL DELETE, giữ nguyên trạng thái đăng nhập)

    func clearChromeHistory(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            print("❌ [Clean] Failed to open Chrome History for cleaning")
            return 0
        }
        defer { sqlite3_close(db) }
        
        var deleted = 0
        
        // Xóa bảng lượt truy cập (bản ghi lượt truy cập)

        if executeDelete(db: db, sql: "DELETE FROM visits") {
            deleted += 1
            print("✅ [Clean] Cleared Chrome visits")
        }
        
        // Xóa bảng url (bản ghi URL)

        if executeDelete(db: db, sql: "DELETE FROM urls") {
            deleted += 1
            print("✅ [Clean] Cleared Chrome urls")
        }
        
        // Xóa bảng tải xuống (bản ghi tải xuống)

        if executeDelete(db: db, sql: "DELETE FROM downloads") {
            deleted += 1
            print("✅ [Clean] Cleared Chrome downloads")
        }
        
        // Xóa bảng từ khóa_search_terms (lịch sử tìm kiếm)

        if executeDelete(db: db, sql: "DELETE FROM keyword_search_terms") {
            deleted += 1
            print("✅ [Clean] Cleared Chrome search terms")
        }
        
        // VACUUM nén cơ sở dữ liệu

        _ = executeDelete(db: db, sql: "VACUUM")
        
        return deleted
    }
    
    /// Clear Chrome Cookies (sẽ đăng xuất bạn khỏi trang web nhưng vẫn giữ tài khoản Google Sync)

    func clearChromeCookies(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            print("❌ [Clean] Failed to open Chrome Cookies for cleaning")
            return 0
        }
        defer { sqlite3_close(db) }
        
        // Xóa tất cả cookie

        if executeDelete(db: db, sql: "DELETE FROM cookies") {
            print("✅ [Clean] Cleared Chrome cookies")
            _ = executeDelete(db: db, sql: "VACUUM")
            return 1
        }
        return 0
    }
    
    /// Clean Chrome Autofill (giữ mật khẩu đã lưu)

    func clearChromeAutofillData(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            print("❌ [Clean] Failed to open Chrome Web Data for cleaning")
            return 0
        }
        defer { sqlite3_close(db) }
        
        var deleted = 0
        
        // Xóa dữ liệu tự động điền

        if executeDelete(db: db, sql: "DELETE FROM autofill") {
            deleted += 1
            print("✅ [Clean] Cleared Chrome autofill")
        }
        
        // Xóa hồ sơ tự động điền

        if executeDelete(db: db, sql: "DELETE FROM autofill_profiles") {
            deleted += 1
            print("✅ [Clean] Cleared Chrome autofill profiles")
        }
        
        _ = executeDelete(db: db, sql: "VACUUM")
        return deleted
    }
    
    /// Xóa lịch sử duyệt web Safari (dùng SQL DELETE)

    func clearSafariHistory(at url: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            print("❌ [Clean] Failed to open Safari History for cleaning")
            return 0
        }
        defer { sqlite3_close(db) }
        
        var deleted = 0
        
        // Xóa lịch sử truy cập

        if executeDelete(db: db, sql: "DELETE FROM history_visits") {
            deleted += 1
            print("✅ [Clean] Cleared Safari history_visits")
        }
        
        // Xóa bản ghi URL

        if executeDelete(db: db, sql: "DELETE FROM history_items") {
            deleted += 1
            print("✅ [Clean] Cleared Safari history_items")
        }
        
        _ = executeDelete(db: db, sql: "VACUUM")
        return deleted
    }
}
