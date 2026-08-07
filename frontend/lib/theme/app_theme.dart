import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandOrange,
      brightness: Brightness.light,
      primary: AppColors.brandOrange,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.brandBlue,
      onSecondary: AppColors.textOnPrimary,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.textOnError,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.grey50,
      fontFamily: 'Inter',

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Space Grotesk', fontSize: 40, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -1.0),
        displayMedium: TextStyle(fontFamily: 'Space Grotesk', fontSize: 36, fontWeight: FontWeight.w700, height: 1.18, letterSpacing: -0.8),
        displaySmall: TextStyle(fontFamily: 'Space Grotesk', fontSize: 32, fontWeight: FontWeight.w700, height: 1.22, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontFamily: 'Space Grotesk', fontSize: 28, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.3),
        headlineMedium: TextStyle(fontFamily: 'Space Grotesk', fontSize: 24, fontWeight: FontWeight.w700, height: 1.28, letterSpacing: -0.2),
        headlineSmall: TextStyle(fontFamily: 'Space Grotesk', fontSize: 20, fontWeight: FontWeight.w600, height: 1.33),
        titleLarge: TextStyle(fontFamily: 'Space Grotesk', fontSize: 18, fontWeight: FontWeight.w700, height: 1.4),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.6),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.57),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.54),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.33),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45),
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.grey600, size: 24),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardLight,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm / 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandOrange,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.grey200,
          disabledForegroundColor: AppColors.grey400,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          side: const BorderSide(color: AppColors.grey200, width: 1.5),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.brandOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 14),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.grey800,
        contentTextStyle: const TextStyle(color: AppColors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.grey300,
        dragHandleSize: Size(32, 4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: AppElevation.highest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Space Grotesk', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey100,
        selectedColor: AppColors.brandOrange,
        disabledColor: AppColors.grey100,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        side: const BorderSide(color: AppColors.grey200, width: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 0),
        showCheckmark: false,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.grey100,
        thickness: 1,
        space: 0,
        indent: 0,
        endIndent: 0,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
        titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        subtitleTextStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        leadingAndTrailingTextStyle: TextStyle(fontSize: 22, color: AppColors.grey600),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.brandOrange,
        unselectedItemColor: AppColors.grey400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.darkPrimary,
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkText,
      secondary: AppColors.brandBlue,
      onSecondary: AppColors.darkText,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      error: AppColors.error,
      onError: AppColors.darkText,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      fontFamily: 'Inter',

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Space Grotesk', fontSize: 40, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -1.0, color: AppColors.darkText),
        displayMedium: TextStyle(fontFamily: 'Space Grotesk', fontSize: 36, fontWeight: FontWeight.w700, height: 1.18, letterSpacing: -0.8, color: AppColors.darkText),
        displaySmall: TextStyle(fontFamily: 'Space Grotesk', fontSize: 32, fontWeight: FontWeight.w700, height: 1.22, letterSpacing: -0.5, color: AppColors.darkText),
        headlineLarge: TextStyle(fontFamily: 'Space Grotesk', fontSize: 28, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.3, color: AppColors.darkText),
        headlineMedium: TextStyle(fontFamily: 'Space Grotesk', fontSize: 24, fontWeight: FontWeight.w700, height: 1.28, letterSpacing: -0.2, color: AppColors.darkText),
        headlineSmall: TextStyle(fontFamily: 'Space Grotesk', fontSize: 20, fontWeight: FontWeight.w600, height: 1.33, color: AppColors.darkText),
        titleLarge: TextStyle(fontFamily: 'Space Grotesk', fontSize: 18, fontWeight: FontWeight.w700, height: 1.4, color: AppColors.darkText),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5, color: AppColors.darkText),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43, color: AppColors.darkTextSecondary),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.6, color: AppColors.darkTextSecondary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.57, color: AppColors.darkTextSecondary),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.54, color: AppColors.darkTextTertiary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43, color: AppColors.darkTextSecondary),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.33, color: AppColors.darkTextTertiary),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45, color: AppColors.darkTextTertiary),
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.darkText,
        titleTextStyle: TextStyle(
          fontFamily: 'Space Grotesk', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkText, letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.darkTextSecondary, size: 24),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkCard,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm / 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkText,
          disabledBackgroundColor: AppColors.darkSurface,
          disabledForegroundColor: AppColors.darkTextTertiary,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkPrimary),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 14),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: const TextStyle(color: AppColors.darkText, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.darkBorder,
        dragHandleSize: Size(32, 4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        elevation: AppElevation.highest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Space Grotesk', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkText,
        ),
        contentTextStyle: const TextStyle(fontSize: 14, color: AppColors.darkTextSecondary, height: 1.5),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedColor: AppColors.darkPrimary,
        disabledColor: AppColors.darkSurface,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        side: const BorderSide(color: AppColors.darkBorder, width: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 0),
        showCheckmark: false,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 0,
        indent: 0,
        endIndent: 0,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
        titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.darkText),
        subtitleTextStyle: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
        leadingAndTrailingTextStyle: TextStyle(fontSize: 22, color: AppColors.darkTextSecondary),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
