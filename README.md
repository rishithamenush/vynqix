# Vynqix

**Plan tomorrow. Master today.**

A local-first daily task scheduler built with Flutter. Everything lives on the
device — no account, no backend, no network calls.

Clean Material 3, light theme only, Inter for type and Phosphor for icons —
both bundled, so nothing is fetched at runtime.

Ported from the `daily-task-scheduler` Expo prototype: the colour system,
typography scale, screen list and product concepts come from that project's
`design.md`; the data model, architecture and implementation are new.

---

## Running it

```bash
flutter pub get
```

```bash
flutter run
```

```bash
flutter test
```

```bash
flutter analyze
```

---

## Architecture

Three layers, with dependencies pointing inwards only. `domain` has no Flutter
imports at all, which is what makes the business rules unit-testable without a
widget tree or a database.

```
lib/
├── main.dart              Opens the database, runs startup tasks, boots the app
├── app/                   MaterialApp, GoRouter, bottom-tab shell
├── core/                  Design tokens, date/duration utilities, extensions
├── domain/                Entities, enums, repository contracts, pure services
├── data/                  SQLite schema, row mappers, repository implementations
└── presentation/          Riverpod providers, shared widgets, feature screens
```

### domain

Pure Dart. Entities are immutable with `copyWith`; enums carry their own ids and
labels so persistence and display never drift.

Services are stateless and take their inputs as arguments:

| Service | Responsibility |
| --- | --- |
| `StatsService` | Aggregates tasks/sessions/logs into `DayStats` and `RangeStats` |
| `StreakService` | Current and longest streak, with a grace period for today |
| `ScheduleService` | Day ordering, overlap detection, free-slot finding |
| `RecurrenceService` | Expands a repeating task into concrete occurrences |
| `AchievementService` | Evaluates the badge catalogue against live metrics |
| `InsightsService` | Rule-based, offline "AI insights" text |
| `NudgeService` | Builds the reminders screen from the current plan |

`RewardsUseCase` is the one place that grants XP and unlocks achievements, so
task completion, focus sessions and daily reviews all award consistently.

### data

`sqflite` with a hand-written schema — no code generation, so `flutter pub get`
is the only build step.

| Table | Holds |
| --- | --- |
| `tasks` | One row per task occurrence, indexed on `dayKey`, `status`, `seriesId` |
| `day_logs` | One reflection per day, keyed by `dayKey` |
| `focus_sessions` | Every Pomodoro block, completed or abandoned |
| `achievements` | Unlock timestamps only; the catalogue lives in code |
| `key_value` | JSON documents for the profile and settings singletons |

Two conventions worth knowing:

- **Days are `yyyy-MM-dd` strings.** Grouping by a day key rather than a
  timestamp makes day-bucketing immune to timezone drift and turns every date
  query into a string comparison.
- **Times are minutes since midnight.** A task can move between days without
  re-deriving a wall-clock time.

Repositories expose a `changes` stream that fires after every write. Riverpod
providers subscribe to it and re-query, which gives a reactive UI on top of a
non-reactive database without pulling in a heavier persistence layer.

### presentation

Riverpod 2 without code generation. Query providers are `FutureProvider`s;
mutations go through controllers (`TaskController`, `ReviewController`,
`FocusController`) that own the side effects.

### Design system

| Decision | Rationale |
| --- | --- |
| **Focus Blue accent** | `#2563EB`. Task apps converge on blue because it reads calm and focused; indigo/violet reads as a creative or AI tool. Category hues were re-spaced so none sits near it — a category dot is never mistaken for a UI accent. |
| **Light theme only** | One theme means every colour is chosen for contrast against white instead of compromised to work on two backgrounds. `success`, `warning` and `error` are deeper than the usual Tailwind shades, which fail contrast as text on white. |
| **Inter, bundled** | Drawn for UI at small sizes: open counters and distinct `1/l/I` keep a dense task list readable. Bundled as TTF (SIL OFL) rather than fetched, so the app renders identically offline. |
| **Phosphor icons, no emoji** | Emoji render differently on every platform and OS version, cannot inherit colour or weight, and read as decoration. Every glyph is an icon that takes the palette. |
| **Stable icon keys** | Anything persisted stores a string key (`tasks.iconKey`, `profile.avatarIconKey`), never an `IconData` — the domain stays framework-free and the icon set can be swapped with no migration. |
| **Flat surfaces** | No gradients, blur or glow. Colour carries meaning only: the category dot, the priority flag, the progress bar. |

