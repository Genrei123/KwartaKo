import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../features/dashboard/dashboard_service.dart';

class SavingsTrendChart extends StatelessWidget {
  final List<MonthlyMetrics> metrics;

  const SavingsTrendChart({Key? key, required this.metrics}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generate spots for the line chart
    final List<FlSpot> spots = [];
    for (int i = 0; i < metrics.length; i++) {
      // Clamp savings rate between -0.5 and 1.0 for better scaling in the UI
      final rate = metrics[i].savingsRate.clamp(-0.5, 1.0);
      spots.add(FlSpot(i.toDouble(), rate));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAVINGS RATE TREND',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 28),
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
                minY: -0.2, // Show a bit of negative range if they overspent
                maxY: 0.6,  // Show up to 60% savings rate
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E2D4A),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    tooltipMargin: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                        final monthMetrics = metrics[touchedSpot.x.toInt()];
                        final ratePercent = (monthMetrics.savingsRate * 100).toStringAsFixed(1);
                        return LineTooltipItem(
                          '${monthMetrics.monthName} Rate\n',
                          const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text: '$ratePercent%',
                              style: TextStyle(
                                color: monthMetrics.savingsRate >= 0.20
                                    ? Colors.green.shade400
                                    : (monthMetrics.savingsRate >= 0 ? Colors.teal.shade300 : Colors.red.shade400),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < metrics.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              metrics[index].monthName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        final percent = (value * 100).toInt();
                        if (percent % 20 != 0) return const SizedBox.shrink();
                        return Text(
                          '$percent%',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.04),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.teal.shade300,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFF0F1B2D),
                        strokeColor: Colors.teal.shade300,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.teal.shade300.withOpacity(0.2),
                          Colors.teal.shade300.withOpacity(0.0),
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
        ],
      ),
    );
  }
}
