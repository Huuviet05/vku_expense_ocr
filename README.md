# 📱 VKU On-Device OCR Expense Tracker

> **Mini-Project 3 — Mobile Application Development**  
> **Faculty of Computer Science — Vietnam - Korea University of Information and Communication Technology (VKU)**  
> **Instructor:** Dr. Nguyen Thanh Tuan  
> **Technology Stack:** Flutter 3.47+ & Dart 3.13+, Google ML Kit (Text Recognition), Riverpod 2, GoRouter, SQLite (sqflite), CustomPainter, MethodChannel.

---

## 📑 Bảng Mục Lục (Table of Contents)

1. [Tổng Quan Dự Án (Project Overview)](#1-tổng-quan-dự-án)
2. [Bảng Đánh Giá & Đáp Ứng Tiêu Chí (Rubric Checklist)](#2-bảng-đáp-ứng-tiêu-chí-chấm-điểm-10-điểm)
3. [Kiến Trúc Ứng Dụng (Architecture Diagram)](#3-kiến-trúc-ứng-dụng)
4. [Hệ Thống On-Device OCR & Regex Heuristics Engine](#4-hệ-thống-on-device-ocr--regex-heuristics)
5. [Màn Hình Review & Verification](#5-màn-hình-xác-nhận--kiểm-tra-ocr-review--verification)
6. [Quản Lý Trạng Thái Hiện Đại với Riverpod 2](#6-quản-lý-trạng-thái-với-riverpod-2)
7. [Vẽ Biểu Đồ Đồ Họa Tuỳ Biến (CustomPainter 120Hz)](#7-vẽ-biểu-đồ-tuỳ-biến-với-custompainter)
8. [Giao Tiếp Hệ Thống Native (Platform Channel - MethodChannel)](#8-giao-tiếp-native-platform-channel)
9. [Lưu Trữ Dữ Liệu Ngoại Tuyến (SQLite & Ảnh Hóa Đơn)](#9-lưu-trữ-dữ-liệu-ngoại-tuyến-sqlite--ảnh-hóa-đơn)
10. [Hướng Dẫn Cài Đặt & Chạy Ứng Dụng (How to Run)](#10-hướng-dẫn-chạy-ứng-dụng--kiểm-thử)

---

## 1. Tổng Quan Dự Án

Ứng dụng **VKU Expense OCR** giải quyết bài toán quản lý tài chính cá nhân dành cho sinh viên và ban quản lý câu lạc bộ VKU:
- **Tự động hóa hoàn toàn:** Chụp ảnh hóa đơn bán lẻ bằng camera hoặc chọn từ thư viện ảnh.
- **Xử lý On-Device (Ngoại tuyến):** Nhận dạng chữ viết siêu tốc bằng **Google ML Kit Text Recognition** trực tiếp trên thiết bị (không cần gửi ảnh lên server, bảo mật tuyệt đối).
- **Trích xuất thông minh:** Bộ máy **Regex Heuristics Engine** chuyên biệt hóa cho hóa đơn tiếng Việt (Highlands, WinMart, Grab, Canteen, cây xăng...) tự động bóc tách **Tên cửa hàng, Tổng tiền thanh toán (VNĐ), Ngày lập hóa đơn** và gợi ý **Danh mục chi tiêu**.
- **Màn hình Review & Verification:** Cho phép người dùng soi chiếu văn bản OCR thô, chọn các con số gợi ý chỉ với 1 chạm hoặc sửa đổi trước khi lưu vào cơ sở dữ liệu SQLite cục bộ.
- **Trực quan hóa sinh động:** Biểu đồ tròn **Donut Category Chart** và biểu đồ cột **Weekly Bar Chart** tự vẽ hoàn toàn bằng `CustomPainter` với hoạt ảnh 120Hz Impeller mượt mà.
- **Cầu nối Native (Platform Channel):** Giao tiếp hai chiều với hệ điều hành Android (Kotlin) để truy vấn mức pin và phần cứng thiết bị.

---

## 2. Bảng Đáp Ứng Tiêu Chí Chấm Điểm (10 Điểm)

| Hạng mục | Yêu cầu Rubric | Triển khai thực tế trong Source Code | Điểm |
|---|---|---|:---:|
| **On-Device OCR & Heuristics** | Chụp ảnh camera / thư viện ảnh, nhận dạng chữ qua ML Kit, Regex trích xuất Tổng tiền (VNĐ/đ/dấu chấm phẩy), Ngày tháng, Tên cửa hàng. Hỗ trợ hóa đơn tiếng Việt đa dạng. | `ReceiptParser` phân tích đa tầng (Multi-pass Regex), bóc tách tiền, ngày `dd/MM/yyyy`, lọc bỏ header hóa đơn, nhận dạng danh mục. Có sẵn **Demo Presets** thử nghiệm nhanh. | **3.5 / 3.5** |
| **Custom Canvas Visualization** | Tự vẽ biểu đồ tròn/donut theo danh mục & biểu đồ cột chi tiêu 7 ngày bằng `CustomPainter`, animation mượt mà. | `DonutChart` & `_DonutPainter` (arcs, startAngle, sweepAngle, chạm vào lát cắt để soi tỷ lệ); `WeeklyBarChart` & `_BarPainter` (gradient rrect, label, tooltip khi bấm vào cột). | **2.5 / 2.5** |
| **State Management & DB** | Kiến trúc Riverpod 2 chuẩn, lưu trữ SQLite `sqflite` CRUD đầy đủ, lưu trữ đường dẫn ảnh hóa đơn chụp thực tế. | `ExpenseNotifier` kế thừa `AsyncNotifier<List<ExpenseModel>>`, các derived providers (`monthlyTotalProvider`, `categoryTotalsProvider`, `weeklyDailyTotalsProvider`). Lưu `photoPath` và xem ảnh phóng to full màn hình. Hỗ trợ hoàn tác (Undo SnackBar). | **2.0 / 2.0** |
| **UI/UX Polish** | Material 3 Theming, Dark Mode, Responsive Layout, Dialog/Sheet xác nhận và chỉnh sửa dữ liệu OCR lỗi, Form Validation. | Seed color VKU Navy Blue `#2C4570`, Google Fonts Outfit, micro-animations `flutter_animate`, `GlobalKey<FormState>`, kiểm tra tính hợp lệ số tiền và tên cửa hàng. | **1.0 / 1.0** |
| **Deliverables & Platform Channel** | Release APK, Platform Channels (`MethodChannel`), Repository cấu trúc sạch sẽ, tài liệu kỹ thuật hoàn chỉnh. | `DevicePlatformService` kết nối `MethodChannel("vn.edu.vku/device_info")` trong `MainActivity.kt` (Android Kotlin). Bộ unit tests 100% passed (`flutter test`). | **1.0 / 1.0** |

---

## 3. Kiến Trúc Ứng Dụng

Ứng dụng tuân theo cấu trúc phân tầng **Clean Feature-First Architecture**:

```
lib/
├── main.dart                                    # Điểm khởi động, ProviderScope, MaterialApp.router
├── core/
│   ├── database/
│   │   └── app_database.dart                    # SQLite singleton, khởi tạo bảng và thực hiện CRUD
│   ├── platform/
│   │   └── device_service.dart                  # Platform Channel MethodChannel('vn.edu.vku/device_info')
│   ├── router/
│   │   └── app_router.dart                      # Khai báo GoRouter, ShellRoute tab navigation, sub-routes
│   └── theme/
│       └── app_theme.dart                       # Hệ thống Material 3, Palette VKU Navy Blue, Typography Outfit
└── features/
    ├── expenses/
    │   ├── data/
    │   │   ├── models/expense_model.dart        # ExpenseModel, ExpenseCategory enum, VND NumberFormat
    │   │   └── repositories/expense_repository.dart # Kho lưu trữ trừu tượng dữ liệu
    │   ├── presentation/
    │   │   ├── screens/
    │   │   │   ├── home_screen.dart             # Danh sách chi tiêu, tìm kiếm, lọc danh mục, tóm tắt tháng
    │   │   │   ├── add_expense_screen.dart      # Thêm thủ công, đính kèm ảnh, Form validation
    │   │   │   └── expense_detail_screen.dart   # Chi tiết khoản chi, xem ảnh hóa đơn zoom, chỉnh sửa, xóa
    │   │   └── widgets/
    │   │       └── expense_summary_card.dart    # ExpenseCard theo chuẩn Lab Tuần 7 (InkWell, animation)
    │   └── providers/
    │       └── expense_provider.dart            # AsyncNotifier Provider & Derived Providers
    ├── ocr/
    │   ├── data/
    │   │   └── receipt_parser.dart              # Bộ xử lý Regex Heuristics trích xuất tổng tiền, ngày, cửa hàng
    │   └── presentation/screens/
    │       ├── ocr_scan_screen.dart             # Màn hình quét Camera/Gallery & Demo Presets
    │       └── review_receipt_screen.dart       # Màn hình Review & Verification kiểm duyệt OCR
    └── stats/
        └── presentation/
            ├── screens/stats_screen.dart        # Màn hình thống kê, thẻ chỉ số, tổng quan
            └── widgets/
                ├── donut_chart.dart             # Animated CustomPainter Donut Chart
                └── weekly_bar_chart.dart        # Animated CustomPainter Weekly Bar Chart
```

---

## 4. Hệ Thống On-Device OCR & Regex Heuristics

### 4.1. Quy trình xử lý (Pipeline)
```
[Camera / Gallery Image] 
        │
        ▼ (InputImage)
[Google ML Kit TextRecognizer]
        │
        ▼ (Raw Noisy Text String)
[ReceiptParser Heuristics Engine]
        ├── Pass 1: Lọc bỏ boilerplate headers ("Hóa đơn bán lẻ", "VAT Invoice"...)
        ├── Pass 2: Trích xuất tên cửa hàng (dòng có ý nghĩa đầu tiên)
        ├── Pass 3: Quét từ khóa Tổng tiền (Tổng cộng, Thành tiền, Thanh toán, Total...)
        ├── Pass 4: Tìm số tiền kế bên hoặc dòng kế cận (Look-ahead)
        ├── Pass 5: Bóc tách ngày lập (dd/MM/yyyy, dd-MM-yyyy, Ngày dd tháng MM...)
        └── Pass 6: Phân loại danh mục (Food, Shopping, Transport, Utilities)
        │
        ▼
[ParsedReceiptResult Object] ──► Chuyển tiếp tới Review & Verification Screen
```

### 4.2. Bảng biểu thức chính quy (Regex Heuristics Table)

| Trường thông tin | Biểu thức Regex mẫu | Mục đích & Xử lý tình huống |
|---|---|---|
| **Từ khóa Tổng tiền** | `r'(?:tổng\s*tiền\|tổng\s*cộng\|thanh\s*toán\|tiền\s*thanh\s*toán\|thành\s*tiền\|total\|grand\s*total\|amount\s*due)'` | Nhận diện dòng chứa thông tin thanh toán cuối cùng của hóa đơn. |
| **Định dạng số VNĐ** | `r'[\d]{1,3}(?:[.,\s]\d{3})*(?:[.,]\d{1,2})?\|\b\d{4,9}\b'` | Nhận dạng số tiền có dấu chấm phân cách ngàn (`150.000`), dấu phẩy (`150,000`), hoặc viết liền (`150000`). |
| **Lọc số tiền phụ** | Look-ahead 1–2 dòng kế tiếp | Nếu từ khóa "TỔNG CỘNG" nằm ở dòng trên và số tiền `89.000` nằm ở dòng dưới, hệ thống vẫn liên kết chính xác. |
| **Ngày lập hóa đơn** | `r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})'` và `r'ngày\s*(\d{1,2})\s*tháng\s*(\d{1,2})\s*năm\s*(\d{2,4})'` | Chuyển đổi định dạng ngày tháng tiếng Việt chuẩn xác sang `DateTime`. |
| **Tên cửa hàng** | Loại trừ: `^(hóa đơn\|phiếu tính tiền\|receipt\|kính chào\|đt:\|mst:)` | Bỏ qua các dòng tiêu đề cố định để lấy chính xác thương hiệu (Highlands Coffee, WinMart, Grab...). |

---

## 5. Màn Hình Xác Nhận & Kiểm Tra OCR (Review & Verification)

Theo yêu cầu trọng tâm của Tuần 8, kết quả OCR thực tế thường có nhiễu (ánh sáng mờ, nếp gấp hóa đơn). Màn hình `ReviewReceiptScreen` đóng vai trò là chốt chặn bảo toàn dữ liệu:
1. **Xem trước ảnh hóa đơn gốc:** Thẻ hình ảnh sắc nét, chạm vào để mở trình xem ảnh tương tác (phóng to/thu nhỏ `InteractiveViewer`).
2. **Form kiểm duyệt có ràng buộc (`GlobalKey<FormState>`):**
   - Tên cửa hàng (bắt buộc, tự động viết hoa chữ cái đầu).
   - Số tiền (làm sạch ký tự thừa, kiểm tra giá trị dương).
   - **Thẻ gợi ý số tiền (Candidate Chips):** Hệ thống liệt kê toàn bộ các con số tìm thấy trên hóa đơn; người dùng có thể chạm 1 chạm để điền ngay lập tức mà không cần gõ bàn phím.
   - Bộ chọn ngày tháng tiện lợi (`showDatePicker`).
   - Danh mục trực quan: Ăn uống, Di chuyển, Mua sắm, Tiện ích (tự động chọn theo từ khóa).
3. **Thanh soi văn bản OCR gốc (Raw OCR Inspector):** Hiển thị toàn bộ các dòng chữ ML Kit đọc được, cho phép sao chép hoặc kiểm tra chéo độ chính xác.

---

## 6. Quản Lý Trạng Thái với Riverpod 2

Ứng dụng ứng dụng triệt để kiến trúc compile-safe của **Flutter Riverpod 2**:
- **Không phụ thuộc BuildContext khi truy xuất State:** Các logic thêm, sửa, xóa có thể gọi trực tiếp từ Controller mà không lo gặp lỗi `ProviderNotFoundException`.
- **`AsyncNotifierProvider`:** Quản lý danh sách chi tiêu trong bộ nhớ đồng thời đồng bộ hóa xuống SQLite.
- **Derived Providers (Tối ưu số lần render):**
  - `monthlyTotalProvider`: Tính tổng chi trong tháng hiện tại.
  - `categoryTotalsProvider`: Nhóm tổng chi theo từng danh mục cho biểu đồ tròn.
  - `weeklyDailyTotalsProvider`: Tính chi tiêu từng ngày trong 7 ngày gần nhất cho biểu đồ cột.
  - `filteredExpensesProvider`: Lọc theo từ khóa tìm kiếm và danh mục được chọn trong thời gian thực.

---

## 7. Vẽ Biểu Đồ Tuỳ Biến với CustomPainter

Thay vì sử dụng các thư viện biểu đồ nặng nề bên thứ ba, toàn bộ biểu đồ được vẽ trực tiếp bằng `CustomPainter` tối ưu cho Impeller Engine:

### 7.1. Animated Donut Chart (`donut_chart.dart`)
- **Tọa độ & Góc xoay:** Tọa độ tâm `Offset(size.width / 2, size.height / 2)`. Bắt đầu từ đỉnh 12 giờ: `startAngle = -π / 2`.
- **Góc quét từng phần (Sweep Angle):** 
  $$\text{sweepAngle} = \left(\frac{\text{amount}}{\text{total}}\right) \times 2\pi \times \text{progress}$$
- **Hiệu ứng tương tác:** Chạm vào lát cắt hoặc chạm vào phần chú giải (Legend) sẽ kích hoạt phóng to độ dày viền nét vẽ (`strokeWidth + 6`) và hiển thị trực tiếp số tiền cùng tỷ lệ phần trăm ngay tâm biểu đồ.

### 7.2. Animated Weekly Bar Chart (`weekly_bar_chart.dart`)
- Tự động chuẩn hóa chiều cao theo cột cao nhất: $\text{ratio} = \frac{\text{dailyTotal}}{\text{maxTotal}} \times \text{progress}$.
- Cột được bo góc trên (`RRect.fromRectAndCorners`), vẽ nền track mờ và phủ dải chuyển màu Gradient hiện đại.
- Cột của ngày hôm nay (`isToday`) được nổi bật bằng màu cam nhấn.
- Hỗ trợ chạm vào từng cột để hiển thị Tooltip ngày và số tiền cụ thể.

---

## 8. Giao Tiếp Native (Platform Channel)

Ứng dụng triển khai kênh giao tiếp **MethodChannel** (`vn.edu.vku/device_info`) như bài giảng Tuần 8 Phần 7:

### Android Side (`MainActivity.kt`):
```kotlin
package com.example.vku_expense_ocr

import android.content.Context
import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "vn.edu.vku/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBatteryLevel" -> {
                        val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                        val level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                        result.success(level)
                    }
                    "getDeviceInfo" -> {
                        result.success("${Build.MANUFACTURER} ${Build.MODEL} (Android ${Build.VERSION.RELEASE})")
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

### Flutter Side (`device_service.dart`):
- Gọi không đồng bộ `platform.invokeMethod('getBatteryLevel')`.
- Hiển thị huy hiệu mức pin trực tiếp trên thanh AppBar trang chủ kèm Modal xem chi tiết trạng thái nền tảng host.

---

## 9. Lưu Trữ Dữ Liệu Ngoại Tuyến (SQLite & Ảnh Hóa Đơn)

- **Cơ sở dữ liệu SQLite (`vku_expense_ocr.db`):** Lưu trữ bền vững thông qua bảng `expenses` gồm các trường `id`, `merchant`, `amount`, `date`, `category`, `photoPath`, `rawOcrText`, `note`.
- **Lưu trữ ảnh chụp:** Ảnh chụp từ Camera hoặc Thư viện được lưu trữ trên bộ nhớ máy và lưu lại đường dẫn `photoPath`.
- **Trải nghiệm hoàn tác (Undo):** Khi vuốt ngang (`Dismissible`) để xóa khoản chi tiêu, SnackBar sẽ xuất hiện cho phép bấm **"Hoàn tác"** để khôi phục tức thì.

---

## 10. Hướng Dẫn Chạy Ứng Dụng & Kiểm Thử

### Yêu cầu môi trường:
- Flutter SDK `>= 3.0.0` (Khuyến nghị `3.47+`)
- Dart SDK `>= 3.0.0`
- Android Studio / VS Code với Flutter & Dart Extension

### Các lệnh thực thi:

```bash
# 1. Di chuyển vào thư mục dự án
cd vku_expense_ocr

# 2. Cài đặt các gói phụ thuộc
flutter pub get

# 3. Chạy toàn bộ Unit Tests kiểm tra Regex Engine (100% Passed)
flutter test

# 4. Kiểm tra chất lượng mã nguồn (0 cảnh báo, 0 lỗi)
flutter analyze

# 5. Chạy ứng dụng trên máy ảo hoặc thiết bị Android thật
flutter run

# 6. Đóng gói bản cài đặt Release APK cho Android
flutter build apk --release
```

File APK xuất xưởng sẽ nằm tại:  
`build/app/outputs/flutter-apk/app-release.apk`

---
*© 2026 VKU Faculty of Computer Science — Mobile Application Development*
