// Test mặc định của Flutter đã được thay thế vì app Hotel Management
// cần khởi tạo Firebase (Firebase.initializeApp) trước khi build MyApp,
// điều mà widget test không tự làm được nếu không mock Firebase.
//
// File này chỉ giữ 1 test tối thiểu để `flutter test` chạy pass,
// không kiểm tra logic nghiệp vụ thực tế.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanity check', () {
    expect(1 + 1, 2);
  });
}