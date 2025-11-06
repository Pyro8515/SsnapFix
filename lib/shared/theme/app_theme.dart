import 'package:flutter/material.dart';

/// App-wide design tokens
class AppTokens {
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Shadows
  static List<BoxShadow> shadowS = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowM = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowL = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Color palette - Deep Teal theme
class AppColors {
  // Primary - Deep Teal
  static const Color primary = Color(0xFF006B6B);
  static const Color primaryLight = Color(0xFF008B8B);
  static const Color primaryDark = Color(0xFF004D4D);

  // Secondary - Customer: Warm Orange, Professional: Indigo
  static const Color secondaryCustomer = Color(0xFFFF6B35);
  static const Color secondaryPro = Color(0xFF6366F1);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Neutral - Customer
  static const Color backgroundCustomer = Color(0xFFFFFFFF);
  static const Color surfaceCustomer = Color(0xFFF9FAFB);
  static const Color borderCustomer = Color(0xFFE5E7EB);
  static const Color textPrimaryCustomer = Color(0xFF111827);
  static const Color textSecondaryCustomer = Color(0xFF6B7280);
  static const Color textDisabledCustomer = Color(0xFF9CA3AF);

  // Neutral - Professional
  static const Color backgroundPro = Color(0xFFF3F4F6);
  static const Color surfacePro = Color(0xFFFFFFFF);
  static const Color borderPro = Color(0xFFD1D5DB);
  static const Color textPrimaryPro = Color(0xFF111827);
  static const Color textSecondaryPro = Color(0xFF4B5563);
  static const Color textDisabledPro = Color(0xFF9CA3AF);

  // Service Icons (Customer - Pastel)
  static const Color servicePlumbing = Color(0xFF60A5FA);
  static const Color serviceElectrical = Color(0xFFFBBF24);
  static const Color serviceHVAC = Color(0xFF34D399);
  static const Color serviceLocksmith = Color(0xFFA78BFA);
  static const Color serviceHandyman = Color(0xFFF87171);
  static const Color serviceCleaning = Color(0xFF818CF8);
  static const Color serviceLandscaping = Color(0xFF4ADE80);
  static const Color servicePainting = Color(0xFFFFC107);
}

/// Customer Theme - Simple, Friendly, Approachable
class CustomerTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondaryCustomer,
        error: AppColors.error,
        surface: AppColors.surfaceCustomer,
        background: AppColors.backgroundCustomer,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: AppColors.textPrimaryCustomer,
        onBackground: AppColors.textPrimaryCustomer,
      ),
      scaffoldBackgroundColor: AppColors.backgroundCustomer,
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusL),
        ),
        color: AppColors.surfaceCustomer,
        margin: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingM,
          vertical: AppTokens.spacingS,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.backgroundCustomer,
        foregroundColor: AppColors.textPrimaryCustomer,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimaryCustomer,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacingL,
            vertical: AppTokens.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusM),
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondaryCustomer,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacingL,
            vertical: AppTokens.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusM),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacingL,
            vertical: AppTokens.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusM),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCustomer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusM),
          borderSide: const BorderSide(color: AppColors.borderCustomer),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusM),
          borderSide: const BorderSide(color: AppColors.borderCustomer),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusM),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingM,
          vertical: AppTokens.spacingM,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryCustomer,
          height: 1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryCustomer,
          height: 1.5,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryCustomer,
          height: 1.5,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryCustomer,
          height: 1.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryCustomer,
          height: 1.5,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryCustomer,
          height: 1.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryCustomer,
          height: 1.5,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryCustomer,
          height: 1.5,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryCustomer,
          height: 1.5,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimaryCustomer,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryCustomer,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryCustomer,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryCustomer,
          height: 1.5,
        ),
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryCustomer,
          height: 1.5,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondaryCustomer,
          height: 1.5,
        ),
      ),
    );
  }
}

/// Professional Theme - Efficient, Data-Driven, Professional
class ProfessionalTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondaryPro,
        error: AppColors.error,
        surface: AppColors.surfacePro,
        background: AppColors.backgroundPro,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: AppColors.textPrimaryPro,
        onBackground: AppColors.textPrimaryPro,
      ),
      scaffoldBackgroundColor: AppColors.backgroundPro,
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusM),
        ),
        color: AppColors.surfacePro,
        margin: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingM,
          vertical: AppTokens.spacingS,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.backgroundPro,
        foregroundColor: AppColors.textPrimaryPro,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimaryPro,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacingM,
            vertical: AppTokens.spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusS),
          ),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondaryPro,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacingM,
            vertical: AppTokens.spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusS),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacingM,
            vertical: AppTokens.spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusS),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfacePro,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusS),
          borderSide: const BorderSide(color: AppColors.borderPro),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusS),
          borderSide: const BorderSide(color: AppColors.borderPro),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusS),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusS),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingM,
          vertical: AppTokens.spacingS,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryPro,
          height: 1.4,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryPro,
          height: 1.4,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryPro,
          height: 1.4,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryPro,
          height: 1.4,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryPro,
          height: 1.4,
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryPro,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryPro,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryPro,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryPro,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimaryPro,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryPro,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryPro,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryPro,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryPro,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondaryPro,
          height: 1.4,
        ),
      ),
    );
  }
}

