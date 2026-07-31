import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/extensions/context_x.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../providers/app_providers.dart';

/// Step 1 of onboarding: who the user is and what they are working towards.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _goal = TextEditingController();
  String _occupation = 'Professional';
  String _avatar = '🙂';

  static const _occupations = [
    'Student',
    'Professional',
    'Founder',
    'Freelancer',
    'Parent',
    'Other',
  ];

  static const _avatars = ['🙂', '😎', '🚀', '🧠', '🌱', '🔥', '⭐', '🦊'];

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    await ref
        .read(profileProvider.notifier)
        .edit(
          (p) => p.copyWith(
            name: _name.text.trim(),
            occupation: _occupation,
            goal: _goal.text.trim(),
            avatarEmoji: _avatar,
          ),
        );
    if (mounted) context.push(Routes.onboardingLifestyle);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('About you')),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          children: [
            const _StepIndicator(step: 1),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Let’s make this yours',
              style: AppTypography.titleLarge.copyWith(
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Used to personalise your dashboard and suggestions. '
              'Nothing leaves your device.',
              style: AppTypography.bodySmall.copyWith(color: colors.muted),
            ),
            const SizedBox(height: AppSpacing.xxl),

            _Label('Pick an avatar'),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: _avatars.map((emoji) {
                final selected = emoji == _avatar;
                return GestureDetector(
                  onTap: () => setState(() => _avatar = emoji),
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.primary.withValues(alpha: 0.14)
                          : colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: selected ? colors.primary : colors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            _Label('Your name'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'e.g. Rishitha'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.xl),

            _Label('What describes you best?'),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _occupations.map((o) {
                final selected = o == _occupation;
                return ChoiceChip(
                  label: Text(o),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _occupation = o),
                  selectedColor: colors.primary.withValues(alpha: 0.14),
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: selected ? colors.primary : colors.muted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: selected ? colors.primary : colors.border,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            _Label('What are you working towards?'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _goal,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Ship my app and finish my degree',
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: FilledButton(
            onPressed: _name.text.trim().isEmpty ? null : _next,
            child: const Text('Continue'),
          ),
        ),
      ),
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

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: List.generate(2, (i) {
        final active = i < step;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i == 1 ? 0 : AppSpacing.sm),
            decoration: BoxDecoration(
              color: active ? colors.primary : colors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        );
      }),
    );
  }
}
