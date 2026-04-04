# MacOptimizer Design Guide

Tài liệu này mô tả phong cách thiết kế hiện tại của app, dựa trên implementation thực tế trong codebase. Đây là file tham chiếu khi chỉnh giao diện, thêm màn mới, hoặc redesign từng module mà vẫn giữ đúng visual language của sản phẩm.

## Nguồn tham chiếu chính

- `AppUninstaller/Styles.swift`
- `AppUninstaller/ContentView.swift`
- `AppUninstaller/NavigationSidebar.swift`
- `AppUninstaller/MenuBar/MenuBarManager.swift`
- `AppUninstaller/MenuBar/*`

## Tinh thần giao diện

MacOptimizer theo hướng:

- Utility app cao cấp cho macOS, không phải dashboard doanh nghiệp khô cứng.
- Nền đậm, màu chuyển sắc mạnh, lớp kính mờ và card nổi.
- Mỗi module có một sắc thái riêng nhưng vẫn nằm trong cùng một hệ màu đậm và bóng.
- Thông tin kỹ thuật phải rõ, nhưng không được đánh đổi cảm giác "premium".

App không theo phong cách trắng tối giản kiểu form app truyền thống. Giao diện thiên về:

- Dark gradients
- Glassmorphism nhẹ
- Card bo tròn lớn
- Accent màu theo từng tính năng
- Text trắng hoặc trắng giảm opacity trên nền đậm

## Bố cục tổng thể

Trong `ContentView`, app dùng một shell 2 cột:

- Sidebar trái dạng panel kính mờ, rộng hẹp, ưu tiên điều hướng nhanh.
- Vùng nội dung chính là một thẻ lớn bo tròn, cũng dùng nền vật liệu mờ trên background gradient toàn màn hình.

Quy ước layout:

- Cửa sổ tối thiểu: `1000x700`
- Sidebar nổi bên trái, có khoảng đệm đều quanh mép
- Content card chiếm toàn bộ phần còn lại
- Chuyển màn bằng `opacity + move(edge: .trailing)`

## Màu sắc và gradient

`Styles.swift` là nguồn chuẩn cho màu và gradient.

### Nền chung

- `Color.mainBackground`: nền tối xanh tím
- `Color.sidebarBackground`: nền đen mờ
- `Color.cardBackground`: trắng mờ nhẹ trên nền tối
- `Color.cardHover`: sáng hơn một nấc so với card background

### Màu text

- `Color.primaryText`: trắng gần đầy đủ opacity
- `Color.secondaryText`: trắng mờ vừa
- `Color.tertiaryText`: trắng mờ sâu

### Accent trạng thái

- `danger`: đỏ cảnh báo
- `success`: xanh lá/xanh ngọc
- `warning`: vàng

### Gradient theo module

Mỗi module có một `gradient` và `backgroundGradient` riêng thông qua `AppModule`.

Các nhóm màu chính:

- `monitor`: hồng tím đậm
- `smartClean`: tím-indigo
- `cleaner`: tím sáng sang tím đậm
- `deepClean`: xanh lá đậm
- `optimizer` / `maintenance`: cam năng lượng
- `uninstaller`: xanh công nghệ
- `privacy`: hồng đậm sang tím
- `spaceLens`: teal sang xanh biển sâu
- `updater`: teal sang xanh sáng
- `malware`: đỏ cam cảnh báo

Nguyên tắc dùng màu:

- Gradient module dùng cho icon active, selected state, CTA nổi bật hoặc data hero.
- `backgroundGradient` dùng ở cấp màn hình.
- Không pha thêm palette mới nếu chưa có lý do rõ ràng.
- Khi thêm module mới, phải định nghĩa cả accent gradient lẫn background gradient.

## Sidebar

Sidebar trong `NavigationSidebar.swift` là một trong những bề mặt đặc trưng nhất của app.

### Cấu trúc

- Logo trên cùng với vòng tròn gradient và icon `sparkles`
- Các nhóm tính năng viết hoa nhẹ, opacity thấp
- Các item điều hướng bo tròn vừa, icon trái, label phải
- Footer nhỏ với version và nút settings

### Trạng thái chọn

Item được chọn không chỉ đổi màu icon mà còn có:

- Nền tối hơn
- Lớp highlight trắng mờ
- Cảm giác giống thẻ kính nổi

Điều cần giữ:

- Icon luôn là điểm nhận diện đầu tiên
- Label gọn
- Selected state phải rõ nhưng không chói
- Sidebar luôn thanh mảnh hơn content area

## Typography

App hiện dùng chủ yếu system font của macOS qua SwiftUI `.system(...)`.

Quy ước thực tế trong code:

- Header module: `15-18pt`, `semibold` hoặc `bold`
- Nội dung chính: `12-14pt`
- Caption, metadata, mô tả phụ: `10-12pt`
- Những giá trị kỹ thuật hoặc số liệu có thể dùng monospaced digits

Nguyên tắc typography:

- Trên nền đậm, ưu tiên `white` và `white.opacity(...)`
- Không dùng quá nhiều trọng số chữ trong cùng một block
- Caption nên mờ hơn thay vì nhỏ quá mức
- Với dữ liệu realtime, nên ưu tiên dễ đọc hơn là cầu kỳ

