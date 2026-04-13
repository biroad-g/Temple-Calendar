import 'package:flutter/material.dart';

class AppTheme {
  // Navy × Gold カラーパレット
  static const Color navyDark = Color(0xFF0D1B2A);
  static const Color navyMedium = Color(0xFF1B2A3E);
  static const Color navyLight = Color(0xFF243B55);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE8C96A);
  static const Color goldDark = Color(0xFFB8960C);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F0E8);
  static const Color textLight = Color(0xFFCCCCCC);
  static const Color textMuted = Color(0xFF888888);
  static const Color red = Color(0xFFE53935);
  static const Color blue = Color(0xFF1E88E5);
  static const Color success = Color(0xFF43A047);

  // 六曜カラー
  static const Color taian = Color(0xFFD4AF37);      // 大安：金
  static const Color tomobiki = Color(0xFF4CAF50);    // 友引：緑
  static const Color sensho = Color(0xFF2196F3);      // 先勝：青
  static const Color senbu = Color(0xFF9C27B0);       // 先負：紫
  static const Color butsumetsu = Color(0xFFE53935);  // 仏滅：赤
  static const Color shakko = Color(0xFF795548);      // 赤口：茶

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: navyDark,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: goldLight,
        surface: navyMedium,
        onPrimary: navyDark,
        onSecondary: navyDark,
        onSurface: white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navyMedium,
        foregroundColor: gold,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: navyMedium,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: gold, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: navyDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return gold;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return goldDark;
          return navyLight;
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navyMedium,
        selectedItemColor: gold,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: gold, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: white, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: white),
        bodyMedium: TextStyle(color: textLight),
        bodySmall: TextStyle(color: textMuted),
      ),
      dividerColor: navyLight,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: navyLight,
        labelStyle: const TextStyle(color: gold),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: gold),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: navyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
      ),
    );
  }
}
