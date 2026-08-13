// Flutter 3.43 stopped re-exporting this from material.dart.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the app's single light theme from the [AppColors] palette.
///
/// Vynqix is light-only on purpose: one theme means every colour can be
/// chosen for contrast against white rather than compromised to work on both
/// backgrounds. Change a token in `app_colors.dart` and the whole app follows.
abstract final class AppTheme {
  static ThemeData light() {
    const AppColors c = AppColors.light;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: c.primary,
          onPrimary: Colors.white,
          primaryContainer: c.primarySoft,
          onPrimaryContainer: c.primary,
          secondary: c.secondary,
          onSecondary: Colors.white,
          tertiary: c.accent,
          surface: c.surface,
          onSurface: c.foreground,
          onSurfaceVariant: c.muted,
          surfaceContainerHighest: c.surfaceAlt,
          error: c.error,
          onError: Colors.white,
          outline: c.border,
          outlineVariant: c.border,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.border,
      splashFactory: InkRipple.splashFactory,
      textTheme: AppTypography.textTheme(c.foreground, c.muted),
      extensions: const <ThemeExtension<dynamic>>[AppColors.light],

      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.foreground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: c.foreground.withValues(alpha: 0.08),
        centerTitle: false,
        iconTheme: IconThemeData(color: c.foreground, size: 22),
        actionsIconTheme: IconThemeData(color: c.muted, size: 22),
        titleTextStyle: AppTypography.title.copyWith(color: c.foreground),
        // Dark status-bar glyphs, since the bar is always light.
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: c.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),

      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          side: BorderSide(color: c.border),
        ),
      ),

      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),

      iconTheme: IconThemeData(color: c.muted, size: 22),

      listTileTheme: ListTileThemeData(
        iconColor: c.muted,
        textColor: c.foreground,
        titleTextStyle: AppTypography.body.copyWith(color: c.foreground),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(color: c.muted),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceAlt,
        hintStyle: AppTypography.body.copyWith(color: c.faint),
        labelStyle: AppTypography.bodySmall.copyWith(color: c.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        border: _inputBorder(c.border),
        enabledBorder: _inputBorder(c.border),
        focusedBorder: _inputBorder(c.primary, width: 1.6),
        errorBorder: _inputBorder(c.error),
        focusedErrorBorder: _inputBorder(c.error, width: 1.6),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.surfaceAlt,
          disabledForegroundColor: c.faint,
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          textStyle: AppTypography.subtitle,
          shape: const StadiumBorder(),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.foreground,
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: c.border),
          textStyle: AppTypography.subtitle,
          shape: const StadiumBorder(),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: AppTypography.subtitle,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: const StadiumBorder(),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.primarySoft,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 23,
            color: s.contains(WidgetState.selected) ? c.primary : c.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppTypography.caption.copyWith(
            color: s.contains(WidgetState.selected) ? c.primary : c.muted,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.overlay,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.title.copyWith(color: c.foreground),
        contentTextStyle: AppTypography.bodySmall.copyWith(color: c.muted),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.foreground,
        contentTextStyle: AppTypography.bodySmall.copyWith(color: Colors.white),
        actionTextColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        insetPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : Colors.white,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: c.faint, width: 1.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm - 2),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        inactiveTrackColor: c.surfaceAlt,
        thumbColor: c.primary,
        overlayColor: c.primary.withValues(alpha: 0.12),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceAlt,
        selectedColor: c.primarySoft,
        side: BorderSide(color: c.border),
        labelStyle: AppTypography.bodySmall.copyWith(color: c.foreground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surfaceAlt,
        circularTrackColor: c.surfaceAlt,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppTypography.body.copyWith(color: c.foreground),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: c.surface,
        dialBackgroundColor: c.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