## Hình khối và surface

Hình khối chủ đạo:

- `cornerRadius` từ `10` đến `16`
- Card lớn dùng radius `12-16`
- Pill/capsule dùng radius tối đa theo chiều cao
- Nền sử dụng lớp trắng mờ trên dark gradient

Nguyên tắc surface:

- Surface không phẳng hoàn toàn; cần có layer, chiều sâu, hoặc highlight nhẹ
- Card trên nền dark nên dùng `Color.white.opacity(0.05...0.12)`
- CTA không dùng border thuần; ưu tiên fill gradient hoặc fill màu trạng thái

## Component language

### Card

Card là component lặp lại nhiều nhất trong app.

Quy tắc:

- Padding rộng rãi
- Title rõ
- Subtitle opacity thấp hơn
- Nếu có số liệu, số là điểm nhìn chính
- Card không nên quá nhiều đường kẻ

### Icon

- Chủ yếu dùng SF Symbols
- Khi active, icon có thể dùng gradient module
- Khi inactive, icon chuyển sang trắng mờ

### Button

- Plain button cho icon action nhỏ
- Pill/capsule button cho hành động quan trọng
- Nút destructive dùng đỏ
- Nút confirm hoặc success dùng xanh/teal

### Toggle và control

- Dùng kiểu macOS native nhưng đặt trên nền dark
- Nếu custom, vẫn phải giữ cảm giác nhẹ và rõ ràng

## Menu bar style

Menu bar là một nhánh thiết kế riêng, nhưng vẫn cùng hệ visual.

### Popup menu bar

Các màn menu bar hiện dùng:

- nền `Color(hex: "1C0C24")`
- card mờ sáng trên nền tối
- typography compact hơn main app
- chiều rộng hẹp, thao tác nhanh

### Status item trên thanh menu

`MenuBarManager.makeStatusItemImage(from:)` đang là nguồn thiết kế chính của status item.

Style hiện tại:

- Không dùng text rời truyền thống
- Render thành banner `NSImage` custom
- Mỗi metric là một capsule riêng
- Nền capsule là xanh xám đậm
- Border có màu accent theo metric
- Label màu accent, value màu trắng
- Icon app là capsule riêng ở đầu

Mapping accent hiện tại:

- GPU: hồng
- DISK: xanh dương sáng
- RAM: xanh ngọc
- CPU: vàng cam
- NET: cyan
- PIN: vàng

Nguyên tắc:

- Status item phải đọc được trong vài trăm mili giây
- Dữ liệu phải ngắn
- Segment nên giống thiết bị monitor hơn là label hành chính

## Tính cách theo module

App không chỉ là một theme duy nhất. Nó có "sub-brand" theo từng màn:

- Smart Clean: premium, êm, hơi futuristic
- Monitor: realtime, cảnh báo, năng lượng cao
- Privacy / Malware: nghiêm túc, bảo vệ, cảnh báo
- Optimizer / Maintenance: tăng tốc, kỹ thuật, hành động
- File / Space Lens: phân tích, cấu trúc, trực quan

Khi thiết kế màn mới, nên chọn đúng "tính cách" của module thay vì reuse nguyên xi một card mẫu của màn khác.

## Những thứ nên giữ

- Nền dark gradient ở cấp app hoặc module
- Sidebar kính mờ
- Card nổi với bo góc lớn
- Accent gradient theo module
- Text trắng nhiều cấp opacity
- Menu bar dạng compact, thiên về monitor tool

## Những thứ nên tránh

- Chuyển toàn app sang nền trắng hoặc phẳng hoàn toàn
- Dùng quá nhiều border xám kiểu enterprise dashboard
- Trộn nhiều palette không liên quan với `Styles.swift`
- Dùng quá nhiều font khác nhau
- CTA kiểu mặc định không có hierarchy
- Table hoặc form quá cứng, làm mất cảm giác premium/macOS utility

## Quy tắc khi thêm UI mới

Khi thêm màn hoặc component mới:

1. Xác định module đó thuộc nhóm màu nào.
2. Dùng `AppModule.gradient` và `backgroundGradient` nếu phù hợp.
3. Ưu tiên card bo tròn trên nền dark.
4. Giữ typography system, sạch, rõ.
5. Nếu là số liệu kỹ thuật, ưu tiên khả năng quét nhanh.
6. Nếu là hành động phá hủy, dùng đỏ và cần trạng thái rõ.
7. Nếu là menu bar, ưu tiên compact và thao tác tức thời.

## Kết luận

Phong cách hiện tại của MacOptimizer là:

- macOS utility cao cấp
- dark gradient + glass surfaces
- module-based color identity
- realtime technical UI nhưng vẫn giàu cảm xúc thị giác

Mọi redesign tiếp theo nên xem file này như guideline gốc, và đối chiếu lại với implementation thực tế trong:

- `AppUninstaller/Styles.swift`
- `AppUninstaller/ContentView.swift`
- `AppUninstaller/NavigationSidebar.swift`
- `AppUninstaller/MenuBar/MenuBarManager.swift`
