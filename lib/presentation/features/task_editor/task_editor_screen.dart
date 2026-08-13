import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/token_styles.dart';
import '../../../core/utils/async_guard.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/subtask.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/enums/task_enums.dart';
import '../../providers/app_providers.dart';
import '../../providers/task_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';

/// Create or edit a task. One screen serves both so the fields, validation
/// and layout can never drift apart between the two flows.
class TaskEditorScreen extends ConsumerStatefulWidget {
  const TaskEditorScreen({super.key, this.taskId, this.dayKey});

  /// When set the screen edits an existing task; otherwise it creates one.
  final String? taskId;

  /// Day to pre-select for a new task.
  final String? dayKey;

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();
  final _tags = TextEditingController();
  final _subtaskInput = TextEditingController();

  Task? _original;
  bool _loaded = false;
  bool _saving = false;

  late String _dayKey = widget.dayKey ?? DateX.tomorrowKey;
  TaskCategory _category = TaskCategory.work;
  TaskPriority _priority = TaskPriority.medium;
  RepeatRule _repeat = RepeatRule.none;
  int? _startMinutes;
  int _duration = 30;
  int? _reminder;
  String? _iconKey;
  List<Subtask> _subtasks = [];

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (!_isEditing) _loaded = true;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _notes.dispose();
    _tags.dispose();
    _subtaskInput.dispose();
    super.dispose();
  }

  void _hydrate(Task task) {
    if (_loaded) return;
    _original = task;
    _title.text = task.title;
    _description.text = task.description;
    _notes.text = task.notes;
    _tags.text = task.tags.join(', ');
    _dayKey = task.dayKey;
    _category = task.category;
    _priority = task.priority;
    _repeat = task.repeat;
    _startMinutes = task.startMinutes;
    _duration = task.durationMinutes;
    _reminder = task.reminderMinutesBefore;
    _iconKey = task.iconKey;
    _subtasks = [...task.subtasks];
    _loaded = true;
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);
    final controller = ref.read(taskControllerProvider);
    final tags = _tags.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final base = _original ?? controller.draft(dayKey: _dayKey);
    final task = base.copyWith(
      title: title,
      description: _description.text.trim(),
      notes: _notes.text.trim(),
      iconKey: _iconKey,
      clearIcon: _iconKey == null,
      dayKey: _dayKey,
      category: _category,
      priority: _priority,
      startMinutes: _startMinutes,
      clearStartMinutes: _startMinutes == null,
      durationMinutes: _duration,
      tags: tags,
      subtasks: _subtasks,
      repeat: _repeat,
      reminderMinutesBefore: _reminder,
      clearReminder: _reminder == null,
    );

    if (_isEditing) {
      await controller.update(task, applyToSeries: false);
    } else {
      await controller.create(task);
    }

    if (mounted) {
      setState(() => _saving = false);
      context.popIfCurrent();
    }
  }

  Future<void> _delete() => OneShot.run('taskEditor.delete', () async {
    final task = _original;
    if (task == null) return;

    // A repeating task has two reasonable meanings for "delete". Asking is
    // the only safe option — guessing either way loses data.
    final _DeleteScope? scope;
    if (task.repeat.repeats && task.seriesId != null) {
      scope = await _askDeleteScope(task);
    } else {
      final confirmed = await confirmDialog(
        context,
        title: 'Delete task?',
        message: '“${task.title}” will be removed permanently.',
      );
      scope = confirmed ? _DeleteScope.single : null;
    }

    if (scope == null || !mounted) return;

    await ref
        .read(taskControllerProvider)
        .delete(task, wholeSeries: scope == _DeleteScope.series);

    if (mounted) context.popIfCurrent();
  });

  Future<_DeleteScope?> _askDeleteScope(Task task) {
    return showOptionsSheet<_DeleteScope>(
      context,
      title: 'This task repeats',
      subtitle: '“${task.title}” is part of a series.',
      cancelLabel: 'Cancel',
      options: const [
        SheetOption(
          value: _DeleteScope.single,
          label: 'Delete this occurrence',
          subtitle: 'Future repeats stay',
          icon: Icons.event_busy_rounded,
        ),
        SheetOption(
          value: _DeleteScope.series,
          label: 'Delete this and all future',
          subtitle: 'The whole series goes',
          icon: Icons.delete_sweep_rounded,
          destructive: true,
        ),
      ],
    );
  }

  /// Whether the form differs from what was loaded, so closing can warn
  /// before throwing work away.
  bool get _isDirty {
    final task = _original;
    if (task == null) {
      return _title.text.trim().isNotEmpty ||
          _description.text.trim().isNotEmpty ||
          _notes.text.trim().isNotEmpty ||
          _tags.text.trim().isNotEmpty ||
          _subtasks.isNotEmpty ||
          _iconKey != null ||
          _startMinutes != null;
    }
    return _title.text.trim() != task.title ||
        _description.text.trim() != task.description ||
        _notes.text.trim() != task.notes ||
        _tags.text.trim() != task.tags.join(', ') ||
        _iconKey != task.iconKey ||
        _dayKey != task.dayKey ||
        _category != task.category ||
        _priority != task.priority ||
        _repeat != task.repeat ||
        _startMinutes != task.startMinutes ||
        _duration != task.durationMinutes ||
        _reminder != task.reminderMinutesBefore ||
        _subtasks.length != task.subtasks.length;
  }

  /// Confirms before discarding unsaved edits.
  Future<void> _handleClose() => OneShot.run('taskEditor.close', () async {
    if (!_isDirty) {
      context.popIfCurrent();
      return;
    }
    final discard = await confirmDialog(
      context,
      title: 'Discard changes?',
      message: 'Your edits to this task have not been saved.',
      confirmLabel: 'Discard',
    );
    if (discard && mounted) context.popIfCurrent();
  });

  @override
  Widget build(BuildContext context) {
    if (_isEditing && !_loaded) {
      final async = ref.watch(taskByIdProvider(widget.taskId!));
      return async.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: ErrorStateView(error: e),
        ),
        data: (task) {
          if (task == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Task not found',
                message: 'It may have been deleted from another screen.',
              ),
            );
          }
          _hydrate(task);
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final colors = context.colors;
    final settings = ref.watch(settingsValueProvider);
    final canSave = _title.text.trim().isNotEmpty && !_saving;

    return PopScope(
      // Intercept the back gesture / hardware back so unsaved edits are not
      // silently discarded.
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleClose();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit task' : 'New task'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            onPressed: _handleClose,
          ),
          actions: [
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _delete,
                tooltip: 'Delete',
              ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
        body: SafeArea(
          child: PageBody(
            maxWidth: Breakpoints.readableContent,
            applyGutter: false,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                context.gutter,
                AppSpacing.sm,
                context.gutter,
                AppSpacing.huge,
              ),
              children: [
                // What the task is, on one card, so the page opens on the only
                // field that is actually required.
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _title,
                        // Deliberately not autofocused: the keyboard covering half
                        // the screen the moment the editor opens hides the
                        // schedule controls right below the title.
                        textCapitalization: TextCapitalization.sentences,
                        style: AppTypography.title.copyWith(
                          color: colors.foreground,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'What needs doing?',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      Divider(color: colors.border, height: 1),
                      TextField(
                        controller: _description,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Add a short description',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                _FieldLabel('Icon'),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppIcons.taskIcons.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final option = AppIcons.taskIcons[i];
                      final selected = option.key == _iconKey;
                      return Semantics(
                        label: option.label,
                        selected: selected,
                        button: true,
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _iconKey = selected ? null : option.key,
                          ),
                          child: AnimatedContainer(
                            duration: AppDurations.fast,
                            width: 46,
                            decoration: BoxDecoration(
                              color: selected
                                  ? colors.primarySoft
                                  : colors.surfaceAlt,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? colors.primary
                                    : colors.border,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Icon(
                              option.icon,
                              size: 21,
                              color: selected ? colors.primary : colors.muted,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                _FieldLabel('When'),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: DateX.relativeLabel(DateX.parseKey(_dayKey)),
                        onTap: _pickDate,
                      ),
                      Divider(color: colors.border, height: 1),
                      _Row(
                        icon: Icons.schedule_rounded,
                        label: 'Start time',
                        value: _startMinutes == null
                            ? 'Unscheduled'
                            : TimeOfDayX.format(
                                _startMinutes!,
                                use24h: settings.use24HourClock,
                              ),
                        onTap: _pickTime,
                        onClear: _startMinutes == null
                            ? null
                            : () => setState(() => _startMinutes = null),
                      ),
                      Divider(color: colors.border, height: 1),
                      _Row(
                        icon: Icons.repeat_rounded,
                        label: 'Repeat',
                        value: _repeat.label,
                        onTap: _pickRepeat,
                      ),
                      Divider(color: colors.border, height: 1),
                      _Row(
                        icon: Icons.notifications_none_rounded,
                        label: 'Reminder',
                        value: _reminder == null
                            ? 'None'
                            : '$_reminder min before',
                        onTap: _startMinutes == null
                            ? () => context.showMessage(
                                'Set a start time before adding a reminder.',
                              )
                            : _pickReminder,
                        onClear: _reminder == null
                            ? null
                            : () => setState(() => _reminder = null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                _FieldLabel('How long'),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants.taskDurations.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final minutes = AppConstants.taskDurations[i];
                      final selected = minutes == _duration;
                      return _Chip(
                        label: DurationX.formatMinutes(minutes),
                        selected: selected,
                        onTap: () => setState(() => _duration = minutes),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                _FieldLabel('Category'),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: TaskCategory.values.map((c) {
                    final selected = c == _category;
                    return _Chip(
                      label: c.label,
                      icon: c.icon,
                      color: c.color,
                      selected: selected,
                      onTap: () => setState(() => _category = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xxl),

                _FieldLabel('Priority'),
                const SizedBox(height: AppSpacing.md),
                SegmentedSelector<TaskPriority>(
                  values: TaskPriority.values,
                  selected: _priority,
                  labelOf: (p) => p.label,
                  colorOf: (p) => p.color,
                  iconOf: (p) => p.icon,
                  onChanged: (p) => setState(() => _priority = p),
                ),
                const SizedBox(height: AppSpacing.xxl),

                _FieldLabel('Checklist'),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      for (final sub in _subtasks)
                        Row(
                          key: ValueKey(sub.id),
                          children: [
                            Checkbox(
                              value: sub.isDone,
                              onChanged: (v) => setState(() {
                                _subtasks = _subtasks
                                    .map(
                                      (s) => s.id == sub.id
                                          ? s.copyWith(isDone: v ?? false)
                                          : s,
                                    )
                                    .toList();
                              }),
                            ),
                            Expanded(
                              child: Text(
                                sub.title,
                                style: AppTypography.bodySmall.copyWith(
                                  color: sub.isDone
                                      ? colors.muted
                                      : colors.foreground,
                                  decoration: sub.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => setState(
                                () => _subtasks = _subtasks
                                    .where((s) => s.id != sub.id)
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextField(
                              controller: _subtaskInput,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                hintText: 'Add a step',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                              ),
                              onSubmitted: (_) => _addSubtask(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded),
                            onPressed: _addSubtask,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                _FieldLabel('Tags'),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _tags,
                  decoration: const InputDecoration(
                    hintText: 'comma, separated, tags',
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                _FieldLabel('Notes'),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _notes,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Anything else worth remembering',
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                if (_isEditing && _original != null)
                  OutlinedButton.icon(
                    onPressed: () => context.pushReplacement(
                      '${Routes.focus}?taskId=${_original!.id}',
                    ),
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('Start focus session'),
                  ),
              ],
            ),
          ),
        ),
        // The primary action lives here rather than as a small word in the app
        // bar: it stays in reach on a long form and reads as the one thing to
        // do next.
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: SafeArea(
            child: PageBody(
              maxWidth: Breakpoints.readableContent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: FilledButton(
                  onPressed: _saving
                      ? null
                      : canSave
                      ? _save
                      : () =>
                            context.showMessage('Give the task a title first.'),
                  child: Text(
                    _saving
                        ? 'Saving…'
                        : _isEditing
                        ? 'Save changes'
                        : 'Add task',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addSubtask() {
    final text = _subtaskInput.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks = [
        ..._subtasks,
        Subtask(id: newId(), title: text, sortIndex: _subtasks.length),
      ];
      _subtaskInput.clear();
    });
  }

  Future<void> _pickDate() async {
    final current = DateX.parseKey(_dayKey);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _dayKey = picked.dayKey);
  }

  Future<void> _pickTime() async {
    final settings = ref.read(settingsValueProvider);
    final initial = _startMinutes ?? 9 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(alwaysUse24HourFormat: settings.use24HourClock),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _startMinutes = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _pickRepeat() async {
    final picked = await showOptionsSheet<RepeatRule>(
      context,
      title: 'Repeat',
      selected: _repeat,
      options: [
        for (final rule in RepeatRule.values)
          SheetOption(
            value: rule,
            label: rule.label,
            icon: rule.repeats ? Icons.repeat_rounded : Icons.block_flipped,
          ),
      ],
    );
    if (picked != null) setState(() => _repeat = picked);
  }

  Future<void> _pickReminder() async {
    const options = [5, 10, 15, 30, 60];
    final picked = await showOptionsSheet<int>(
      context,
      title: 'Reminder',
      subtitle: 'How long before the start time to notify you.',
      selected: _reminder,
      options: [
        for (final m in options)
          SheetOption(
            value: m,
            label: '$m minutes before',
            icon: Icons.notifications_none_rounded,
          ),
      ],
    );
    if (picked != null) setState(() => _reminder = picked);
  }
}

/// Which occurrences a delete applies to.
enum _DeleteScope { single, series }

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppTypography.caption.copyWith(
      color: context.colors.muted,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: onTap == null ? colors.border : colors.muted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: onTap == null ? colors.muted : colors.foreground,
                ),
              ),
            ),
            Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: onClear,
                visualDensity: VisualDensity.compact,
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colors.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = color ?? colors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? tint.withValues(alpha: 0.14) : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? tint : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: selected ? tint : colors.muted),
              const SizedBox(width: AppSpacing.xs + 2),
            ],
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: selected ? tint : colors.muted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
