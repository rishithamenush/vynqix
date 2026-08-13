import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/core/utils/chart_axis.dart';

void main() {
  group('showsLabel', () {
    test('thins a month down to a handful of labels', () {
      final shown = [for (var i = 0; i < 30; i++) if (ChartAxis.showsLabel(i, 30)) i];
      expect(shown.length, lessThanOrEqualTo(6));
      expect(shown, isNotEmpty);
    });

    test('always labels the most recent bar', () {
      for (final count in [1, 2, 7, 14, 30, 31]) {
        expect(
          ChartAxis.showsLabel(count - 1, count),
          isTrue,
          reason: 'the last bar of $count must carry a label',
        );
      }
    });

    test('spaces labels evenly', () {
      final shown = [for (var i = 0; i < 30; i++) if (ChartAxis.showsLabel(i, 30)) i];
      final gaps = [
        for (var i = 1; i < shown.length; i++) shown[i] - shown[i - 1],
      ];
      expect(gaps.toSet().length, 1, reason: 'gaps should all be equal: $shown');
    });

    test('labels every bar when they all fit', () {
      for (var i = 0; i < 5; i++) {
        expect(ChartAxis.showsLabel(i, 5), isTrue);
      }
    });

    test('rejects out-of-range indices', () {
      expect(ChartAxis.showsLabel(-1, 10), isFalse);
      expect(ChartAxis.showsLabel(10, 10), isFalse);
    });
  });

  group('verticalAxis', () {
    test('puts the top gridline exactly on the maximum', () {
      // The old code used `max + 1`, so fl_chart drew a label at the last
      // interval *and* at the maximum, one unit apart, and they overlapped.
      for (var raw = 1; raw <= 200; raw++) {
        final axis = ChartAxis.verticalAxis(raw);
        expect(
          axis.max % axis.interval,
          0,
          reason: 'max ${axis.max} is not a whole number of ${axis.interval}',
        );
        expect(axis.max, greaterThanOrEqualTo(raw.toDouble()));
      }
    });

    test('never returns a zero interval', () {
      for (final raw in [0, -5, 1]) {
        expect(ChartAxis.verticalAxis(raw).interval, greaterThan(0));
      }
    });

    test('keeps the axis close to the data', () {
      // Headroom is fine; a chart scaled to twice its tallest bar is not.
      for (var raw = 1; raw <= 200; raw++) {
        final axis = ChartAxis.verticalAxis(raw);
        expect(axis.max, lessThan(raw * 2 + 3));
      }
    });

    test('an 18-task month reads 0 / 6 / 12 / 18', () {
      final axis = ChartAxis.verticalAxis(18);
      expect(axis.max, 18);
      expect(axis.interval, 6);
    });
  });

  testWidgets('a 30-bar chart renders only the thinned date labels', (
    tester,
  ) async {
    // The whole defect was that fl_chart ignores `SideTitles.interval` on a
    // bar chart's horizontal axis and emits a title per group. This pumps a
    // real chart wired the way the Analytics screen wires one, and counts
    // what actually reaches the tree.
    const count = 30;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            width: 340,
            child: BarChart(
              BarChartData(
                maxY: 10,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (!ChartAxis.showsLabel(i, count)) {
                          return const SizedBox.shrink();
                        }
                        return Text('d$i');
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < count; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [BarChartRodData(toY: 5)],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labels = find.byWidgetPredicate(
      (w) => w is Text && w.data != null && w.data!.startsWith('d'),
    );
    expect(labels, findsNWidgets(5));
    expect(find.text('d29'), findsOneWidget, reason: 'newest day stays labelled');
  });
}
