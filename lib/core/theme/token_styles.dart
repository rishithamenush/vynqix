import 'package:flutter/material.dart';

import '../../domain/enums/task_enums.dart';

/// Visual mapping for domain enums.
///
/// Kept out of the domain layer so entities and enums remain framework-free.
extension TaskCategoryStyle on TaskCategory {
  Color get color => switch (this) {
    TaskCategory.work => const Color(0xFF4F46E5),
    TaskCategory.study => const Color(0xFF8B5CF6),
    TaskCategory.health => const Color(0xFF22C55E),
    TaskCategory.personal => const Color(0xFFF59E0B),
    TaskCategory.social => const Color(0xFFEC4899),
    TaskCategory.finance => const Color(0xFF06B6D4),
    TaskCategory.creative => const Color(0xFFEF4444),
    TaskCategory.other => const Color(0xFF6B7280),
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
    TaskPriority.high => const Color(0xFFEF4444),
    TaskPriority.medium => const Color(0xFFF59E0B),
    TaskPriority.low => const Color(0xFF22C55E),
  };

  IconData get icon => switch (this) {
    TaskPriority.high => Icons.keyboard_double_arrow_up_rounded,
    TaskPriority.medium => Icons.drag_handle_rounded,
    TaskPriority.low => Icons.keyboard_double_arrow_down_rounded,
  };
}

extension TaskStatusStyle on TaskStatus {
  Color color(ColorScheme _) => switch (this) {
    TaskStatus.completed => const Color(0xFF22C55E),
    TaskStatus.inProgress => const Color(0xFF4F46E5),
    TaskStatus.missed => const Color(0xFFEF4444),
    TaskStatus.skipped => const Color(0xFF6B7280),
    TaskStatus.pending => const Color(0xFF9CA3AF),
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
    Mood.great => const Color(0xFF22C55E),
    Mood.good => const Color(0xFF4F46E5),
    Mood.okay => const Color(0xFFF59E0B),
    Mood.bad => const Color(0xFFEF4444),
    Mood.terrible => const Color(0xFF7F1D1D),
  };
}
