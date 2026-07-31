import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ergonomic access to theme tokens.
///
/// Transient messages live in `presentation/widgets/app_dialog.dart` as
/// `context.showMessage` — they need app widgets, which core must not import.
extension ContextX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  TextTheme get text => Theme.of(this).textTheme;

  MediaQueryData get mq => MediaQuery.of(this);

  Size get screenSize => MediaQuery.sizeOf(this);

  bool get isCompact => MediaQuery.sizeOf(this).width < 380;
}
