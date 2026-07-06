import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bảng màu dùng chung cho khối giao diện admin kiểu tối (dashboard,
/// quản lý phòng, đặt phòng...). Tách riêng ra đây để mọi màn hình admin
/// dùng chung 1 nguồn, tránh copy lại nhiều nơi.
class AdminColors {
  static const bg = Color(0xFF0B1220);
  static const card = Color(0xFF141B2E);
  static const cardAlt = Color(0xFF10182A);
  static const border = Color(0xFF1F2A40);
  static const gold = Color(0xFFE3B23C);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF8B94A7);
  static const green = Color(0xFF2ECC71);
  static const red = Color(0xFFE74C3C);
  static const orange = Color(0xFFF39C12);
  static const grey = Color(0xFF95A5A6);
  static const blue = Color(0xFF3498DB);
}

/// Theme tối dùng cho các trang admin, đồng bộ font Poppins với
/// `AppTheme.lightTheme` hiện có của app.
final ThemeData adminDarkTheme = ThemeData.dark(useMaterial3: true).copyWith(
  scaffoldBackgroundColor: AdminColors.bg,
  colorScheme: const ColorScheme.dark(
    primary: AdminColors.gold,
    surface: AdminColors.card,
  ),
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
  cardTheme: CardThemeData(
    color: AdminColors.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AdminColors.border),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AdminColors.cardAlt,
    selectedColor: AdminColors.gold,
    labelStyle: GoogleFonts.poppins(color: AdminColors.textPrimary),
    secondaryLabelStyle: GoogleFonts.poppins(color: Colors.black),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    side: const BorderSide(color: AdminColors.border),
  ),
);