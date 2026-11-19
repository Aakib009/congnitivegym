import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/cognitive_analytics_model.dart';

/// Presentation-only BarChart widget displaying exercise completion distribution.
class ExerciseBreakdownBarChart extends StatelessWidget {
  final ExerciseCountBreakdown breakdown;

  const ExerciseBreakdownBarChart({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dataMap = [
      {'name': 'Story', 'count': breakdown.storyBuilder},
      {'name': 'Obs', 'count': breakdown.observationChallenge},
      {'name': 'Sequence', 'count': breakdown.sequenceMaster},
      {'name': 'Scenario', 'count': breakdown.scenarioLab},
      {'name': 'Debate', 'count': breakdown.debateArena},
    ];

    int maxIdx = 0;
    for (var i = 1; i < dataMap.length; i++) {
      if ((dataMap[i]['count'] as int) > (dataMap[maxIdx]['count'] as int)) {
        maxIdx = i;
      }
    }

    double maxVal = 5;
    for (final item in dataMap) {
      final cnt = (item['count'] as int).toDouble();
      if (cnt > maxVal) maxVal = cnt;
    }
    maxVal = (maxVal * 1.3).clamp(5.0, 500.0);

    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 12.0,
          left: 6.0,
          top: 16.0,
          bottom: 6.0,
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => colorScheme.surfaceContainerHigh,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final item = dataMap[groupIndex];
                  return BarTooltipItem(
                    '${item['name']}: ${rod.toY.toInt()} completions',
                    TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: maxVal / 4,
                  getTitlesWidget: (val, meta) => Text(
                    '${val.toInt()}',
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(140),
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    final idx = val.toInt();
                    if (idx >= 0 && idx < dataMap.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          dataMap[idx]['name'] as String,
                          style: TextStyle(
                            color: colorScheme.onSurface.withAlpha(180),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxVal / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: colorScheme.outline.withAlpha(50),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withAlpha(100)),
                left: BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
            ),
            barGroups: dataMap.asMap().entries.map((entry) {
              final idx = entry.key;
              final count = (entry.value['count'] as int).toDouble();
              final isHighlighted = idx == maxIdx;
              final color = isHighlighted
                  ? colorScheme.primary
                  : colorScheme.outline.withAlpha(120);

              return BarChartGroupData(
                x: idx,
                barRods: [
                  BarChartRodData(
                    toY: count,
                    color: color,
                    width: 22,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
