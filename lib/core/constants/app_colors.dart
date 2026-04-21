import 'package:flutter/material.dart';

class AppColors {
  // ============ Primary Colors (الهوية) ============
  /// Main Accent - Buttons, Active Icons, Progress Bars
  static const Color primary = Color(0xFF3D5AFF);
  static const Color primaryDark = Color(0xFF2D43CC);

  /// Glow Effect - Highlights, Selected State Glow, Hover
  static const Color accent = Color(0xFF00F2FF);
  static const Color accentMuted = Color(0xFF00C4CC);

  // ============ Dark Backgrounds ============
  /// Main App Background
  static const Color background = Color(0xFF0B0E14);

  /// Surface - Movie Cards, Side Navigation
  static const Color surface = Color(0xFF1A1F26);

  /// Elevated Surface
  static const Color card = Color(0xFF1A1F26);
  static const Color cardLight = Color(0xFF242A33);

  /// Border / Stroke
  static const Color divider = Color(0xFF2D343F);
  static const Color border = Color(0xFF2D343F);

  // ============ Typography ============
  /// High Emphasis
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Medium Emphasis - Metadata
  static const Color textSecondary = Color(0xFF94A3B8);

  /// Disabled / Placeholder
  static const Color textMuted = Color(0xFF475569);

  // ============ Semantic Colors ============
  static const Color success = Color(0xFF00D68F);
  static const Color warning = Color(0xFFFFAA00);
  static const Color error = Color(0xFFFF3D71);
  static const Color live = Color(0xFFFF3D71);

  // ============ Gradients ============
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF5B73FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============ Glows / Shadows ============
  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: primary.withOpacity(0.4),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> accentGlow = [
    BoxShadow(
      color: accent.withOpacity(0.25),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

class AppStrings {
  static const String appName = 'IPTV Player';
  static const String login = 'تسجيل الدخول';
  static const String serverUrl = 'رابط السيرفر';
  static const String username = 'اسم المستخدم';
  static const String password = 'كلمة المرور';
  static const String signIn = 'دخول';
  static const String liveTv = 'القنوات المباشرة';
  static const String movies = 'الأفلام';
  static const String series = 'المسلسلات';
  static const String search = 'بحث';
  static const String favorites = 'المفضلة';
  static const String settings = 'الإعدادات';
  static const String logout = 'تسجيل الخروج';
}
