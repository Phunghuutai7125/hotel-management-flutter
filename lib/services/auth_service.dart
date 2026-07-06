import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');

  User? get currentUser => _auth.currentUser;

  /// Đăng nhập bằng email/password.
  /// Trả về null nếu thành công, hoặc chuỗi lỗi nếu thất bại.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(const Duration(seconds: 15));
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      // ignore: avoid_print
      print('login() lỗi: $e');
      return 'Đã có lỗi xảy ra, vui lòng thử lại';
    }
  }

  /// Đăng ký tài khoản mới + tạo document trong collection `users`
  /// với role mặc định là "user".
  /// Trả về null nếu thành công, hoặc chuỗi lỗi nếu thất bại.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(const Duration(seconds: 15));

      final uid = credential.user?.uid;
      if (uid == null) {
        return 'Không thể tạo tài khoản, vui lòng thử lại';
      }

      final newUser = AppUser(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        role: 'user',
      );

      try {
        await _usersRef
            .doc(uid)
            .set(newUser.toMap())
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        // ignore: avoid_print
        print('Ghi Firestore users lỗi: $e');
        // Tài khoản Auth đã tạo thành công, chỉ lỗi ở bước lưu role.
        // Không rollback để tránh phức tạp; báo lỗi rõ để người dùng biết.
        return 'Tạo tài khoản thành công nhưng lưu thông tin thất bại. '
            'Vui lòng thử đăng nhập lại.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      // ignore: avoid_print
      print('register() lỗi: $e');
      return 'Đã có lỗi xảy ra, vui lòng thử lại';
    }
  }

  /// Lấy role của user hiện tại ("admin" hoặc "user").
  /// Mặc định trả về "user" nếu không tìm thấy dữ liệu hoặc có lỗi
  /// (không bao giờ throw ra ngoài, tránh app bị treo/crash ngầm).
  Future<String> getRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'user';

    try {
      final doc = await _usersRef
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists) return 'user';

      final data = doc.data() as Map<String, dynamic>?;
      return data?['role']?.toString() ?? 'user';
    } catch (e) {
      // ignore: avoid_print
      print('getRole() lỗi: $e');
      return 'user';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Tài khoản không tồn tại';
      case 'wrong-password':
        return 'Sai mật khẩu';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      default:
        return e.message ?? 'Đã có lỗi xảy ra, vui lòng thử lại';
    }
  }
}