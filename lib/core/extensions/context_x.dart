import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ergonomic access to theme tokens and common navigation/feedback helpers.
extension ContextX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  TextTheme get text => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  MediaQueryData get mq => MediaQuery.of(this);

  Size get screenSize => MediaQuery.sizeOf(this);

  bool get isCompact => MediaQuery.sizeOf(this).width < 380;

  void showSnack(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(this);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.error : colors.foreground,
      ),
    );
  }
}
