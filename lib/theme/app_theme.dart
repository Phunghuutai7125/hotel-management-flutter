import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff2563EB),
      ),

      scaffoldBackgroundColor: const Color(0xffF8FAFC),

      textTheme: GoogleFonts.poppinsTextTheme(),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xff2563EB),
            width: 2,
          ),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,

          minimumSize: const Size(
            double.infinity,
            55,
          ),

          backgroundColor: const Color(0xff2563EB),

          foregroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              15,
            ),
          ),

          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.white,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            18,
          ),
        ),
      ),
    );
  }
}

/// Bộ màu & gradient dùng chung cho phong cách "app du lịch" —
/// tươi sáng, hiện đại. Dùng ở các màn hình auth (login/register)
/// và khu vực user để tạo cảm giác đồng bộ, không phải tô riêng
/// từng màn.
class AppGradients {
  /// Gradient chính: xanh dương -> xanh ngọc (cyan), dùng cho
  /// header, nút chính, banner chào mừng.
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
  );

  /// Gradient nền nhẹ, dùng cho background toàn màn hình auth —
  /// nhạt hơn primary rất nhiều để không chói, chữ đen vẫn đọc rõ.
  static const backgroundSoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFDCEEFF), Color(0xFFF8FAFC)],
  );

  /// Màu nhấn phụ (dùng cho badge, icon phụ, trạng thái tích cực).
  static const accent = Color(0xFF14B8A6);
}

/// Shadow mềm dùng chung cho card nổi trên nền sáng — nhẹ hơn
/// mặc định của Material để trông "thoáng" kiểu app du lịch.
class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF2563EB).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}