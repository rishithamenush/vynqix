/// Axis arithmetic for the charts on the Analytics screen.
///
/// Both helpers exist because of the same class of defect: fl_chart draws
/// whatever labels it is asked for, however little room there is, and the
/// result is a smear of overlapping text rather than a dropped label.
abstract final class ChartAxis {
  /// How many bars to skip between date labels so at most [target] are drawn.
  ///
  /// A bar chart's horizontal axis ignores `SideTitles.interval` — fl_chart
  /// walks the bar groups and emits a title for every one of them — so the
  /// thinning has to happen in `getTitlesWidget`, using this.
  static int labelStep(int count, {int target = 5}) {
    if (count <= target) return 1;
    return (count / target).ceil();
  }

  /// Whether the bar at [index] of [count] should carry a date label.
  ///
  /// Counts back from the last bar rather than forward from the first, so the
  /// most recent day — the one the eye goes to — is always labelled, and the
  /// gaps stay even.
  static bool showsLabel(int index, int count, {int target = 5}) {
    if (index < 0 || index >= count) return false;
    return (count - 1 - index) % labelStep(count, target: target) == 0;
  }

  /// A vertical axis whose top gridline lands exactly on its maximum.
  ///
  /// fl_chart labels the interval steps *and* the axis maximum. Left to
  /// itself with a max of, say, 19 and a step of 9 it draws 18 and 19 a few
  /// pixels apart and they overlap into an unreadable blob. Rounding the
  /// maximum up to a whole number of steps makes the last step and the
  /// maximum the same number, so there is nothing to collide with.
  static ({double max, double interval}) verticalAxis(
    int rawMax, {
    int divisions = 3,
  }) {
    assert(divisions > 0, 'an axis needs at least one division');
    final safeMax = rawMax < 1 ? 1 : rawMax;
    final interval = (safeMax / divisions).ceil();
    return (max: (interval * divisions).toDouble(), interval: interval.toDouble());
  }
}
