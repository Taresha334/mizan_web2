// filepath: lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class MizanTheme {
  // Mizan PLC Official Brand Colors
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGold = Color(0xFFC6A664);
  static const Color backgroundGreen = Color(0xFF1B5E20);
  static const Color surfaceWhite = Colors.white;
  static const Color errorRed = Color(0xFFD32F2F);

  static ThemeData getTheme(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;
    final bool isDesktop = width > 1024;

    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundGreen,

      // Ensure the font is loaded in pubspec.yaml
      fontFamily: 'NotoSansEthiopic',

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        onPrimary: Colors.white,
        secondary: accentGold,
        onSecondary: primaryGreen,
        surface: Colors.white,
        onSurface: Colors.black87,
        error: errorRed,
        onError: Colors.white,
        brightness: Brightness.light,
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: isDesktop ? 48 : (isMobile ? 28 : 36),
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: isDesktop ? 32 : (isMobile ? 22 : 28),
          fontWeight: FontWeight.bold,
          color: accentGold,
        ),
        titleLarge: TextStyle(
          fontSize: isDesktop ? 22 : 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
        // Used for TextField input and primary reading
        bodyLarge: TextStyle(
          fontSize: isDesktop ? 18 : 16,
          color: Colors.black,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        // Used for secondary text/form descriptions
        bodyMedium: TextStyle(
          fontSize: isDesktop ? 16 : 14,
          color: Colors.black87,
        ),
        // For buttons and high-contrast labels
        labelLarge: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: isDesktop ? 24 : 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          fontFamily: 'NotoSansEthiopic',
        ),
      ),

      // UPDATED: Fixed Type Mismatch (CardThemeData)
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        surfaceTintColor: Colors.white, // Prevents purple tint in Material 3
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: primaryGreen,
          minimumSize: Size(120, isDesktop ? 56 : 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          elevation: 4,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        labelStyle: const TextStyle(
          color: primaryGreen,
          fontWeight: FontWeight.bold,
        ),
        floatingLabelStyle: const TextStyle(
          color: accentGold,
          fontWeight: FontWeight.bold,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentGold, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
      ),

      // UPDATED: Fixed Type Mismatch (TabBarThemeData)
      tabBarTheme: const TabBarThemeData(
        labelColor: accentGold,
        unselectedLabelColor: Colors.white70,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: accentGold,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),

      // ADDED: DialogThemeData for Admin/Farmer Alerts
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          color: primaryGreen,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        contentTextStyle: const TextStyle(color: Colors.black87, fontSize: 16),
      ),

      // ADDED: SnackBarThemeData for Global Feedback
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryGreen,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),

      // ADDED: BottomNavigationBarThemeData for Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
    );
  }
}