### Responsive layout

Breakpoints follow Material 3's window size classes, on **width only** — height
varies too much (keyboards, notches, split-screen) to drive layout.

| Width | Class | Layout |
| --- | --- | --- |
| `< 600dp` | compact | Bottom `NavigationBar`, full-bleed content |
| `600–839dp` | medium | Side `NavigationRail` (icons), content starts centring |
| `>= 840dp` | expanded | Extended rail with labels, 3–4 column stat grids |

Two helpers carry most of it, both in `core/utils/responsive.dart` and
`presentation/widgets/page_body.dart`:

- `context.responsive(compact:, medium:, expanded:)` picks a value for the
  current class and falls back down the scale.
- `PageBody` / `SliverPageBody` centre content and cap it at 640dp for prose
  and forms, 760dp for lists. Without this, a task row stretches to 1200dp on
  a tablet, which is the single thing that makes a phone layout look broken on
  a big screen.

Rotation is unlocked. Screens that used fixed `Spacer` layouts (Welcome) now
scroll rather than overflow when the window is short, and the focus ring scales
to the viewport instead of a fixed 264dp.

---

## Features

**Onboarding** — profile, avatar, goal, and the wake/sleep/work rhythm the
planner schedules around.

**Home** — "Today" list with a date/progress header and streak, tasks split
into outstanding and completed, swipe to complete or delete, long-press for
quick actions.

**Planner** — any day on a horizontal strip, timeline with overlap warnings,
drag-to-reorder backlog, a capacity meter against your waking hours,
auto-schedule into free slots, and copy-today-into-tomorrow.

**Task editor** — icon, category, priority, date, start time, duration,
repeat rule, reminder lead time, checklist, tags and notes.

**Focus** — Pomodoro timer bound to a task, auto-starting breaks, a long break
every fourth block, and a persisted session log.

**Daily review** — mood, energy, 1–5 rating and four reflection prompts, shown
alongside the day's real numbers.

**Analytics** — 7/30/90-day windows: completion bars, completions by hour,
category donut, and a mood trend from your reviews.

**Insights** — plain-language observations computed on-device: peak hours,
over-booking, category concentration, mood/completion correlation.

**Calendar** — month grid with task dots and a day agenda.

**History** — past days with reviews, plus full-text search across every task.

**Reminders** — nudges derived live from the current plan (overdue tasks, empty
tomorrow, unwritten review, streak at risk).

**Profile & achievements** — XP, levels, lifetime stats, 15-badge catalogue.

**Settings** — 24-hour clock, completed-task visibility, focus defaults,
reminder times, rollover behaviour, waking hours, daily goal, and a full data
reset.

---

## Usability behaviour worth knowing

These are deliberate, and the reasoning is in the code where each lives:

- **Tapping anywhere off a field closes the keyboard** (`DismissKeyboardOnTap`
  in `app/app.dart`), and dragging a form scrolls it away. It sits above the
  `Navigator`, so it applies to every screen at once.
- **Closing the task editor with unsaved edits asks first**, including via the
  system back gesture.
- **Swipe-to-delete deletes immediately and offers Undo** rather than
  interrupting with a dialog — swiping is easy to do by accident, and an undo
  is cheaper than a confirm on every delete.
- **Deleting a repeating task asks** whether it means this occurrence or all
  future ones. Guessing either way loses data.
- **Search is debounced** by 300 ms so a query runs when you pause, not on
  every keystroke.
- **Touch targets are 44dp**, including the task checkbox, whose visible
  circle is only 22dp.
- **The Calendar opens on today** even though the Planner defaults the shared
  day selection to tomorrow.

## Known limitations

- **No OS notifications.** The reminders screen is computed in-app and is always
  accurate, but nothing fires while the app is closed. Adding
  `flutter_local_notifications` would need platform permission setup on both
  iOS and Android.
- **Premium is a local flag.** No billing SDK is wired up; the toggle exists so
  the premium surfaces can be built and demoed.
- **Web is not wired up.** `sqflite` covers iOS, Android, macOS, Windows and
  Linux. Web would need a second `TaskRepository` implementation — the
  repository interfaces are already the seam for it.
- **No dark theme.** Removed on purpose (see the design table). Re-adding it
  means restoring a second `AppColors` set and re-checking every deepened
  semantic colour.
