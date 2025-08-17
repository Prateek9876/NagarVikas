import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartWidget extends StatelessWidget {
  final int resolved;
  final int pending;
  final int rejected; // Keep the parameter name as 'rejected' for backward compatibility

  const PieChartWidget({
    super.key,
    required this.resolved,
    required this.pending,
    required this.rejected, // This will actually contain inProgress data
  });

  @override
  Widget build(BuildContext context) {
    final total = resolved + pending + rejected;

    // Handle case where total is 0 to avoid division by zero
    if (total == 0) {
      return AspectRatio( // Aspect Ratio
        aspectRatio: 1.3,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12), //Border Radius
            color: Colors.grey.shade100,
          ),
          child: const Center(
            child: Text(
              'No complaints data available',
              style: TextStyle( // Text Style
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    final sections = [
      PieChartSectionData(
        value: resolved.toDouble(),
        color: Colors.green,
        title: resolved > 0 ? 'Resolved\n${((resolved / total) * 100).toStringAsFixed(1)}%' : '',
        radius: 65,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      PieChartSectionData(
        value: pending.toDouble(),
        color: Colors.orange,
        title: pending > 0 ? 'Pending\n${((pending / total) * 100).toStringAsFixed(1)}%' : '',
        radius: 65,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      PieChartSectionData(
        value: rejected.toDouble(), // This is actually inProgress data
        color: Colors.blue, // Changed from red to blue for "In Progress"
        title: rejected > 0 ? 'In Progress\n${((rejected / total) * 100).toStringAsFixed(1)}%' : '', // Changed title from "Rejected" to "In Progress"
        radius: 65,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    ];

    return AspectRatio( // Aspect Ratio
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
