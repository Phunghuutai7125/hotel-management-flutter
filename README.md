# 🏨 Hotel Management App

Ứng dụng quản lý khách sạn đa nền tảng (Android / iOS / Web) xây dựng bằng **Flutter**, tích hợp **Firebase** làm backend và **Google Gemini API** làm trợ lý AI hỗ trợ khách hàng.

## 📋 Giới thiệu

Ứng dụng phục vụ 2 vai trò:
- **Admin**: quản lý phòng, khách hàng, duyệt/từ chối đặt phòng, nhận/trả phòng, lập hóa đơn, xem báo cáo thống kê.
- **User**: đăng ký/đăng nhập, đặt phòng, thanh toán qua QR, xem lịch sử đặt phòng, xem hóa đơn cá nhân, trò chuyện với trợ lý AI.

## ✨ Tính năng chính

- 🔐 Đăng ký / Đăng nhập, phân quyền Admin - User (Firebase Authentication)
- 🛏️ Quản lý phòng: thêm/sửa/xóa, trạng thái Trống / Đang thuê / Chờ dọn / Bảo trì
- 📅 Đặt phòng với kiểm tra trùng lịch (conflict check) tự động
- ✅ Duyệt / từ chối booking
- 🔑 Nhận phòng / Trả phòng theo đúng vòng đời thực tế (`pending → confirmed → checked_in → checked_out`)
- 🧾 Tự động lập hóa đơn khi trả phòng, lưu trữ độc lập với booking
- 💳 Thanh toán bằng mã QR chuyển khoản + tải ảnh sao kê minh chứng
- 📊 Dashboard thống kê doanh thu, tỉ lệ lấp đầy phòng theo thời gian thực (biểu đồ cột, biểu đồ tròn)
- 🤖 Trợ lý AI hỗ trợ khách hàng (Google Gemini API)

## 🛠️ Công nghệ sử dụng

| Thành phần | Công nghệ |
|---|---|
| Frontend | Flutter (Dart) |
| Quản lý trạng thái | Provider |
| Backend / Database | Firebase Authentication, Cloud Firestore |
| Trợ lý AI | Google Gemini API (`google_generative_ai`) |
| Biểu đồ | fl_chart |
| Mã QR | qr_flutter |
| Chọn ảnh | file_picker |
| Font & UI | google_fonts, Material 3 |

## 📂 Cấu trúc project
<pre>
lib/
├── main.dart
├── firebase_options.dart
├── secrets.dart              (API key, không commit lên Git)
├── models/                   (Room, Booking, Customer, Invoice, AppUser...)
├── services/                 (Giao tiếp trực tiếp với Firestore)
├── providers/                (State management - ChangeNotifier)
├── screens/
│   ├── auth/                 (Đăng nhập, Đăng ký)
│   ├── admin/                (Dashboard, quản lý phòng/khách/booking, nhận-trả phòng, hóa đơn)
│   └── user/                 (Trang chủ user, đặt phòng, thanh toán, lịch sử, hóa đơn, AI chat)
├── widgets/                  (Component dùng chung)
└── theme/                    (Theme, gradient dùng chung)
</pre>
## 🚀 Cài đặt và chạy project

### Yêu cầu
- Flutter SDK ^3.9.0
- Tài khoản Firebase đã tạo project (Authentication + Cloud Firestore)
- API key Google Gemini (miễn phí tại [Google AI Studio](https://aistudio.google.com/apikey))

### Bước 1: Clone project

```bash
git clone https://github.com/Phunghuutai7125/hotel-management-flutter.git
cd hotel-management-flutter
```

### Bước 2: Cài dependencies

```bash
flutter pub get
```

### Bước 3: Cấu hình API key

Tạo file `lib/secrets.dart` (file này không được commit lên Git):

```dart
const String geminiApiKey = 'DÁN_API_KEY_GEMINI_CỦA_BẠN_VÀO_ĐÂY';
```

### Bước 4: Cấu hình Firebase

Chạy `flutterfire configure` để sinh file `firebase_options.dart` tương ứng với project Firebase của bạn (nếu chưa có sẵn), hoặc dùng project Firebase đã cấu hình sẵn của nhóm.

### Bước 5: Chạy ứng dụng

```bash
flutter run
```

## 🔒 Bảo mật

- File `lib/secrets.dart` và mọi file `.env` đã được thêm vào `.gitignore`, **không** xuất hiện trên repository.
- Firestore Security Rules yêu cầu `request.auth != null` cho toàn bộ collection nghiệp vụ.

## 👥 Thành viên nhóm

| STT | Họ và tên | MSSV | Lớp |
|---|---|---|---|
| 1 | Nguyễn Quang Duy | 1771040009 | KHMT 17-01 |
| 2 | Phùng Hữu Tài | ... | KHMT 17-01 |
| 3 | Nguyễn Mạnh Cường | ... | KHMT 17-01 |

## 📄 Giấy phép

Đồ án phục vụ mục đích học tập - Học phần Lập trình Mobile, Trường Đại học Đại Nam.
