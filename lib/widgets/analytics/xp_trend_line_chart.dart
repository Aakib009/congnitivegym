import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/cognitive_analytics_model.dart';

/// Presentation-only LineChart widget displaying XP progress over time.
class XpTrendLineChart extends StatelessWidget {
  final List<XpTrendPoint> xpTrend;

  const XpTrendLineChart({
    super.key,
    required this.xpTrend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (xpTrend.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No XP trend data available.')),
      );
    }

    final spots = xpTrend.asMap().entries.map((entry) {
      final idx = entry.key.toDouble();
      final val = entry.value.xpEarned.toDouble();
      return FlSpot(idx, val);
    }).toList();

    double maxY = 50;
    for (final pt in xpTrend) {
      if (pt.xpEarned > maxY) maxY = pt.xpEarned.toDouble();
    }
    maxY = (maxY * 1.25).clamp(50.0, 1000.0);

    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.only(right: 18.0, left: 6.0, top: 12.0, bottom: 6.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: colorScheme.outline.withAlpha(50),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: maxY / 4,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(140),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: (xpTrend.length / 5).clamp(1.0, 10.0),
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < xpTrend.length) {
                      final dt = xpTrend[idx].date;
                      final label = '${dt.month}/${dt.day}';
                      return Text(
                        label,
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(140),
                          fontSize: 10,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withAlpha(100)),
                left: BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
            ),
            minX: 0,
            maxX: (xpTrend.length - 1).toDouble(),
            minY: 0,
            maxY: maxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => colorScheme.surfaceContainerHigh,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final idx = spot.spotIndex;
                    final pt = xpTrend[idx];
                    final dateStr = '${pt.date.year}-${pt.date.month.toString().padLeft(2, '0')}-${pt.date.day.toString().padLeft(2, '0')}';
                    return LineTooltipItem(
                      '$dateStr\n+${pt.xpEarned} XP',
                      TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 3,
                color: colorScheme.primary,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: xpTrend.length <= 10,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 4,
                    color: colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: colorScheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withAlpha(80),
                      colorScheme.primary.withAlpha(0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
