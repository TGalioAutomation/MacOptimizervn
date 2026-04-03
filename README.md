<p align="center">
  <img src="generated_icon.png" width="128" height="128" alt="MacOptimizer Logo">
</p>

<h1 align="center">MacOptimizer</h1>

<p align="center">
  <strong>🚀 A Powerful macOS System Optimization and App Management Tool</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013.0+-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-4.0-purple.svg" alt="SwiftUI">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/version-2.2.0-brightgreen.svg" alt="Version">
  <img src="https://img.shields.io/badge/i18n-EN%20%7C%20VI-cyan.svg" alt="i18n">
</p>

---

## ✨ Features

MacOptimizer is a system optimization tool designed specifically for macOS, featuring a modern SwiftUI interface with eight core functional modules:

### 🌐 Multi-Language Support (New!)
- **Vietnamese & English** - Switch between languages with one click
- **Persistent Settings** - Language preference is saved automatically
- **Full Coverage** - All UI elements support localization

### 🖥️ Console (System Monitor)
- **CPU Usage** - Real-time CPU usage monitoring
- **Memory Status** - Display used/available memory
- **Disk Space** - Visual disk usage percentage
- **Process Management** - View and manage running apps and background processes
- **One-Click Stop** - Quickly terminate unwanted processes

### 📦 App Uninstaller
- **Smart Scanning** - Automatically detect installed applications
- **Residual File Detection** - Find all associated residual files:
  - Preferences
  - Application Support
  - Caches
  - Logs
  - Saved State
  - Containers
  - Launch Agents
  - Crash Reports
- **Complete Uninstall** - Remove app and all related files with one click
- **Selective Deletion** - Choose to delete only residuals or include the app
- **Move to Trash** - Safe deletion with recovery option

### 🧹 Junk Cleaner
- **System Cache** - Clean macOS system cache
- **App Cache** - Clean cache files from various applications
- **Browser Cache** - Support Safari, Chrome, Firefox, and more
- **Log Files** - Clean system and app logs
- **Categorized Display** - Group by type, support selective cleaning

### ⚡ System Optimizer
- **Startup Items** - View and disable startup items
- **Memory Release** - One-click system memory cleanup
- **System Acceleration** - Optimize system performance

### 🔍 Large File Finder
- **Smart Scanning** - Quickly locate space-consuming files
- **Multi-Directory Scan** - Scan all files in home directory
- **Visual Display** - Clear file size and location display
- **Quick Cleanup** - Direct delete or move to trash

### 🗑️ Trash Manager
- **View Contents** - Browse all files in trash
- **Space Statistics** - Show trash space usage
- **One-Click Empty** - Quickly empty trash to free space

### ✨ Deep Clean
- **Orphaned File Scan** - Scan residual files from uninstalled apps
- **Smart Recognition** - Auto-identify files not belonging to installed apps
- **System Protection** - Auto-exclude Apple system files to prevent accidental deletion
- **Categorized Display** - Group by type: App Support, Cache, Preferences, Containers, Logs
- **Selective Cleanup** - Support select all/none, freely choose items to clean
- **Safe Deletion** - Files move to trash for recovery

### 📁 File Explorer
- **Disk Browsing** - Browse entire Mac disk directory structure
- **Quick Access** - Home, Desktop, Documents, Downloads, Applications, Disk Root
- **Navigation** - Forward/Back/Parent + Breadcrumb path bar
- **Path Input** - Manual path input for quick navigation (supports `~`)
- **File Operations** - New folder, new file, rename, delete
- **Hidden Files** - Toggle show/hide system hidden files
- **Terminal Integration** - One-click open current directory in Terminal
- **Context Menu** - Open, Show in Finder, Rename, Delete

---

## 📸 Screenshots

![alt text](image.png)
![alt text](image-15.png)
![alt text](image-16.png)
![alt text](image-1.png)

![alt text](image-2.png)

![alt text](image-3.png)
![alt text](image-4.png)
![alt text](image-5.png)
![alt text](image-6.png)
![alt text](image-7.png)
![alt text](image-8.png)
![alt text](image-9.png)
![alt text](image-10.png)
![alt text](image-11.png)
![alt text](image-12.png)
![alt text](image-13.png)
![alt text](image-14.png)

---

## 🛠️ Installation & Build

