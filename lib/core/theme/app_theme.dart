import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.coral,
          surface: AppColors.ivory,
        ).copyWith(
          primary: AppColors.coral,
          onPrimary: AppColors.indigo,
          secondary: AppColors.teal,
          onSecondary: AppColors.indigo,
          tertiary: AppColors.periwinkle,
          surface: AppColors.ivory,
          onSurface: AppColors.indigo,
          error: AppColors.coralInk,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ivory,
      fontFamily: AppType.family,
      fontFamilyFallback: AppType.fallback,
      textTheme: AppType.textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.indigo,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppType.titleSmall,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.indigo,
        contentTextStyle: AppType.bodySmall.copyWith(color: AppColors.ivory),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
