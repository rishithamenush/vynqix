// Temporary: renders the completion chart before/after the axis fix so the
// change can be eyeballed. Run with --update-goldens, then delete.
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/core/theme/app_theme.dart';
import 'package:vynqix/core/utils/chart_axis.dart';

const _counts = [
  6, 11, 3, 9, 14, 2, 7, 12, 5, 10, 16, 4, 8, 13, 6, 9, 3, 11, 15, 7,
  2, 10, 5, 12, 8, 14, 4, 9, 18, 11,
];

Future<void> _loadInter() async {
  for (final name in ['Inter-Regular', 'Inter-Medium', 'Inter-SemiBold']) {
    final bytes = await File('assets/fonts/$name.ttf').readAsBytes();
    final loader = FontLoader('Inter')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

Widget _chart({required bool fixed}) {
  final max = _counts.reduce((a, b) => a > b ? a : b);
  final axis = ChartAxis.verticalAxis(max);
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 200,
            width: 320,
            child: BarChart(
              BarChartData(
                maxY: fixed ? axis.max : max + 1,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: fixed
                          ? axis.interval
                          : (max / 2).ceilToDouble(),
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(fontSize: 11, fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: fixed ? null : (_counts.length / 6).ceilToDouble(),
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (fixed && !ChartAxis.showsLabel(i, _counts.length)) {
                          return const SizedBox.shrink();
                        }
                        final day = DateTime(2026, 7, 15).add(Duration(days: i));
                        final label =
                            '${day.day} ${const [
                          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
                        ][day.month - 1]}';
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            label,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: fixed ? 10 : 9,
                              fontFamily: 'Inter',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < _counts.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: _counts[i].toDouble() * 0.78,
                          width: 6,
                          borderRadius: BorderRadius.circular(3),
                          color: const Color(0xFF047857),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: _counts[i].toDouble(),
                            color: const Color(0xFFEDF3F0),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('before', (tester) async {
    await _loadInter();
    await tester.pumpWidget(_chart(fixed: false));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BarChart),
      matchesGoldenFile('chart_before.png'),
    );
  });

  testWidgets('after', (tester) async {
    await _loadInter();
    await tester.pumpWidget(_chart(fixed: true));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BarChart),
      matchesGoldenFile('chart_after.png'),
    );
  });
}
