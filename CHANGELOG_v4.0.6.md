# Nhật ký thay đổi MacOptimizer v4.0.6

**Cập nhật giao diện menu bar, tài liệu và trạng thái repo**: 4 tháng 4 năm 2026

---

## Tổng quan

`v4.0.6` là mốc phản ánh trạng thái hiện tại của repo sau các thay đổi gần đây ở giao diện, menu bar monitoring, popup tiện ích và quy trình build. File này không thay thế các changelog lịch sử `v4.0.0` đến `v4.0.3`, mà bổ sung snapshot mới nhất để README và tài liệu vận hành bám đúng mã nguồn hiện tại.

---

## Điểm thay đổi chính

### 1. Việt hóa diện rộng

- Giao diện chính và nhiều luồng runtime đã được chuyển sang tiếng Việt.
- Menu bar, monitor, popup và nhiều nhãn thao tác đã được làm mượt câu chữ theo ngữ cảnh macOS.
- Repo vẫn giữ checklist sweep cuối ở [contracts/vietnamese-only-sweep-checklist.md](contracts/vietnamese-only-sweep-checklist.md) để dọn nốt text còn sót trong source runtime.

### 2. Menu bar monitoring và popup tiện ích

- App hỗ trợ status item động trên menu bar.
- Metric đang hỗ trợ:
  - `GPU`
  - `CPU`
  - `DISK`
  - `RAM`
  - `Mạng`
  - `Pin`
- Có tooltip cho metric và phần tùy biến status item.
- Có trang tùy biến riêng từ nút gear trong popup menu bar.
- Luồng force-quit nhanh trong detail `CPU` và `RAM` được giữ nguyên.
- Status item trên menu bar được redesign sang kiểu capsule banner với segment rõ hơn cho từng metric.
- Popup overview của menu bar đã được làm lại theo kiểu dashboard kính mờ, compact và dễ thao tác hơn.
- Footer của popup menu bar giờ là nhóm shortcut thực sự:
  - `Trang chủ`
  - `Dọn`
  - `Tăng tốc`
  - `Bảo vệ`
  - `Cài đặt`
- Có màn riêng để buộc thoát ứng dụng đang chạy trực tiếp từ menu bar.
- Đã sửa lỗi realtime cho `Pin`, `Wi‑Fi` và tốc độ mạng trong popup overview.
- Đã sửa lỗi định vị và layout của cửa sổ `Tùy chỉnh thanh menu` để không bị tràn/cắt khỏi màn hình.

### 3. Chạy theo kiểu menu bar utility

- App khởi động ở chế độ accessory utility.
- Cửa sổ chính được ẩn khi mở app và có thể bật lại khi người dùng cần.
- App không còn phụ thuộc vào việc mở sẵn cửa sổ chính để dùng menu bar monitoring.

### 4. Tài liệu design nội bộ

- Bổ sung `DESIGN.md` để mô tả visual language hiện tại của app:
  - dark gradient
  - glassmorphism nhẹ
  - module accent colors
  - quy ước layout sidebar, card, menu bar
- Các thay đổi UI sau này có thể bám file này để tránh lệch phong cách.

### 5. Build artifact hiện tại

- `./build.sh`
  - tạo `build/MacOptimizer.app`
  - tạo `build/MacOptimizer.dmg`
- `./build_dual_dmg.sh`
  - tạo `build_release/MacOptimizer_v4.0.6_AppleSilicon.dmg`
  - tạo `build_release/MacOptimizer_v4.0.6_Intel.dmg`

---

## Ghi chú tài liệu

- `README.md` đã được cập nhật lại để loại bỏ mô tả cũ, sai hoặc không còn khớp với mã nguồn hiện tại.
- Ảnh minh họa trong README hiện dùng file có sẵn trong repo thay vì placeholder hỏng.
- Tài liệu hiện tách rõ:
  - changelog lịch sử,
  - trạng thái repo hiện tại,
  - checklist sweep tiếp theo cho việc chuẩn hóa tiếng Việt.

---

## Tham chiếu nhanh

- [README.md](README.md)
- [CHANGELOG_v4.0.3.md](CHANGELOG_v4.0.3.md)
- [DESIGN.md](DESIGN.md)
- [contracts/vietnamese-only-sweep-checklist.md](contracts/vietnamese-only-sweep-checklist.md)
