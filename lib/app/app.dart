import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

/// Root widget. Rebuilds only when the theme preference changes.
class VynqixApp extends ConsumerWidget {
  const VynqixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      // Light-only by design: the palette is tuned for white surfaces, so
      // pinning the mode also stops the OS setting from washing it out.
      themeMode: ThemeMode.light,
      builder: (context, child) {
        // Keep the app's typography stable when the OS text scale is extreme.
        final scale = MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 0.85, maxScaleFactor: 1.35);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: DismissKeyboardOnTap(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

/// Closes the on-screen keyboard when the user taps anywhere that does not
/// itself handle the tap.
///
/// This sits above the [Navigator], so it applies to every screen at once
/// rather than each form remembering to do it.
///
/// It works because a tap resolves to exactly one winner in Flutter's gesture
/// arena, and the innermost recogniser wins: tapping a button, a list row or
/// another text field still goes to that widget, and this handler only fires
/// on taps nothing else claimed — empty space, padding, background.
class DismissKeyboardOnTap extends StatelessWidget {
  const DismissKeyboardOnTap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // `translucent` lets the tap reach this handler even where the child
      // paints nothing, which is exactly the empty space we care about.
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onTap: () {
        final focus = FocusManager.instance.primaryFocus;
        // Only act when something actually holds focus, so this never
        // interferes with ordinary taps on a screen with no open keyboard.
        if (focus != null && focus.hasFocus) focus.unfocus();
      },
      child: child,
    );
  }
}
