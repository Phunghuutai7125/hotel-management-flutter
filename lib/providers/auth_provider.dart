import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService =
      AuthService();

  bool isLoading = false;

  Future<String?> login(
    String email,
    String password,
  ) async {
    isLoading = true;
    notifyListeners();

    final result =
        await _authService.login(
      email: email,
      password: password,
    );

    isLoading = false;
    notifyListeners();

    return result;
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    notifyListeners();

    final result =
        await _authService.register(
      name: name,
      email: email,
      password: password,
    );

    isLoading = false;
    notifyListeners();

    return result;
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<String> getRole() async {
    return await _authService.getRole();
  }
}