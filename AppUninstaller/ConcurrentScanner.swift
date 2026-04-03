import Foundation

// MARK: - Lớp công cụ quét đồng thời


/// Trình thu thập kết quả quét an toàn theo luồng

actor ScanResultCollector<T: Sendable> {
    private var results: [T] = []
    private var totalSize: Int64 = 0
    private var processedCount: Int = 0
    
    func append(_ item: T) {
        results.append(item)
    }
    
    func appendContents(of items: [T]) {
        results.append(contentsOf: items)
    }
    
    func addSize(_ size: Int64) {
        totalSize += size
    }
    
    func incrementCount() {
        processedCount += 1
    }
    
    func incrementCount(by count: Int) {
        processedCount += count
    }
    
    func getResults() -> [T] {
        return results
    }
    
    func getTotalSize() -> Int64 {
        return totalSize
    }
    
    func getProcessedCount() -> Int {
        return processedCount
    }
    
    func clear() {
        results.removeAll()
        totalSize = 0
        processedCount = 0
    }
}

/// Trình theo dõi tiến trình quét đồng thời

actor ScanProgressTracker {
    private var completedTasks: Int = 0
    private var totalTasks: Int = 0
    private var currentPath: String = ""
    
    func setTotalTasks(_ count: Int) {
        totalTasks = count
    }
    
    func completeTask() {
        completedTasks += 1
    }
    
    func setCurrentPath(_ path: String) {
        currentPath = path
    }
    
    func getProgress() -> Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    func getCurrentPath() -> String {
        return currentPath
    }
    
    func reset() {
        completedTasks = 0
        totalTasks = 0
        currentPath = ""
    }
}

// MARK: - Tính toán kích thước tập tin đồng thời


/// Đồng thời tính toán kích thước thư mục (phiên bản tối ưu)

func calculateSizeAsync(at url: URL, fileManager: FileManager = .default) async -> Int64 {
    var totalSize: Int64 = 0
    
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return 0 }
    
    if isDirectory.boolValue {
        // Đối với các thư mục, sử dụng phép liệt kê đồng thời

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        
        // Thu thập URL tệp theo lô để giảm xung đột khóa

        var fileURLs: [URL] = []
        while let fileURL = enumerator.nextObject() as? URL {
            fileURLs.append(fileURL)
        }
        
        // Kích thước tính toán đồng thời

        let chunkSize = max(100, fileURLs.count / 8) // Chia thành tối đa 8 nhiệm vụ
        let chunks = stride(from: 0, to: fileURLs.count, by: chunkSize).map {
            Array(fileURLs[$0..<min($0 + chunkSize, fileURLs.count)])
        }
        
        await withTaskGroup(of: Int64.self) { group in
            for chunk in chunks {
                group.addTask {
                    var chunkSize: Int64 = 0
                    for fileURL in chunk {
                        if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                            chunkSize += Int64(size)
                        }
                    }
                    return chunkSize
                }
            }
            
            for await size in group {
                totalSize += size
            }
        }
    } else {
        // Nhận kích thước của một tập tin trực tiếp

        if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
           let size = attributes[.size] as? UInt64 {
            totalSize = Int64(size)
        }
    }
    
    return totalSize
}

/// Ước tính nhanh kích thước thư mục (phương pháp lấy mẫu, nhanh hơn nhưng kém chính xác)

func estimateDirectorySize(at url: URL, sampleRate: Double = 0.1, fileManager: FileManager = .default) async -> Int64 {
    guard let enumerator = fileManager.enumerator(
        at: url,
        includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
        options: [.skipsHiddenFiles]
    ) else { return 0 }
    
    var sampledSize: Int64 = 0
    var sampledCount = 0
    var totalCount = 0
    
    while let fileURL = enumerator.nextObject() as? URL {
        totalCount += 1
        
        // Lấy mẫu theo tỷ lệ mẫu

        if Double.random(in: 0...1) < sampleRate {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = resourceValues.fileSize {
                sampledSize += Int64(size)
                sampledCount += 1
            }
        }
    }
    
    // Ước tính tổng kích thước dựa trên kết quả lấy mẫu

    guard sampledCount > 0 else { return 0 }
    let averageSize = Double(sampledSize) / Double(sampledCount)
    return Int64(averageSize * Double(totalCount))
}

// MARK: - Quét thư mục đồng thời


///cấu hình quét

struct ScanConfiguration {
    ///Số lượng nhiệm vụ đồng thời tối đa

    var maxConcurrency: Int = 8
    /// Khoảng thời gian cập nhật UI (cập nhật một lần sau khi xử lý bao nhiêu file)

    var uiUpdateInterval: Int = 100
    ///Ngưỡng kích thước tệp tối thiểu (byte)

    var minFileSize: Int64 = 0
    /// Có bỏ qua file ẩn hay không

    var skipHiddenFiles: Bool = true
    /// Đường dẫn thư mục cần loại trừ

