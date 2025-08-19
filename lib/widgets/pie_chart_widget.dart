import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartWidget extends StatelessWidget {
  final int resolved;
  final int pending;
  final int rejected;

  const PieChartWidget({
    super.key,
    required this.resolved,
    required this.pending,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    final total = resolved + pending + rejected;
    final sections = [
      PieChartSectionData(
        value: resolved.toDouble(),
        color: Colors.greenAccent,
        title: resolved > 0
            ? 'Resolved\n${((resolved / total) * 100).toStringAsFixed(1)}%'
            : '',
        radius: 65,
        titleStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      PieChartSectionData(
        value: pending.toDouble(),
        color: Colors.orangeAccent,
        title: pending > 0
            ? 'Pending\n${((pending / total) * 100).toStringAsFixed(1)}%'
            : '',
        radius: 65,
        titleStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      PieChartSectionData(
        value: rejected.toDouble(),
        color: Colors.redAccent,
        title: rejected > 0
            ? 'Rejected\n${((rejected / total) * 100).toStringAsFixed(1)}%'
            : '',
        radius: 65,
        titleStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    ];

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
