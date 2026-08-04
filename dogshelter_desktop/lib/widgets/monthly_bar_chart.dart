import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const monthlyBarChartGridColor = Color(0xFFE5E7EB);

double computeChartMaxY(num maxValue, {int minimum = 5}) {
  if (maxValue <= minimum) return minimum.toDouble();
  return ((maxValue / 5).ceil() * 5).toDouble();
}

/// Truncates a full Bosnian month name to its 3-letter abbreviation for chart axis labels.
String mjesecLabel(String naziv) => naziv.length > 3 ? naziv.substring(0, 3) : naziv;

/// Bar chart shared by every "count/amount per month" report visualization in this app
/// (Početna's dashboard, all 3 Izvještaji report cards) - one implementation, one look.
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({super.key, required this.labels, required this.values, required this.color});

  final List<String> labels;
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const SizedBox(height: 220, child: Center(child: Text('Nema podataka za odabrani period.')));
    }
    final maxValue = values.fold<double>(0, (max, v) => v > max ? v : max);
    final maxY = computeChartMaxY(maxValue);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => const FlLine(color: monthlyBarChartGridColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) =>
                    Text(value.toInt().toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(labels[index], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: 20,
                    color: color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
