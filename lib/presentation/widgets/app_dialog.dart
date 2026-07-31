import 'package:flutter/material.dart';

import '../../core/extensions/context_x.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// The app's one popup box: tinted icon disc, headline, optional body, then
/// full-width pill buttons stacked down the card.
///
/// Every dialog and every message goes through this so a confirmation and a
/// "saved" notice are recognisably the same object.
class AppDialogBox extends StatelessWidget {
  const AppDialogBox({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    required this.actions,
    this.message,
    this.compactTitle = false,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String? message;

  /// Buttons, top to bottom. The first one is the primary action.
  final List<Widget> actions;

  /// Sizes the headline for a one-line message rather than a question.
  final bool compactTitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxl,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: tint, size: 24),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style:
                  (compactTitle ? AppTypography.subtitle : AppTypography.title)
                      .copyWith(color: colors.foreground),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppTypography.bodySmall.copyWith(color: colors.muted),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }
}

extension MessageX on BuildContext {
  /// Shows a message in the same box as [confirmDialog].
  ///
  /// Dismissing is a tap on the button or on the barrier — there is no timer,
  /// because a box in the middle of the screen that vanishes on its own is
  /// easy to miss and impossible to re-read.
  Future<void> showMessage(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    String dismissLabel = 'OK',
  }) async {
    final tint = isError
        ? colors.error
        : isSuccess
        ? colors.success
        : colors.primary;
    final glyph =
        icon ??
        (isError
            ? Icons.error_outline_rounded
            : isSuccess
            ? Icons.check_circle_outline_rounded
            : Icons.info_outline_rounded);

    final tookAction = await showDialog<bool>(
      context: this,
      builder: (context) => AppDialogBox(
        icon: glyph,
        tint: tint,
        title: message,
        compactTitle: true,
        actions: [
          if (actionLabel != null)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: tint,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(actionLabel),
            ),
          if (actionLabel == null)
            FilledButton(
              onPressed: () => Navigator.pop(context, false),
              style: FilledButton.styleFrom(
                backgroundColor: tint,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(dismissLabel),
            )
          else
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Dismiss'),
            ),
        ],
      ),
    );

    if (tookAction ?? false) onAction?.call();
  }
}