### System Requirements
- **macOS 13.0 (Ventura)** or later
- **Apple Silicon (M1/M2/M3/M4)** or Intel (modify build parameters)
- **Command Line Tools** (Full Xcode not required)

### Download DMG

Download the latest release from [GitHub Releases](https://github.com/apexdev/MacOptimizer/releases):
- **Apple Silicon (M1/M2/M3/M4)**: `MacOptimizer_vX.X.X_AppleSilicon.dmg`
- **Intel**: `MacOptimizer_vX.X.X_Intel.dmg`

### Build from Source
```bash
# 1. Clone repository
git clone https://github.com/apexdev/MacOptimizer.git
cd MacOptimizer

# 2. Run build script
chmod +x build.sh
./build.sh

# 3. Launch app
open build/MacOptimizer.app
```

### Intel Support

For Intel Mac, modify `build.sh`:

```bash
# Change
-target arm64-apple-macos13.0
# To
-target x86_64-apple-macos13.0
```

---

## 📁 Project Structure

```
MacOptimizer/
├── AppUninstaller/              # Source code
│   ├── AppUninstallerApp.swift  # App entry
│   ├── ContentView.swift        # Main view
│   ├── NavigationSidebar.swift  # Sidebar navigation
│   ├── LocalizationManager.swift # i18n manager (New!)
│   ├── Models.swift             # Data models
│   ├── Styles.swift             # Global styles
│   │
│   ├── MonitorView.swift        # Console view
│   ├── SystemMonitorService.swift
│   ├── ProcessService.swift
│   │
│   ├── AppScanner.swift         # App scanner
│   ├── AppDetailView.swift      # App detail view
│   ├── ResidualFileScanner.swift
│   ├── FileRemover.swift
│   │
│   ├── JunkCleaner.swift        # Junk cleaner
│   ├── JunkCleanerView.swift
│   │
│   ├── SystemOptimizer.swift    # System optimizer
│   ├── OptimizerView.swift
│   │
│   ├── LargeFileScanner.swift   # Large file scanner
│   ├── LargeFileView.swift
│   │
│   ├── TrashView.swift          # Trash view
│   ├── DiskSpaceManager.swift
│   ├── DiskUsageView.swift
│   │
│   ├── DeepCleanScanner.swift   # Deep clean
│   ├── DeepCleanView.swift
│   │
│   ├── FileExplorerService.swift # File explorer
│   ├── FileExplorerView.swift
│   │
│   ├── Info.plist
│   └── AppIcon.icns
│
├── build.sh                     # Build script
├── release_package.sh           # Release packaging
└── README.md
```

---

## 🔧 Tech Stack

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI 4.0
- **Minimum Support**: macOS 13.0 (Ventura)
- **Architecture**: MVVM
- **Build Tool**: Swift Compiler (swiftc)

---

## 🚀 Roadmap

- [x] Multi-language support (English/Vietnamese)
- [ ] Scheduled cleanup tasks
- [ ] Menu bar widget
- [ ] App update detection
- [ ] Duplicate file finder
- [ ] Privacy protection (browsing history cleanup)

---

## 🤝 Contributing

Contributions are welcome! Submit a Pull Request or create an Issue.

1. Fork this repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Create Pull Request

---

## 📄 License

This project is open source under the [MIT License](LICENSE).

---

## ⚠️ Disclaimer

- Back up important data before use
- Deleting system files may cause apps to malfunction
- Recommend using "Move to Trash" first, then empty after confirming
- This tool is for learning and personal use only

---

<p align="center">
  Visit website: <a href="https://apexdev.website">https://apexdev.website</a>
</p>

---

# Hướng dẫn Tiếng Việt

## ✨ Tính năng

MacOptimizer là một công cụ tối ưu hóa hệ thống được thiết kế dành riêng cho macOS, với giao diện SwiftUI hiện đại, cung cấp 8 tính năng cốt lõi:

### 🌐 Hỗ trợ đa ngôn ngữ (Tính năng mới!)
- **Song ngữ Việt - Anh** - Chuyển đổi ngôn ngữ giao diện dễ dàng
- **Lưu cài đặt** - Tự động lưu lựa chọn ngôn ngữ
- **Hỗ trợ toàn diện** - Mọi thành phần giao diện đều được bản địa hóa

### 🖥️ Điều khiển (Giám sát hệ thống)
- **Mức sử dụng CPU** - Giám sát CPU theo thời gian thực
- **Trạng thái bộ nhớ** - Hiển thị dung lượng đã dùng/khả dụng
- **Dung lượng ổ đĩa** - Hiển thị đồ họa trực quan mức sử dụng ổ đĩa
- **Quản lý tiến trình** - Xem và quản lý các ứng dụng, tiến trình chạy ngầm
- **Dừng tiến trình** - Ghi đè, tắt ứng dụng không mong muốn nhanh chóng

### 📦 Gỡ cài đặt ứng dụng
- **Quét thông minh** - Tự động phát hiện các ứng dụng đã cài đặt
- **Phát hiện tệp tin rác** - Tìm tất cả tệp tin rác liên quan như:
  - Tùy chọn (Preferences)
  - Hỗ trợ ứng dụng (Application Support)
  - Bộ nhớ đệm (Caches)
  - Nhật ký (Logs)
  - Trạng thái đã lưu (Saved State)
  - Vùng chứa (Containers)
  - Quản lý Khởi động (Launch Agents)
  - Báo cáo sự cố (Crash Reports)
- **Gỡ bỏ hoàn toàn** - Xóa ứng dụng và tất cả tệp tin liên quan
- **Xóa có chọn lọc** - Chỉ xóa rác hoặc xóa cả ứng dụng
- **Chuyển vào Thùng rác** - Khôi phục dễ dàng

### 🧹 Dọn dẹp rác
- **Bộ đệm hệ thống** - Dọn sạch cache macOS
- **Bộ đệm ứng dụng** - Dọn sạch cache do ứng dụng sinh ra
- **Bộ đệm trình duyệt** - Hỗ trợ Safari, Chrome, Firefox, v.v.
- **Tệp nhật ký** - Làm sạch nhật ký hệ thống
- **Phân loại hiển thị** - Phân nhóm và xóa chọn lọc

### ⚡ Tối ưu hệ thống
- **Mục khởi động** - Quản lý, tắt ứng dụng khởi động cùng máy
- **Giải phóng bộ nhớ** - Dọn RAM bằng một cú nhấp chuột
- **Tăng tốc hệ thống** - Tối ưu hóa hiệu năng

### 🔍 Tìm tệp lớn
- **Quét thông minh** - Tìm ngay file tốn dung lượng
- **Quét đa thư mục** - Quét tất cả file trong Home
- **Giao diện trực quan** - Xem tên và dung lượng rõ ràng
- **Dọn dẹp nhanh** - Xóa trực tiếp hoặc chuyển vào thùng rác

### 🗑️ Quản lý thùng rác
- **Xem nội dung** - Trực tiếp duyệt các file trong thùng rác
- **Thống kê dung lượng** - Hiển thị tổng dung lượng các file
- **Làm trống** - Giải phóng dung lượng ổ cứng ngay

### ✨ Dọn dẹp sâu
- **Tệp mồ côi** - Quét tệp dư thừa từ app đã bị xóa
- **Cảnh báo thông minh** - Loại trừ tệp hệ thống Apple
- **Xóa có chọn lọc** - Lựa chọn an toàn các rác cần xóa

### 📁 Quản lý tệp
- **Duyệt ổ đĩa** - Truy cập cấu trúc thư mục của Mac
- **Truy cập nhanh** - Điều hướng dễ dàng tới Tải xuống, Desktop, v.v.
- **Tương tác Terminal** - Mở ngay Terminal ở đường dẫn hiện tại
- **Các tác vụ khác** - Mở thẻ Finder, Hiện tệp ẩn, v.v.

---

## 🛠️ Cài đặt & Build

### Yêu cầu hệ thống
- **macOS 13.0 (Ventura)** trở lên
- **Apple Silicon** hoặc Intel

### Cài đặt qua Homebrew

```bash
# Sử dụng Homebrew Cask
brew tap apexdev/macoptimizer
brew install --cask macoptimizer
```

Hoặc cài trực tiếp từ file:
```bash
brew install --cask ./homebrew/macoptimizer.rb
```

### Tải bản DMG
[GitHub Releases](https://github.com/apexdev/MacOptimizer/releases):
- **Apple Silicon (M1/M2/M3/M4)**: `MacOptimizer_vX.X.X_AppleSilicon.dmg`
- **Intel**: `MacOptimizer_vX.X.X_Intel.dmg`

---

Truy cập website của chúng tôi tại: https://apexdev.website

<p align="center">
  Made with ❤️ for macOS
</p>
