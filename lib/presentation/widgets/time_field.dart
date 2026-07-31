import 'package:flutter/material.dart';

import '../../core/extensions/context_x.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_x.dart';

/// A labelled row that opens the platform time picker and reports the result
/// as minutes since midnight — the unit the whole app stores times in.
class TimeField extends StatelessWidget {
  const TimeField({
    super.key,
    required this.label,
    required this.minutes,
    required this.onChanged,
    this.icon,
    this.use24h = false,
  });

  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;
  final IconData? icon;
  final bool use24h;

  Future<void> _pick(BuildContext context) async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: use24h),
        child: child!,
      ),
    );
    if (result != null) onChanged(result.hour * 60 + result.minute);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: colors.muted),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(color: colors.foreground),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                TimeOfDayX.format(minutes, use24h: use24h),
                style: AppTypography.bodySmall.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
