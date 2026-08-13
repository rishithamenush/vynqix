import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/token_styles.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/day_log.dart';
import '../../../domain/enums/task_enums.dart';
import '../../providers/review_providers.dart';
import '../../providers/stats_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/common.dart';
import '../../widgets/page_body.dart';

/// End-of-day reflection: how the day felt, what worked, what to change.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.dayKey});

  final String dayKey;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _highlight = TextEditingController();
  final _gratitude = TextEditingController();
  final _blocker = TextEditingController();
  final _improvement = TextEditingController();

  Mood? _mood;
  EnergyLevel? _energy;
  int _rating = 0;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _highlight.dispose();
    _gratitude.dispose();
    _blocker.dispose();
    _improvement.dispose();
    super.dispose();
  }

  void _hydrate(DayLog? log) {
    if (_loaded) return;
    _loaded = true;
    if (log == null) return;
    _mood = log.mood;
    _energy = log.energy;
    _rating = log.rating;
    _highlight.text = log.highlight;
    _gratitude.text = log.gratitude;
    _blocker.text = log.blocker;
    _improvement.text = log.improvement;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final existing = await ref.read(dayLogProvider(widget.dayKey).future);
    final base = existing ?? DayLog.empty(widget.dayKey);

    await ref
        .read(reviewControllerProvider)
        .save(
          base.copyWith(
            mood: _mood,
            energy: _energy,
            rating: _rating,
            highlight: _highlight.text.trim(),
            gratitude: _gratitude.text.trim(),
            blocker: _blocker.text.trim(),
            improvement: _improvement.text.trim(),
          ),
        );

    if (!mounted) return;
    setState(() => _saving = false);
    await context.showMessage('Review saved.');
    if (mounted) context.popIfCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logAsync = ref.watch(dayLogProvider(widget.dayKey));
    final stats = ref.watch(dayStatsProvider(widget.dayKey)).valueOrNull;
    final date = DateX.parseKey(widget.dayKey);

    return logAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorStateView(error: e),
      ),
      data: (log) {
        _hydrate(log);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Daily review'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: TextButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save'),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: PageBody(
              maxWidth: Breakpoints.readableContent,
              applyGutter: false,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  context.gutter,
                  AppSpacing.sm,
                  context.gutter,
                  AppSpacing.huge,
                ),
                children: [
                  Text(
                    DateX.fullLabel(date),
                    style: AppTypography.titleLarge.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // How the day objectively went.
                  if (stats != null && stats.total > 0)
                    AppCard(
                      child: Row(
                        children: [
                          _MiniStat(
                            value: '${stats.completed}/${stats.total}',
                            label: 'Tasks done',
                          ),
                          _Divider(),
                          _MiniStat(
                            value: '${(stats.completionRate * 100).round()}%',
                            label: 'Completion',
                          ),
                          _Divider(),
                          _MiniStat(
                            value: DurationX.formatMinutes(stats.focusMinutes),
                            label: 'Focused',
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xxl),

                  _Label('How did today feel?'),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: Mood.values.map((m) {
                      final selected = m == _mood;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _mood = m),
                          child: AnimatedContainer(
                            duration: AppDurations.fast,
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? m.color.withValues(alpha: 0.15)
                                  : colors.surfaceAlt,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: selected ? m.color : colors.border,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  AppIcons.mood(m),
                                  size: 26,
                                  color: selected ? m.color : colors.faint,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  m.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    color: selected ? m.color : colors.muted,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  _Label('Energy level'),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedSelector<EnergyLevel>(
                    values: EnergyLevel.values,
                    selected: _energy ?? EnergyLevel.medium,
                    labelOf: (e) => e.label,
                    iconOf: AppIcons.energy,
                    onChanged: (e) => setState(() => _energy = e),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  _Label('Rate the day'),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < _rating;
                      return Expanded(
                        child: IconButton(
                          onPressed: () => setState(
                            () => _rating = _rating == i + 1 ? 0 : i + 1,
                          ),
                          icon: Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 34,
                            color: filled ? colors.warning : colors.border,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  _Field(
                    label: 'Highlight of the day',
                    hint: 'The one thing worth remembering',
                    controller: _highlight,
                  ),
                  _Field(
                    label: 'Grateful for',
                    hint: 'Something that went right',
                    controller: _gratitude,
                  ),
                  _Field(
                    label: 'What got in the way',
                    hint: 'Interruptions, blockers, distractions',
                    controller: _blocker,
                  ),
                  _Field(
                    label: 'One thing to change tomorrow',
                    hint: 'Small and specific beats ambitious',
                    controller: _improvement,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.subtitle.copyWith(color: context.colors.foreground),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(label),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.title.copyWith(color: colors.foreground),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: context.colors.border);
}
