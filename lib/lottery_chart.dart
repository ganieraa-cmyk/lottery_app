import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dashboard_screen.dart'; // To access LotteryData

class LotterySpreadChart extends StatelessWidget {
  final List<LotteryData> data;

  const LotterySpreadChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Only process valid data (filter out empty rows or parse errors)
    final validData = <_ChartData>[];
    for (int i = 0; i < data.length; i++) {
      try {
        final mc = double.parse(data[i].dear1pmMC.replaceAll(RegExp(r'[^0-9.]'), ''));
        final result = double.parse(data[i].dear1pmResult.replaceAll(RegExp(r'[^0-9.]'), ''));
        final spread = (mc - result).abs();
        validData.add(_ChartData(index: i, date: data[i].date, spread: spread));
      } catch (e) {
        // Skip rows that don't have valid numeric data
        continue;
      }
    }

    if (validData.isEmpty) {
      return const Center(child: Text("No valid numeric data for chart"));
    }

    // Determine Y-axis boundaries
    double maxSpread = 0;
    for (var item in validData) {
      if (item.spread > maxSpread) maxSpread = item.spread;
    }
    // Add 10% padding to the top of the chart
    final maxY = maxSpread * 1.1;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        padding: const EdgeInsets.only(right: 22, left: 12, top: 24, bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: maxY > 0 ? (maxY / 5) : 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
              },
              getDrawingVerticalLine: (value) {
                return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= validData.length) return const SizedBox.shrink();
                    
                    // Show every 3rd date to avoid crowding the X-axis
                    if (index % 3 != 0 && index != validData.length - 1 && index != 0) {
                      return const SizedBox.shrink();
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        validData[index].date.replaceAll('.0', ''),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  getTitlesWidget: (value, meta) {
                    // Format large numbers (e.g. 10000 -> 10k)
                    String text = '';
                    if (value >= 1000) {
                      text = '${(value / 1000).toStringAsFixed(0)}k';
                    } else {
                      text = value.toStringAsFixed(0);
                    }
                    return Text(
                      text,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                      textAlign: TextAlign.right,
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            minX: 0,
            maxX: validData.length.toDouble() - 1,
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: validData.map((e) => FlSpot(e.index.toDouble(), e.spread)).toList(),
                isCurved: true,
                color: Colors.deepPurple,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.amber,
                      strokeWidth: 2,
                      strokeColor: Colors.deepPurple,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.deepPurple.withOpacity(0.15),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Colors.deepPurpleAccent,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final dataItem = validData[spot.spotIndex.toInt()];
                    return LineTooltipItem(
                      'Date: ${dataItem.date}\nSpread: ${spot.y.toStringAsFixed(0)}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartData {
  final int index;
  final String date;
  final double spread;

  _ChartData({required this.index, required this.date, required this.spread});
}
