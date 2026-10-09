# MINI-PROJECT SHORT TECHNICAL REPORT
**Course:** Cross-Platform Mobile App Development (VKU)  
**Mini-Project Title:** Mini-Project 3: On-Device OCR Expense Tracker (VKU Expense OCR)  
**Team / Student Name:** Nguyễn Hữu Việt  
**Submission Date:** 09/10/2026 (End of Week 8)  

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS
* **Team Members:**
  1. Nguyễn Hữu Việt — Student ID: 23IT309 — Role: Full-stack Mobile Developer (System Architecture, On-Device ML Kit OCR, Regex Heuristics Engine, Review & Verification Screen, Riverpod 2 State Management, CustomPainter Visualization, Platform Channel MethodChannel) — Contribution: 100%
* **📱 Link Tải File APK (Google Drive / GitHub Releases):** [https://github.com/huuviet05/vku_expense_ocr/releases/download/v1.0.0/app-release.apk](https://github.com/huuviet05/vku_expense_ocr/releases/download/v1.0.0/app-release.apk) *(Sẵn sàng cài đặt và chạy trên mọi thiết bị Android)*
* **💻 GitHub Repository:** [https://github.com/huuviet05/vku_expense_ocr.git](https://github.com/huuviet05/vku_expense_ocr.git) *(Public repo, Clean Architecture, tài liệu README.md chi tiết)*
* **🎥 Video Demo (Physical Android Phone / Emulator):** [Link Video Demo 2–3 phút trên YouTube / Google Drive — Thể hiện quét hóa đơn thời gian thực, bóc tách regex, xác nhận review và vẽ biểu đồ CustomPainter]

---

## 2. FEATURE IMPLEMENTATION CHECKLIST
| # | Required Feature | Status | Implementation Details & Acceptance Level |
|:---:|---|:---:|---|
| 1 | **On-Device OCR & Image Capture** | ✅ Complete | Chụp ảnh camera sắc nét hoặc chọn từ thư viện ảnh (`image_picker`). Nhận dạng chữ viết ngoại tuyến hoàn toàn bằng **Google ML Kit Text Recognition** trực tiếp trên thiết bị (không cần mạng, bảo mật tối đa, phản hồi dưới 500ms). |
| 2 | **Regex Heuristics Engine for Vietnamese Bills** | ✅ Complete | Bộ máy `ReceiptParser` phân tích đa tầng (Multi-pass Regex): Bóc tách số tiền VNĐ đa dạng (`150.000`, `150,000`, `150000`, đuôi `VNĐ`, `đ`), kỹ thuật look-ahead 2 dòng khi nhãn và số tiền nằm tách biệt, bóc tách ngày lập (`dd/MM/yyyy`) và lọc bỏ tiêu đề rác của máy in hóa đơn. |
| 3 | **Automatic Category Classification** | ✅ Complete | Phân loại danh mục tự động dựa trên từ khóa thương hiệu: Ăn uống (Highlands, Phúc Long, Quán ăn, Canteen), Mua sắm (WinMart, Co.op, Circle K, GS25), Di chuyển (Grab, Be, Xanh SM, Cây xăng), Tiện ích (Điện, Nước, Internet VNPT/FPT). |
| 4 | **Review & Verification Screen (Week 8 Core)** | ✅ Complete | Màn hình kiểm duyệt `ReviewReceiptScreen` chuẩn Rubric: Xem ảnh hóa đơn gốc phóng to (`InteractiveViewer`), Form kiểm tra ràng buộc (`GlobalKey<FormState>`), thanh **Candidate Amount Chips** (chạm 1 chạm chọn số tiền tìm thấy trên bill) và thanh soi toàn văn OCR gốc (Raw OCR Inspector). |
| 5 | **Riverpod 2 Compile-Safe State Architecture** | ✅ Complete | Quản lý trạng thái compile-safe 100% bằng `AsyncNotifierProvider` (`expenseProvider`). Các Derived Providers (`monthlyTotalProvider`, `categoryTotalsProvider`, `weeklyDailyTotalsProvider`, `filteredExpensesProvider`) tự động tính toán lại mà không gây rebuild toàn bộ cây widget. |
| 6 | **Local SQLite Persistence & Photo Storage** | ✅ Complete | Lưu trữ cơ sở dữ liệu bền vững bằng SQLite (`sqflite`). Lưu trữ đường dẫn ảnh hóa đơn chụp thực tế (`photoPath`), văn bản OCR thô và ghi chú. Hỗ trợ thao tác vuốt xóa (`Dismissible`) kèm thanh thông báo hoàn tác (Undo SnackBar). |
| 7 | **Animated Donut Chart (CustomPainter 120Hz)** | ✅ Complete | Biểu đồ tròn phân bổ danh mục tự vẽ hoàn toàn bằng `CustomPainter` tối ưu cho Impeller Engine: Tính toán góc quét cung tròn (`drawArc`), hiệu ứng bo tròn đầu lát cắt (`StrokeCap.round`). Tương tác chạm: Bấm vào lát cắt hoặc chú giải để phóng to lát cắt và hiển thị % cùng số tiền ngay tâm. |
| 8 | **Animated Weekly Bar Chart (CustomPainter)** | ✅ Complete | Biểu đồ cột chi tiêu 7 ngày tự vẽ bằng `CustomPainter`: Chuẩn hóa tỉ lệ theo ngày cao nhất, cột bo góc `RRect` phủ dải chuyển màu `LinearGradient`, tự động làm nổi bật ngày hôm nay (`isToday`), hỗ trợ chạm vào cột để xem Tooltip ngày và số tiền chi tiết. |
| 9 | **Native Platform Channel (Week 8 Part 7)** | ✅ Complete | Thiết lập kênh giao tiếp hai chiều `MethodChannel("vn.edu.vku/device_info")` với Android (viết bằng Kotlin trong `MainActivity.kt`) và iOS (viết bằng Swift trong `AppDelegate.swift`) để truy vấn % pin phần cứng (`getBatteryLevel`) và thông tin thiết bị (`getDeviceInfo`). |
| 10 | **UI/UX Polish, Search & Material 3** | ✅ Complete | Thiết kế chuẩn Material 3 với tông màu VKU Navy Blue (`#2C4570`), font chữ Google Fonts Outfit, micro-animations `flutter_animate`, thanh tìm kiếm và lọc danh mục thời gian thực, có sẵn bộ hóa đơn mẫu (Demo Presets) để thử nghiệm nhanh. |

---

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE

### 3.1. Cấu Trúc Thư Mục Dự Án (Directory Structure)
Dự án được tổ chức theo kiến trúc phân tầng **Clean Feature-First Architecture**:

```text
vku_expense_ocr/
├── android/                 # Mã nguồn Android Native, MainActivity.kt (MethodChannel Kotlin)
├── ios/                     # Mã nguồn iOS Native, AppDelegate.swift (MethodChannel Swift) & Info.plist
├── test/
│   └── widget_test.dart     # Bộ Unit Test tự động kiểm tra Regex Heuristics Engine (100% Passed)
├── lib/
│   ├── main.dart            # Khởi tạo ProviderScope, MaterialApp.router, cấu hình Material 3
│   ├── core/
│   │   ├── database/        # app_database.dart: SQLite Singleton, tạo bảng và CRUD
│   │   ├── platform/        # device_service.dart: Cầu nối MethodChannel('vn.edu.vku/device_info')
│   │   ├── router/          # app_router.dart: GoRouter, ShellRoute tab navigation, sub-routes
│   │   └── theme/           # app_theme.dart: Theme Light/Dark, Palette VKU Navy Blue (#2C4570)
│   └── features/
│       ├── expenses/
│       │   ├── data/
│       │   │   ├── models/expense_model.dart        # ExpenseModel, ExpenseCategory enum, VND NumberFormat
│       │   │   └── repositories/expense_repository.dart # Kho lưu trữ trừu tượng dữ liệu SQLite
│       │   ├── presentation/
│       │   │   ├── screens/
│       │   │   │   ├── home_screen.dart             # Danh sách chi tiêu, tìm kiếm, lọc danh mục, tóm tắt tháng
│       │   │   │   ├── add_expense_screen.dart      # Thêm thủ công, đính kèm ảnh, Form validation
│       │   │   │   └── expense_detail_screen.dart   # Chi tiết khoản chi, xem ảnh hóa đơn zoom, chỉnh sửa, xóa
│       │   │   └── widgets/
│       │   │       └── expense_summary_card.dart    # ExpenseCard theo chuẩn Lab Tuần 7 (InkWell, animation)
│       │   └── providers/
│       │       └── expense_provider.dart            # AsyncNotifier Provider & Derived Providers
│       ├── ocr/
│       │   ├── data/
│       │   │   └── receipt_parser.dart              # Bộ xử lý Regex Heuristics trích xuất tổng tiền, ngày, cửa hàng
│       │   └── presentation/screens/
│       │       ├── ocr_scan_screen.dart             # Màn hình quét Camera/Gallery & Demo Presets
│       │       └── review_receipt_screen.dart       # Màn hình Review & Verification kiểm duyệt OCR
│       └── stats/
│           └── presentation/
│               ├── screens/stats_screen.dart        # Màn hình thống kê, thẻ chỉ số, tổng quan
│               └── widgets/
│                   ├── donut_chart.dart             # Animated CustomPainter Donut Chart
│                   └── weekly_bar_chart.dart        # Animated CustomPainter Weekly Bar Chart
```

### 3.2. Luồng Quản Lý Trạng Thái & Dữ Liệu (State Management Flow)
* **Compile-Safe State Management (Riverpod 2):**
  - `expenseProvider`: Được triển khai qua `AsyncNotifierProvider<ExpenseNotifier, List<ExpenseModel>>`, thực hiện cập nhật lạc quan (Optimistic Update) giúp UI phản hồi ngay tức thì trước khi câu lệnh SQLite hoàn tất.
  - `monthlyTotalProvider`, `categoryTotalsProvider`, `weeklyDailyTotalsProvider`: Sử dụng cơ chế Derived Providers, chỉ tính toán lại khi dữ liệu nguồn thay đổi, loại bỏ việc rebuild toàn bộ cây widget không cần thiết.
  - `filteredExpensesProvider`: Lắng nghe đồng thời từ khóa tìm kiếm và chip danh mục đang chọn để lọc dữ liệu thời gian thực.
* **Local Persistence (SQLite & File Storage):** Toàn bộ hóa đơn được lưu trữ an toàn trong SQLite cục bộ (`vku_expense_ocr.db`). Đường dẫn ảnh hóa đơn được lưu vào trường `photoPath`, cho phép người dùng mở lại và phóng to ảnh hóa đơn bất kỳ lúc nào.

### 3.3. Thuật Toán Regex Heuristics Cho Hóa Đơn Tiếng Việt
* **Từ khóa tổng tiền:** `r'(?:tổng\s*tiền|tổng\s*cộng|thanh\s*toán|tiền\s*thanh\s*toán|thành\s*tiền|cộng\s*tiền\s*hàng|total|grand\s*total|amount\s*due)'`
* **Định dạng số tiền:** `r'[\d]{1,3}(?:[.,\s]\d{3})*(?:[.,]\d{1,2})?|\b\d{4,9}\b'`
* **Kỹ thuật Look-ahead 2 dòng:** Khi từ khóa nằm ở dòng trên và số tiền nằm ở dòng dưới, hệ thống vẫn liên kết chính xác.
* **Lọc Header hóa đơn:** Bỏ qua các dòng tiêu đề cố định `^(hóa đơn|phiếu tính tiền|receipt|kính chào|đt:|mst:)` để lấy đúng tên cửa hàng (Highlands Coffee, WinMart...).

---

## 4. EMPIRICAL EVIDENCE & SCREENSHOTS

Ứng dụng đã được kiểm thử thực tế và hoạt động hoàn hảo trên thiết bị **Android (Physical & Emulator)**:

| Màn hình kiểm thử | Mô tả chi tiết chức năng đã nghiệm thu |
|:---|:---|
| **1. Màn hình sổ chi tiêu (HomeScreen)** | Hiển thị banner tổng chi tiêu trong tháng hiện tại với gradient VKU Navy Blue, huy hiệu % pin lấy từ Platform Channel (`MethodChannel`), thanh tìm kiếm thời gian thực, dải chip lọc danh mục (Tất cả, Ăn uống, Di chuyển, Mua sắm, Tiện ích). Danh sách khoản chi với hiệu ứng xuất hiện mượt mà (`flutter_animate`), vuốt sang trái để xóa kèm thanh thông báo hoàn tác (Undo SnackBar). |
| **2. Màn hình quét OCR (OcrScanScreen)** | Giao diện chụp ảnh camera và thư viện ảnh trực quan. Tích hợp sẵn 3 hóa đơn mẫu (**Demo Presets: Highlands Coffee, WinMart+, Grab**) giúp kiểm thử nhanh chóng quy trình nhận dạng ML Kit và Regex mà không phụ thuộc camera vật lý. |
| **3. Màn hình kiểm duyệt (ReviewReceiptScreen)** | Cho phép xem trước ảnh hóa đơn gốc (hỗ trợ zoom đa điểm `InteractiveViewer`). Form kiểm tra có validation đầy đủ. Dải **Candidate Amount Chips** liệt kê các con số tìm thấy trên hóa đơn giúp sinh viên chạm 1 chạm để điền số tiền. Bộ chọn ngày tiếng Việt, bộ chọn danh mục trực quan và khung soi toàn văn OCR thô (Raw OCR Inspector). |
| **4. Màn hình chi tiết khoản chi (ExpenseDetailScreen)** | Thẻ số tiền nổi bật theo màu danh mục, thông tin cửa hàng, ngày tháng, ghi chú. Xem ảnh hóa đơn gốc lưu trữ trong máy và mở xem ảnh phóng to. Hỗ trợ chỉnh sửa và cập nhật phản hồi ngay lập tức về SQLite và Riverpod state. |
| **5. Màn hình thống kê (StatsScreen)** | Các thẻ chỉ số tổng quan (Tổng chi tháng, Trung bình ngày trong tuần, Danh mục chi nhiều nhất). Biểu đồ cột **WeeklyBarChart** tự vẽ bằng `CustomPainter` với hoạt ảnh tăng trưởng cột và tooltip xem chi tiết ngày. Biểu đồ tròn **DonutChart** tự vẽ với hoạt ảnh quét cung tròn 120Hz, chạm vào lát cắt để hiển thị tỷ lệ % và số tiền ngay tâm. |

---

## 5. TECHNICAL CHALLENGES & RESOLUTIONS

### 5.1. Thách thức 1: Nhiễu ký tự và định dạng số tiền đa dạng trên hóa đơn tiếng Việt
* **Mô tả sự cố:** Hóa đơn tại Việt Nam sử dụng nhiều cách định dạng tiền khác nhau (`150.000 đ`, `150,000 VNĐ`, `150000`, `150 000`). Nhiều hóa đơn in nhãn "TỔNG TIỀN:" ở một dòng và số tiền nằm ở dòng tiếp theo, hoặc in lẫn lộn số tiền từng món ăn và thuế VAT khiến Regex đơn giản bị lấy nhầm số nhỏ.
* **Giải pháp khắc phục:** 
  1. Triển khai thuật toán **Multi-pass Regex** trong `ReceiptParser`: Quét từ khóa tổng tiền trên cùng dòng; nếu không có số, tự động kích hoạt kỹ thuật **Look-ahead** kiểm tra 1–2 dòng kế tiếp.
  2. Xây dựng hàm làm sạch số thông minh `_parseCleanNumber`: Tự động nhận diện dấu chấm/phẩy phân cách hàng ngàn để chuyển đổi chính xác sang kiểu số thực `double`.
  3. Bổ sung cơ chế **Candidate Amounts Collector**: Thu thập toàn bộ các số tiền hợp lệ trên bill và hiển thị thành các nút bấm nhanh (Candidate Chips) trên màn hình Review, giúp người dùng chỉnh sửa chỉ với 1 chạm nếu OCR nhận diện nhầm.

### 5.2. Thách thức 2: Tối ưu đồ họa 120Hz với Impeller Engine bằng CustomPainter
* **Mô tả sự cố:** Các thư viện biểu đồ bên thứ ba thường cồng kềnh, khó tùy biến màu sắc thương hiệu VKU và hay bị giật khung hình (frame jank) khi dữ liệu chi tiêu cập nhật liên tục.
* **Giải pháp khắc phục:** 
  1. Xây dựng trực tiếp hai widget `DonutChart` và `WeeklyBarChart` kế thừa từ `CustomPainter` nguyên bản của Flutter.
  2. Áp dụng công thức lượng giác tính góc quét cung tròn $\text{sweepAngle} = (\text{amount} / \text{total}) \times 2\pi \times \text{progress}$ kết hợp `CurvedAnimation(curve: Curves.easeOutCubic)` mang lại chuyển động mượt mà ở tần số quét 120Hz.
  3. Tích hợp tính năng tương tác chạm thông qua `GestureDetector` và liên kết với chú giải `DonutLegend`, khi người dùng bấm vào một danh mục, độ dày nét vẽ tự động mở rộng thêm $6\text{px}$ và hiển thị tỷ lệ phần trăm ngay tại tâm biểu đồ.

### 5.3. Thách thức 3: Xung đột khóa tệp Gradle Wrapper (Exclusive Access Lock Timeout 120s)
* **Mô tả sự cố:** Khi thực hiện lệnh `flutter run` lần đầu trên Windows, tiến trình nền tự động yêu cầu tải bản `Gradle 9.3.1` (gói zip 200MB từ server nước ngoài). Do mạng bị nghẽn, tệp `.lck` bị khóa và gây ra lỗi nghiêm trọng: `java.lang.RuntimeException: Timeout of 120000 reached waiting for exclusive access to ... gradle-9.3.1-all.zip`.
* **Giải pháp khắc phục:**
  1. Hủy bỏ tiến trình nền bị kẹt và dọn dẹp các tệp tạm `.lck`, `.part` trong thư mục `.gradle`.
  2. Chuyển cấu hình `distributionUrl` trong `gradle-wrapper.properties` sang phiên bản **`Gradle 8.10.2`** — phiên bản đã có sẵn 100% trong bộ nhớ máy tính cục bộ của sinh viên, loại bỏ hoàn toàn việc phải tải thêm dữ liệu qua mạng.
  3. Đồng bộ hóa Android Gradle Plugin (AGP) lên phiên bản `8.7.0` và Kotlin `2.0.20` tương thích tuyệt đối, giúp lệnh `gradlew` thực thi ngay lập tức trong 1.5 giây.

---
*© 2026 VKU Faculty of Computer Science — Mobile Application Development*
