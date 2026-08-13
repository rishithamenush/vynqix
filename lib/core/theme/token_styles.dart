import 'package:flutter/material.dart';

import '../../domain/enums/task_enums.dart';

/// Visual mapping for domain enums.
///
/// Kept out of the domain layer so entities and enums remain framework-free.
extension TaskCategoryStyle on TaskCategory {
  /// Eight well-separated hues, all around the 600 weight so they stay
  /// legible as small text and 6dp dots on white. None sits near the primary
  /// emerald, so a category dot is never mistaken for a UI accent — health
  /// used to be green and moved to blue when the brand colour did.
  Color get color => switch (this) {
    TaskCategory.work => const Color(0xFF7C3AED),
    TaskCategory.study => const Color(0xFF0891B2),
    TaskCategory.health => const Color(0xFF2563EB),
    TaskCategory.personal => const Color(0xFFEA580C),
    TaskCategory.social => const Color(0xFFDB2777),
    TaskCategory.finance => const Color(0xFFCA8A04),
    TaskCategory.creative => const Color(0xFFC026D3),
    TaskCategory.other => const Color(0xFF64748B),
  };

  IconData get icon => switch (this) {
    TaskCategory.work => Icons.work_outline_rounded,
    TaskCategory.study => Icons.menu_book_rounded,
    TaskCategory.health => Icons.favorite_outline_rounded,
    TaskCategory.personal => Icons.person_outline_rounded,
    TaskCategory.social => Icons.people_outline_rounded,
    TaskCategory.finance => Icons.attach_money_rounded,
    TaskCategory.creative => Icons.palette_outlined,
    TaskCategory.other => Icons.grid_view_rounded,
  };
}

extension TaskPriorityStyle on TaskPriority {
  Color get color => switch (this) {
    TaskPriority.high => const Color(0xFFDC2626),
    TaskPriority.medium => const Color(0xFFC2410C),
    TaskPriority.low => const Color(0xFF15803D),
  };

  IconData get icon => switch (this) {
    TaskPriority.high => Icons.keyboard_double_arrow_up_rounded,
    TaskPriority.medium => Icons.drag_handle_rounded,
    TaskPriority.low => Icons.keyboard_double_arrow_down_rounded,
  };
}

extension TaskStatusStyle on TaskStatus {
  Color color(ColorScheme _) => switch (this) {
    TaskStatus.completed => const Color(0xFF15803D),
    TaskStatus.inProgress => const Color(0xFF2563EB),
    TaskStatus.missed => const Color(0xFFDC2626),
    TaskStatus.skipped => const Color(0xFF64748B),
    TaskStatus.pending => const Color(0xFF98A8A1),
  };

  IconData get icon => switch (this) {
    TaskStatus.completed => Icons.check_circle_rounded,
    TaskStatus.inProgress => Icons.play_circle_fill_rounded,
    TaskStatus.missed => Icons.cancel_rounded,
    TaskStatus.skipped => Icons.remove_circle_outline_rounded,
    TaskStatus.pending => Icons.radio_button_unchecked_rounded,
  };
}

extension MoodStyle on Mood {
  Color get color => switch (this) {
    Mood.great => const Color(0xFF15803D),
    Mood.good => const Color(0xFF2563EB),
    Mood.okay => const Color(0xFFC2410C),
    Mood.bad => const Color(0xFFDC2626),
    Mood.terrible => const Color(0xFF7F1D1D),
  };
}
