import 'package:flutter/material.dart';

class AppTheme {
  // Official Brand Colors derived directly from uploaded reference design
  static const Color primaryNavy = Color(0xFF0B2545);      // Deep Academic Postal Navy
  static const Color primaryDark = Color(0xFF07182C);      // Darkest Navy
  static const Color secondaryMaroon = Color(0xFFC81D25);  // Vibrant Postal Crimson/Red (Live Test Banner)
  static const Color secondaryMaroonLight = Color(0xFFE53935);

  // Luxurious Gold Palette (from Welcome Card & Bell in uploaded reference)
  static const Color goldBorder = Color(0xFFC89B3C);       // Golden Frame Outer Border
  static const Color goldInnerBorder = Color(0xFFDFBC69);  // Golden Frame Inner Border
  static const Color goldGradientStart = Color(0xFFFAF2DC);// Champagne Gold Start
  static const Color goldGradientEnd = Color(0xFFF5E4B5);  // Gold Shimmer End
  static const Color goldChipBg = Color(0xFFDCA938);       // SESSION 2026 Chip
  static const Color goldBell = Color(0xFFD97706);         // Notification Bell Amber/Gold

  // Backwards-compatible aliases
  static const Color accentGold = goldBorder;
  static const Color accentGoldLight = goldGradientStart;

  // Backgrounds & Warm Postal Paper Surfaces (from uploaded reference)
  static const Color bgWarm = Color(0xFFFAF7EE);           // Warm Parchment / Cream Backdrop
  static const Color surfaceWarmWhite = Color(0xFFFFFDF8); // Clean Card Surface
  static const Color surfaceCream = Color(0xFFF4EFE6);     // Icon Box Warm Cream Fill
  static const Color borderWarmSubtle = Color(0xFFEADBBE); // Subtle Warm Border

  // Aliases for seamless compatibility
  static const Color bgLight = bgWarm;
  static const Color surfaceWhite = surfaceWarmWhite;
  static const Color borderSubtle = borderWarmSubtle;

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);      // High Contrast Deep Slate
  static const Color textSecondary = Color(0xFF475569);    // Balanced Slate Gray
  static const Color textMuted = Color(0xFF94A3B8);        // Subtle Hint Text
  static const Color textOnPrimary = Color(0xFFFFFFFF);    // White on Navy/Maroon

  // Status & Feedback Colors
  static const Color successGreen = Color(0xFF059669);     // FREE Pill & Correct MCQ Answer
  static const Color successGreenBg = Color(0xFFECFDF5);   // Soft Green Fill
  static const Color errorRed = Color(0xFFEF4444);         // Wrong Answer Red
  static const Color errorRedBg = Color(0xFFFEF2F2);       // Soft Red Fill
  static const Color warningAmber = Color(0xFFF59E0B);     // Live Test Timer Warning
  static const Color infoBlue = Color(0xFF0284C7);         // Information Alert
  static const Color viewAllRed = Color(0xFFB91C1C);       // View All Link Red

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryNavy,
      scaffoldBackgroundColor: bgWarm,
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        onPrimary: surfaceWhite,
        secondary: secondaryMaroon,
        onSecondary: surfaceWhite,
        tertiary: goldBorder,
        onTertiary: primaryNavy,
        surface: surfaceWhite,
        onSurface: textPrimary,
        error: errorRed,
        onError: surfaceWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWarmWhite,
        foregroundColor: primaryNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: primaryNavy,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: primaryNavy),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 2,
        shadowColor: primaryNavy.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryMaroon,
          foregroundColor: surfaceWhite,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryNavy,
          side: const BorderSide(color: primaryNavy, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: secondaryMaroon,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryNavy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed),
        ),
      ),
    );
  }
}
