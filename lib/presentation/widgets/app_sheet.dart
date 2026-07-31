import 'package:flutter/material.dart';

import '../../core/extensions/context_x.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import 'page_body.dart';

/// One row in an [showOptionsSheet].
///
/// Sheets return their value rather than taking a callback, so the caller acts
/// after the sheet has closed and never has to reason about a `BuildContext`
/// that belongs to a route being popped.
@immutable
class SheetOption<T> {
  const SheetOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.destructive = false,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;

  /// Tints the row red. For actions that delete or discard.
  final bool destructive;
}

/// The app's one modal sheet: grab handle, title, then content.
///
/// Every picker and action menu goes through here so they share the same
/// corner radius, spacing and typography instead of each screen assembling a
/// column of bare `ListTile`s.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: PageBody(
        maxWidth: Breakpoints.readableContent,
        applyGutter: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.title.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Flexible(child: child),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

/// Shows [options] in an [AppSheet] and returns the chosen value, or null if
/// the sheet was dismissed.
Future<T?> showOptionsSheet<T>(
  BuildContext context, {
  required String title,
  required List<SheetOption<T>> options,
  String? subtitle,
  T? selected,
  String? cancelLabel,
}) {
  return showModalBottomSheet<T>(
    context: context,
    // Long pickers (a 12-entry target, every repeat rule) would otherwise be
    // capped at half the screen and clip.
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
    ),
    builder: (sheetContext) => AppSheet(
      title: title,
      subtitle: subtitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: options.length,
              itemBuilder: (context, i) => _OptionRow<T>(
                option: options[i],
                isSelected: selected != null && options[i].value == selected,
                onTap: () => Navigator.pop(sheetContext, options[i].value),
              ),
            ),
          ),
          if (cancelLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                0,
              ),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(cancelLabel),
              ),
            ),
        ],
      ),
    ),
  );
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final SheetOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = option.destructive
        ? colors.error
        : isSelected
        ? colors.primary
        : colors.muted;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              if (option.icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tint.withValues(alpha: 0.12),
                  ),
                  child: Icon(option.icon, size: 18, color: tint),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.label,
                      style: AppTypography.body.copyWith(
                        color: option.destructive
                            ? colors.error
                            : colors.foreground,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    if (option.subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        option.subtitle!,
                        style: AppTypography.caption.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, size: 20, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
