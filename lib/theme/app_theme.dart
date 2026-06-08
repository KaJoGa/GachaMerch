import 'package:flutter/material.dart';

/// Palet warna tema GachaMerch — vibe e-commerce premium + fantasi (chill).
class AppColors {
  static const Color primary = Color(0xFFC29A5B); // Muted Gold — CTA, harga, ikon penting
  static const Color secondary = Color(0xFF5A716A); // Sage/Jade — kategori, filter, badge
  static const Color background = Color(0xFFFDFBF7); // Warm White/Cream — latar app
  static const Color surface = Color(0xFFFFFFFF); // White — card produk
  static const Color text = Color(0xFF3E342F); // Dark Roast Brown — teks & border
}

/// Tema utama aplikasi. Disetel sekali di main.dart agar AppBar, tombol,
/// background, dan card otomatis memakai palet di atas.
ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.text,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
    ),
  );
}
