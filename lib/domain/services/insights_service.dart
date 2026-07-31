import '../../core/utils/date_x.dart';
import '../entities/stats.dart';
import '../entities/user_profile.dart';

/// Turns aggregated statistics into plain-language observations.
///
/// This is the "AI Insights" screen's engine. It is intentionally rule-based
/// and offline — no network call, no model — so insights are instant,
/// private and deterministic.
abstract final class InsightsService {
  static List<Insight> generate({
    required RangeStats stats,
    required StreakInfo streak,
    required UserProfile profile,
  }) {
    final insights = <Insight>[];

    if (stats.totalTasks == 0) {
      return const [
        Insight(
          id: 'empty',
          title: 'Nothing to analyse yet',
          body:
              'Plan a few tasks and finish them. Once there is a week of '
              'history here, patterns in your focus, timing and energy start '
              'showing up on this screen.',
          iconKey: 'seedling',
        ),
      ];
    }

    // Completion rate.
    final rate = (stats.completionRate * 100).round();
    if (rate >= 80) {
      insights.add(
        Insight(
          id: 'rate_high',
          title: 'You finish what you plan',
          body:
              'You completed $rate% of your scheduled tasks. That is a '
              'realistic plan meeting real follow-through — the hardest '
              'combination to get right.',
          iconKey: 'target',
          tone: InsightTone.positive,
        ),
      );
    } else if (rate < 50) {
      insights.add(
        Insight(
          id: 'rate_low',
          title: 'Your days are over-booked',
          body:
              'Only $rate% of planned tasks got done. You are not failing to '
              'execute — you are planning more than a day holds. Try cutting '
              'tomorrow’s list to your top three.',
          iconKey: 'balance',
          tone: InsightTone.warning,
        ),
      );
    } else {
      insights.add(
        Insight(
          id: 'rate_mid',
          title: 'Steady progress',
          body:
              'You completed $rate% of your planned tasks. Trimming one or '
              'two low-priority items per day would push this over 70%.',
          iconKey: 'trendUp',
        ),
      );
    }

    // Peak hour.
    final peak = stats.peakHour;
    if (peak != null) {
      insights.add(
        Insight(
          id: 'peak_hour',
          title: 'Your peak window is ${TimeOfDayX.format(peak * 60)}',
          body:
              'More of your tasks get completed around this hour than any '
              'other. Protect it — schedule your hardest task here instead of '
              'meetings or admin.',
          iconKey: 'clock',
          tone: InsightTone.positive,
        ),
      );
    }

    // Category concentration.
    final top = stats.topCategory;
    if (top != null) {
      final count = stats.byCategory[top] ?? 0;
      final share = stats.totalCompleted == 0
          ? 0
          : ((count / stats.totalCompleted) * 100).round();
      insights.add(
        Insight(
          id: 'top_category',
          title: '${top.label} dominates your time',
          body:
              '$share% of everything you completed was ${top.label.toLowerCase()}. '
              '${share > 60 ? 'That is a lot of weight in one area — check that the others are not quietly slipping.' : 'That looks like a healthy balance across your life areas.'}',
          iconKey: 'compass',
          tone: share > 60 ? InsightTone.warning : InsightTone.neutral,
        ),
      );
    }

    // Focus time.
    if (stats.totalFocusMinutes > 0) {
      final avg = stats.avgFocusMinutesPerActiveDay.round();
      insights.add(
        Insight(
          id: 'focus',
          title: '${DurationX.formatMinutes(stats.totalFocusMinutes)} of deep focus',
          body:
              'That averages ${DurationX.formatMinutes(avg)} on the days you '
              'were active. Focus sessions correlate with the days you clear '
              'your whole list.',
          iconKey: 'focus',
          tone: InsightTone.positive,
        ),
      );
    } else {
      insights.add(
        const Insight(
          id: 'focus_none',
          title: 'You have not used Focus mode',
          body:
              'Tasks worked on inside a timed focus block get finished far '
              'more often than ones left open-ended. Try a single 25-minute '
              'block tomorrow.',
          iconKey: 'timer',
        ),
      );
    }

    // Streak.
    if (streak.current >= 3) {
      insights.add(
        Insight(
          id: 'streak',
          title: '${streak.current}-day streak',
          body:
              'Your longest run is ${streak.longest} days. Consistency, not '
              'volume, is what moves the completion rate over time.',
          iconKey: 'fire',
          tone: InsightTone.positive,
        ),
      );
    } else if (stats.activeDays >= 3) {
      insights.add(
        const Insight(
          id: 'streak_broken',
          title: 'Your rhythm is patchy',
          body:
              'You have active days scattered rather than consecutive. One '
              'small task a day beats an intense day followed by three empty '
              'ones.',
          iconKey: 'wave',
          tone: InsightTone.warning,
        ),
      );
    }

    // Mood correlation.
    if (stats.moodScores.length >= 3) {
      final good = <double>[];
      final bad = <double>[];
      for (final day in stats.days) {
        final mood = stats.moodScores[day.dayKey];
        if (mood == null || day.total == 0) continue;
        (mood >= 4 ? good : bad).add(day.completionRate);
      }
      if (good.isNotEmpty && bad.isNotEmpty) {
        final goodAvg = good.reduce((a, b) => a + b) / good.length;
        final badAvg = bad.reduce((a, b) => a + b) / bad.length;
        final delta = ((goodAvg - badAvg) * 100).round();
        if (delta.abs() >= 10) {
          insights.add(
            Insight(
              id: 'mood',
              title: delta > 0
                  ? 'Good moods track with finished days'
                  : 'You get more done on flat days',
              body: delta > 0
                  ? 'On days you rated your mood highly you completed $delta '
                        'percentage points more of your list. Guarding sleep '
                        'and breaks is productivity work, not a break from it.'
                  : 'Interestingly, your completion rate is ${delta.abs()} '
                        'points higher on lower-mood days — you may be using '
                        'work to push through. Watch for burnout.',
              iconKey: delta > 0 ? 'sun' : 'rain',
              tone: delta > 0 ? InsightTone.positive : InsightTone.warning,
            ),
          );
        }
      }
    }

    // Perfect days.
    if (stats.perfectDays > 0) {
      insights.add(
        Insight(
          id: 'perfect',
          title: '${stats.perfectDays} perfect ${stats.perfectDays == 1 ? 'day' : 'days'}',
          body:
              'Days where every planned task got done. Look at what those '
              'days had in common — usually a shorter list and an earlier '
              'start.',
          iconKey: 'sparkle',
          tone: InsightTone.positive,
        ),
      );
    }

    // Lifestyle fit.
    final avgPlanned = stats.activeDays == 0
        ? 0
        : stats.days.fold(0, (s, d) => s + d.plannedMinutes) / stats.activeDays;
    if (avgPlanned > profile.wakingMinutes * 0.6) {
      insights.add(
        Insight(
          id: 'capacity',
          title: 'You are scheduling more than fits',
          body:
              'You plan around ${DurationX.formatMinutes(avgPlanned.round())} '
              'of work per active day against roughly '
              '${DurationX.formatMinutes(profile.wakingMinutes)} awake. Leave '
              'room for the things a calendar never shows.',
          iconKey: 'capacity',
          tone: InsightTone.warning,
        ),
      );
    }

    return insights;
  }
}
