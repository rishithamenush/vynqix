# Vynqix

**Plan tomorrow. Master today.**

A local-first daily task scheduler built with Flutter. Everything lives on the
device — no account, no backend, no network calls.

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

---

## Features

**Onboarding** — profile, avatar, goal, and the wake/sleep/work rhythm the
planner schedules around.

**Home** — today's completion ring, streak and level, "right now" and "up next",
swipe to complete or delete, long-press for quick actions.

**Planner** — any day on a horizontal strip, timeline with overlap warnings,
drag-to-reorder backlog, a capacity meter against your waking hours,
auto-schedule into free slots, and copy-today-into-tomorrow.

**Task editor** — emoji, category, priority, date, start time, duration,
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

**Settings** — theme, 24-hour clock, focus defaults, reminder times, rollover
behaviour, daily goal, and a full data reset.

---

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
