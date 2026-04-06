# Nhật ký thay đổi MacOptimizer v4.0.7

Ngày: 2026-04-06

## Tóm tắt

Phiên bản này bổ sung module **quản lý mô hình AI** (Ollama / LM Studio), tách thư viện **AIModelKit**, cải thiện **build** (Swift Package + resource bundle), phản hồi **loading khi chuyển module** trong cửa sổ chính, và kiểm thử parsing qua **XCTest** (khi có Xcode) hoặc **AIModelKitVerify**.

## Thay đổi kỹ thuật

- **AIModelKit** (`Sources/AIModelKit/`): kiểu dữ liệu provider, `parseByteCount` / `parseOllamaList` (hỗ trợ GiB/MiB và regex size cập nhật).
- **App**: `AIModelManager`, `AIModelsView`; `ContentView` dùng một `AIModelManager` shared qua `environmentObject`; entry từ sidebar, Smart Clean, menu bar.
- **ContentView**: overlay loading ngắn khi đổi `selectedModule` (khớp animation chuyển cảnh).
- **build.sh**: `swift build -c release`, copy binary + `MacOptimizer_AppUninstaller.bundle` vào `.app`.
- **Tests**: `Tests/AppUninstallerTests` (XCTest khi `canImport(XCTest)`); `swift run AIModelKitVerify` cho môi trường chỉ Command Line Tools.
- **Tài liệu**: `docs/audit-2026-04-06.md`.

## Build

```bash
./build.sh
# hoặc hai kiến trúc:
./build_dual_dmg.sh
```

Artifact tham chiếu (sau `build_dual_dmg.sh`):

- `build_release/MacOptimizer_v4.0.7_AppleSilicon.dmg`
- `build_release/MacOptimizer_v4.0.7_Intel.dmg`

## Bổ sung (SPM resources)

- Khai báo đầy đủ ảnh trong `Package.swift` (deep clean, welcome, `resource/*`, v.v.) để clone repo và `swift build` gói đủ asset trong bundle; bỏ tham chiếu file không có trong repo (`AppIcon_back.icns`, `malware.jpg`).
- Ba file PNG trùng tên ở root với `resource/` được **exclude** khỏi target để tránh xung đột tên trong bundle — runtime vẫn dùng bản trong thư mục `resource/`.

## Liên kết phiên bản trước

- [CHANGELOG_v4.0.6.md](CHANGELOG_v4.0.6.md)
