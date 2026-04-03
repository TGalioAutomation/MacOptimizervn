# Nhật ký thay đổi MacOptimizer v4.0.3

**Ngày phát hành**: 12 tháng 1 năm 2026

---

## 🔴 Sửa lỗi bảo mật khẩn cấp

Phiên bản này sửa nhiều lỗ hổng bảo mật nghiêm trọng. Tất cả người dùng được khuyến nghị cập nhật ngay lập tức.

---

## ⚠️ Mô tả vấn đề

v4.0.2 và các phiên bản cũ hơn có các vấn đề nghiêm trọng sau:
- Dọn dẹp quét thông minh có thể xóa các file video của người dùng
- Sau khi dọn dẹp, 90% ứng dụng không thể khởi động (bao gồm Edge, Chrome, v.v.)
- Xóa file ngôn ngữ ứng dụng dẫn đến chữ ký mã bị hỏng

---

## ✅ Nội dung sửa lỗi

### 1. Mô-đun quét thông minh (SmartCleanerService)

| Vấn đề | Sửa chữa |
|--------|----------|
| Không kiểm tra `isSelected` khi xóa 6 mảng file | Thêm kiểm tra `isSelected` |
| File trùng lặp/ảnh tương tự không kiểm tra trạng thái chọn | Thêm kiểm tra `isSelected` |
| Xóa file .lproj phá vỡ chữ ký mã | **Tắt** dọn dẹp file bản địa hóa |
| Xóa bộ nhớ đệm ứng dụng đã cài đặt | Bỏ qua bộ nhớ đệm của ứng dụng đã cài đặt |
| Quét phần còn lại của ứng dụng đã gỡ có thể xóa nhầm | **Tắt** quét phần dư |
| Các file lớn được chọn theo mặc định dẫn đến xóa nhầm | File lớn **không được chọn theo mặc định** |
| Tối ưu hóa ứng dụng nền gây lỗi | **Tắt** chức năng tối ưu hóa hiệu suất |

### 2. Bảo vệ an toàn

Thêm các thư mục được bảo vệ mới:
- `~/Movies` - Video người dùng
- `~/Music` - Nhạc người dùng
- `~/Pictures` - Ảnh người dùng
- `~/Documents` - Tài liệu người dùng
- `~/Desktop` - Màn hình desktop
- `~/Downloads` - Thư mục tải về
- `/Applications` - Ứng dụng

### 3. Mô-đun quét sâu (DeepCleanScanner)

| Vấn đề | Sửa chữa |
|--------|----------|
| Kiểm tra bảo mật bỏ qua `SafetyGuard` | Thêm kiểm tra `SafetyGuard` |
| File bị xóa trực tiếp không thể phục hồi | Sử dụng `.trash()` để chuyển vào Thùng rác |

### 4. Mô-đun rác hệ thống (JunkCleaner)

| Vấn đề | Sửa chữa |
|--------|----------|
| Quét file ngôn ngữ xóa .lproj của ứng dụng | **Tắt hoàn toàn** loại file ngôn ngữ |

---

## ❌ Các tính năng đã tắt

Các chức năng sau đã bị vô hiệu hóa do rủi ro bảo mật và sẽ được khôi phục sau khi xây dựng lại bảo mật trong các phiên bản tiếp theo:

1. **Dọn dẹp file bản địa hóa** - Xóa .lproj làm hỏng chữ ký mã macOS
2. **Làm sạch file ngôn ngữ** - Tương tự như trên
3. **Tối ưu hóa hiệu suất (Đóng ứng dụng nền)** - Có thể gây mất dữ liệu ứng dụng
4. **Quét phần còn lại của ứng dụng đã gỡ cài đặt** - Tỷ lệ dương tính giả quá cao

---

## 📊 Thống kê thay đổi mã

- **SmartCleanerService.swift** - Sửa 8 vòng lặp xóa
- **SafetyGuard.swift** - Thêm 8 đường dẫn bảo vệ mới
- **DeepCleanScanner.swift** - 1 bản sửa lỗi kiểm tra bảo mật
- **JunkCleaner.swift** - Đã tắt 1 tính năng

---

## ⬆️ Nâng cấp đề xuất

⚠️ **RẤT KHUYẾN NGHỊ** - Tất cả người dùng nên nâng cấp lên v4.0.3

Nếu bạn gặp vấn đề ứng dụng không thể khởi động sau khi dùng v4.0.2:
1. Khôi phục ứng dụng từ bản sao lưu
2. Hoặc tải xuống/cài đặt lại các ứng dụng bị ảnh hưởng

---

## 📥 Tải xuống

- Apple Silicon (chip M): [MacOptimizer_v4.0.3_AppleSilicon.dmg](https://github.com/apexdev/MacOptimizer/releases/tag/v4.0.3)
- Intel (x86_64): [MacOptimizer_v4.0.3_Intel.dmg](https://github.com/apexdev/MacOptimizer/releases/tag/v4.0.3)

---

## 📝 Khả năng tương thích

- **Phiên bản macOS**: 13.0+
- **Kiến trúc**: Apple Silicon (chip M) / Intel