    var excludedPaths: Set<String> = []
    
    static let `default` = ScanConfiguration()
    
    static let junkScan = ScanConfiguration(
        maxConcurrency: 8,
        uiUpdateInterval: 50,
        minFileSize: 0,
        skipHiddenFiles: false,
        excludedPaths: []
    )
    
    static let largeFileScan = ScanConfiguration(
        maxConcurrency: 8,
        uiUpdateInterval: 100,
        minFileSize: 50 * 1024 * 1024, // 50MB
        skipHiddenFiles: true,
        excludedPaths: ["Library", "Applications", "Public", ".Trash"]
    )
}

/// Đồng thời quét thư mục và trả về các file đáp ứng điều kiện

func scanDirectoryConcurrently<T: Sendable>(
    directories: [URL],
    configuration: ScanConfiguration = .default,
    transform: @escaping @Sendable (URL, URLResourceValues) async -> T?
) async -> [T] {
    let collector = ScanResultCollector<T>()
    let fileManager = FileManager.default
    
    await withTaskGroup(of: [T].self) { group in
        for directory in directories {
            group.addTask {
                var items: [T] = []
                
                guard fileManager.fileExists(atPath: directory.path) else { return items }
                
                let options: FileManager.DirectoryEnumerationOptions = configuration.skipHiddenFiles 
                    ? [.skipsHiddenFiles] 
                    : []
                
                guard let enumerator = fileManager.enumerator(
                    at: directory,
                    includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey],
                    options: options
                ) else { return items }
                
                while let fileURL = enumerator.nextObject() as? URL {
                    // Kiểm tra xem nó có nằm trong danh sách loại trừ không

                    let relativePath = fileURL.path.replacingOccurrences(of: directory.path, with: "")
                    let shouldExclude = configuration.excludedPaths.contains { 
                        relativePath.hasPrefix("/\($0)") || relativePath.hasPrefix($0)
                    }
                    
                    if shouldExclude {
                        enumerator.skipDescendants()
                        continue
                    }
                    
                    guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey]) else {
                        continue
                    }
                    
                    // bỏ qua thư mục

                    if values.isDirectory == true { continue }
                    
                    // bộ lọc kích thước

                    let size = Int64(values.fileSize ?? 0)
                    if size < configuration.minFileSize { continue }
                    
                    // Chuyển thành

                    if let item = await transform(fileURL, values) {
                        items.append(item)
                    }
                }
                
                return items
            }
        }
        
        for await items in group {
            await collector.appendContents(of: items)
        }
    }
    
    return await collector.getResults()
}

// MARK: - Trình quản lý cập nhật giao diện người dùng hàng loạt


/// Bộ quản lý cập nhật UI theo lô để giảm tần suất gọi MainActor.

actor BatchUIUpdater {
    private var pendingUpdates: [() -> Void] = []
    private var lastUpdateTime: Date = Date()
    private let minUpdateInterval: TimeInterval
    
    init(minUpdateInterval: TimeInterval = 0.1) {
        self.minUpdateInterval = minUpdateInterval
    }
    
    func scheduleUpdate(_ update: @escaping () -> Void) async {
        pendingUpdates.append(update)
        
        let now = Date()
        if now.timeIntervalSince(lastUpdateTime) >= minUpdateInterval {
            await flush()
        }
    }
    
    func flush() async {
        guard !pendingUpdates.isEmpty else { return }
        
        let updates = pendingUpdates
        pendingUpdates.removeAll()
        lastUpdateTime = Date()
        
        await MainActor.run {
            for update in updates {
                update()
            }
        }
    }
}

// MARK: - Tính toán đồng thời các giá trị băm của tệp


import CryptoKit

/// Tính toán đồng thời giá trị băm MD5 cho nhiều tệp.

func computeHashesConcurrently(for urls: [URL], maxConcurrency: Int = 8) async -> [URL: String] {
    var results: [URL: String] = [:]
    
    await withTaskGroup(of: (URL, String?).self) { group in
        // Sử dụng ngữ nghĩa để kiểm soát đồng thời

        var pendingCount = 0
        var urlIndex = 0
        
        while urlIndex < urls.count || pendingCount > 0 {
            // Thêm nhiệm vụ mới cho đến khi đạt được sự đồng thời tối đa

            while pendingCount < maxConcurrency && urlIndex < urls.count {
                let url = urls[urlIndex]
                urlIndex += 1
                pendingCount += 1
                
                group.addTask {
                    guard let data = try? Data(contentsOf: url) else { return (url, nil) }
                    let digest = Insecure.MD5.hash(data: data)
                    let hash = digest.map { String(format: "%02x", $0) }.joined()
                    return (url, hash)
                }
            }
            
            // Chờ một tác vụ hoàn thành

            if let (url, hash) = await group.next() {
                pendingCount -= 1
                if let hash = hash {
                    results[url] = hash
                }
            }
        }
    }
    
    return results
}
