import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/cognitive_analytics_model.dart';

/// Presentation-only RadarChart widget using fl_chart to display cognitive skill balance.
class SkillRadarChart extends StatefulWidget {
  final SkillMetrics skillMetrics;

  const SkillRadarChart({
    super.key,
    required this.skillMetrics,
  });

  @override
  State<SkillRadarChart> createState() => _SkillRadarChartState();
}

class _SkillRadarChartState extends State<SkillRadarChart> {
  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final metrics = [
      widget.skillMetrics.criticalThinking,
      widget.skillMetrics.memory,
      widget.skillMetrics.observation,
      widget.skillMetrics.creativity,
      widget.skillMetrics.decisionMaking,
    ];

    final titles = [
      'Critical Thinking',
      'Memory',
      'Observation',
      'Creativity',
      'Decision Making',
    ];

    return AspectRatio(
      aspectRatio: 1.3,
      child: RadarChart(
        RadarChartData(
          radarTouchData: RadarTouchData(
            touchCallback: (FlTouchEvent event, response) {
              if (response != null && response.touchedSpot != null) {
                setState(() {
                  selectedIndex = response.touchedSpot!.touchedRadarEntryIndex;
                });
              } else {
                setState(() {
                  selectedIndex = -1;
                });
              }
            },
          ),
          dataSets: [
            RadarDataSet(
              fillColor: colorScheme.primary.withAlpha(50),
              borderColor: colorScheme.primary,
              entryRadius: 4,
              borderWidth: 2.5,
              dataEntries: metrics
                  .map((val) => RadarEntry(value: val.clamp(5.0, 100.0)))
                  .toList(),
            ),
          ],
          radarShape: RadarShape.polygon,
          radarBorderData: BorderSide(
            color: colorScheme.outline.withAlpha(100),
            width: 1,
          ),
          gridBorderData: BorderSide(
            color: colorScheme.outline.withAlpha(60),
            width: 1,
          ),
          tickBorderData: BorderSide(
            color: colorScheme.outline.withAlpha(40),
            width: 1,
          ),
          ticksTextStyle: TextStyle(
            color: colorScheme.onSurface.withAlpha(100),
            fontSize: 10,
          ),
          getTitle: (index, angle) {
            return RadarChartTitle(
              text: titles[index],
              positionPercentageOffset: 0.15,
            );
          },
          tickCount: 4,
        ),
      ),
    );
  }
}
