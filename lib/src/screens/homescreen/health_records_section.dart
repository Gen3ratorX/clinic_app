import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthRecordsSection extends StatelessWidget {
  final String selectedMetric;
  final void Function(String metric) onMetricChange;
  final Color primaryColor;
  final Color bgColor;
  final Map<String, List<FlSpot>> metricData;

  const HealthRecordsSection({
    super.key,
    required this.selectedMetric,
    required this.onMetricChange,
    required this.primaryColor,
    required this.bgColor,
    required this.metricData,
  });

  @override
  Widget build(BuildContext context) {
    final recentValue = selectedMetric == 'Blood Pressure'
        ? '120/80 mmHg'
        : selectedMetric == 'Heart Rate'
        ? '70 bpm'
        : '70 kg';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Records',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Metrics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: primaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedMetric,
                          items: ['Blood Pressure', 'Heart Rate', 'Weight']
                              .map((metric) => DropdownMenuItem(
                            value: metric,
                            child: Text(metric, style: const TextStyle(fontSize: 14)),
                          ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              HapticFeedback.lightImpact();
                              onMetricChange(value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedMetric,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recentValue,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trend', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        SizedBox(height: 4),
                        Text('Stable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: metricData[selectedMetric]!,
                          isCurved: true,
                          color: primaryColor,
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: primaryColor.withOpacity(0.2),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${spot.y}',
                                const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Insight: Your $selectedMetric is stable this week.',
                    style: TextStyle(fontSize: 14, color: primaryColor),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // navigation placeholder
                    },
                    child: Text('View All', style: TextStyle(color: primaryColor)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

