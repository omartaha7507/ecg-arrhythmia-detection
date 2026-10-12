import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedECGLineChart extends StatefulWidget {
  const AnimatedECGLineChart({
    super.key,
    required this.flSpots,
    required this.positivePeak,
    required this.negativePeak,
    required this.animation,
    required this.totalDuration,
    this.windowDuration = 10.0,
  });

  final List<FlSpot> flSpots;
  final double positivePeak;
  final double negativePeak;
  final double windowDuration;
  final Animation<double> animation;
  final double totalDuration;

  @override
  State<AnimatedECGLineChart> createState() => _AnimatedECGLineChartState();
}

class _AnimatedECGLineChartState extends State<AnimatedECGLineChart> {
  List<FlSpot> _optimizedSpots = [];
  static const int _maxDataPoints = 500;
  final double yMargin = 0.5;

  @override
  void initState() {
    super.initState();
    _optimizeDataPoints();
  }

  void _optimizeDataPoints() {
    if (widget.flSpots.length <= _maxDataPoints) {
      _optimizedSpots = List.from(widget.flSpots);
      return;
    }

    // Downsample the data while preserving important peaks
    _optimizedSpots = [];
    double step = widget.flSpots.length / _maxDataPoints;

    for (int i = 0; i < _maxDataPoints; i++) {
      int index = (i * step).round();
      if (index < widget.flSpots.length) {
        _optimizedSpots.add(widget.flSpots[index]);
      }
    }
  }

  List<FlSpot> _getVisibleSpots(double currentTime) {
    if (_optimizedSpots.isEmpty) return [];

    double startTime = currentTime;
    double endTime = startTime + widget.windowDuration;

    List<FlSpot> visibleSpots = [];

    // Use binary search-like approach for better performance
    int startIndex = _findNearestIndex(startTime);
    int endIndex = _findNearestIndex(endTime);

    // Add spots within the current window
    for (int i = startIndex; i <= endIndex && i < _optimizedSpots.length; i++) {
      FlSpot spot = _optimizedSpots[i];
      if (spot.x >= startTime && spot.x <= endTime) {
        visibleSpots.add(FlSpot(spot.x - startTime, spot.y));
      }
    }

    // Handle wrap-around when we reach the end
    if (endTime > widget.totalDuration) {
      double overflowTime = endTime - widget.totalDuration;
      int overflowEndIndex = _findNearestIndex(overflowTime);

      for (
        int i = 0;
        i <= overflowEndIndex && i < _optimizedSpots.length;
        i++
      ) {
        FlSpot spot = _optimizedSpots[i];
        if (spot.x <= overflowTime) {
          visibleSpots.add(
            FlSpot(spot.x + (widget.totalDuration - startTime), spot.y),
          );
        }
      }
    }

    return visibleSpots;
  }

  int _findNearestIndex(double time) {
    if (_optimizedSpots.isEmpty) return 0;

    int left = 0;
    int right = _optimizedSpots.length - 1;

    while (left <= right) {
      int mid = (left + right) ~/ 2;
      if (_optimizedSpots[mid].x < time) {
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }

    return math.max(0, math.min(left, _optimizedSpots.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade800, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedBuilder(
          animation: widget.animation,
          builder: (context, child) {
            List<FlSpot> visibleSpots = _getVisibleSpots(
              widget.animation.value,
            );

            return LineChart(
              LineChartData(
                maxY: widget.positivePeak + yMargin,
                minY: widget.negativePeak - yMargin,
                maxX: widget.windowDuration,
                minX: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: visibleSpots,
                    isCurved: false,
                    color: Colors.green,
                    barWidth: 2.0,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.1),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (widget.positivePeak + 0.1) / 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontFamily: 'monospace',
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: widget.windowDuration / 5,
                      getTitlesWidget: (value, meta) {
                        double actualTime = widget.animation.value;
                        if (actualTime >= widget.totalDuration) {
                          actualTime = actualTime % widget.totalDuration;
                        }
                        return Text(
                          '${actualTime.toStringAsFixed(1)}s',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontFamily: 'monospace',
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  verticalInterval: widget.windowDuration / 10,
                  horizontalInterval: (widget.positivePeak + 0.1) / 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.green.withOpacity(0.3),
                      strokeWidth: 0.5,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.green.withOpacity(0.3),
                      strokeWidth: 0.5,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.green.shade800, width: 1),
                ),
              ),
              duration: const Duration(milliseconds: 16),
              curve: Curves.linear,
            );
          },
        ),
      ),
    );
  }
}
