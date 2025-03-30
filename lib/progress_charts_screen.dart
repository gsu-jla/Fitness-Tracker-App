import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database/database_helper.dart';
import 'dart:math' as math;

// Screen for visualizing progress with charts
class ProgressChartsScreen extends StatefulWidget {
  @override
  _ProgressChartsScreenState createState() => _ProgressChartsScreenState();
}

class _ProgressChartsScreenState extends State<ProgressChartsScreen> {
  List<Map<String, dynamic>> _workoutHistory = [];
  List<Map<String, dynamic>> _weightHistory = [];
  bool _isLoading = true;
  String _weightUnit = 'lbs'; // Default to pounds

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final workoutHistory = await DatabaseHelper.instance.getWorkoutHistory();
      final weightHistory = await DatabaseHelper.instance.getWeightHistory();
      final unit = await DatabaseHelper.instance.getWeightUnit();
      
      setState(() {
        _workoutHistory = workoutHistory;
        _weightHistory = weightHistory;
        _weightUnit = unit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Progress Charts'),
          backgroundColor: Colors.purple,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Progress Charts'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weight Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildWeightChart(),
            
            SizedBox(height: 24),
            Text(
              'Calories Burned',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildCaloriesBurnedChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    if (_weightHistory.isEmpty) {
      return Center(child: Text('No weight data available'));
    }

    final sortedWeights = List<Map<String, dynamic>>.from(_weightHistory);
    sortedWeights.sort((a, b) {
      final dateA = DateTime.parse(a['date'] as String);
      final dateB = DateTime.parse(b['date'] as String);
      return dateA.compareTo(dateB);
    });

    final spots = sortedWeights.map((weight) {
      final date = DateTime.parse(weight['date'] as String);
      final weightValue = (weight['weight'] as num).toDouble();
      final displayWeight = _weightUnit == 'lbs' ? weightValue * 2.20462 : weightValue;
      return FlSpot(date.millisecondsSinceEpoch.toDouble(), displayWeight);
    }).toList();

    double minWeight = spots.map((spot) => spot.y).reduce(math.min);
    double maxWeight = spots.map((spot) => spot.y).reduce(math.max);
    double padding = (maxWeight - minWeight) * 0.2;
    double yMin = ((minWeight - padding) / 5).floor() * 5.0;
    double yMax = ((maxWeight + padding) / 5).ceil() * 5.0;
    double yInterval = ((yMax - yMin) / 6).ceil().toDouble();
    if (yInterval > 5) {
      yInterval = (yInterval / 5).ceil() * 5.0;
    }

    final firstDate = DateTime.parse(sortedWeights.first['date'] as String);
    final lastDate = DateTime.parse(sortedWeights.last['date'] as String);
    final totalDays = lastDate.difference(firstDate).inDays;
    final startDate = firstDate.subtract(Duration(days: 2));
    final endDate = lastDate.add(Duration(days: 2));
    final xInterval = 86400000 * math.max((totalDays / 5).ceil(), 1).toDouble();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 250,
        width: math.max(MediaQuery.of(context).size.width, totalDays * 50.0),
        padding: EdgeInsets.fromLTRB(16, 16, 32, 16),
        child: LineChart(
          LineChartData(
            minX: startDate.millisecondsSinceEpoch.toDouble(),
            maxX: endDate.millisecondsSinceEpoch.toDouble(),
            minY: yMin,
            maxY: yMax,
            gridData: FlGridData(
              show: true,
              horizontalInterval: yInterval,
              verticalInterval: xInterval,
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: xInterval,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    return Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        '${date.day}/${date.month}',
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: Text('Weight ($_weightUnit)'),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                barWidth: 2,
                color: Colors.green,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: Colors.green,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutDurationChart() {
    if (_workoutHistory.isEmpty) {
      return Center(child: Text('No workout data available'));
    }

    final sortedWorkouts = List<Map<String, dynamic>>.from(_workoutHistory);
    sortedWorkouts.sort((a, b) {
      final dateA = DateTime.parse(a['date'] as String);
      final dateB = DateTime.parse(b['date'] as String);
      return dateA.compareTo(dateB);
    });

    final spots = sortedWorkouts.map((workout) {
      final date = DateTime.parse(workout['date'] as String);
      final duration = (workout['duration'] as int?) ?? 0;
      return FlSpot(date.millisecondsSinceEpoch.toDouble(), duration.toDouble());
    }).toList();

    return Container(
      height: 250,
      padding: EdgeInsets.fromLTRB(16, 16, 32, 16),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 120, // 2 hours max
          gridData: FlGridData(
            show: true,
            horizontalInterval: 30,
            verticalInterval: 86400000,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 86400000,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      '${date.day}/${date.month}',
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: 30,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text(
                      '${value.toInt()} min',
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesBurnedChart() {
    if (_workoutHistory.isEmpty) {
      return Center(child: Text('No workout data available'));
    }

    final sortedWorkouts = List<Map<String, dynamic>>.from(_workoutHistory);
    sortedWorkouts.sort((a, b) {
      final dateA = DateTime.parse(a['date'] as String);
      final dateB = DateTime.parse(b['date'] as String);
      return dateA.compareTo(dateB);
    });

    final spots = sortedWorkouts.map((workout) {
      final date = DateTime.parse(workout['date'] as String);
      final calories = (workout['calories'] as int?) ?? 0;
      return FlSpot(date.millisecondsSinceEpoch.toDouble(), calories.toDouble());
    }).toList();

    final firstDate = DateTime.parse(sortedWorkouts.first['date'] as String);
    final lastDate = DateTime.parse(sortedWorkouts.last['date'] as String);
    final totalDays = lastDate.difference(firstDate).inDays;
    
    final startDate = firstDate.subtract(Duration(days: 2));
    final endDate = lastDate.add(Duration(days: 2));
    final interval = 86400000 * math.max((totalDays / 5).ceil(), 1).toDouble();

    double maxCalories = spots.isEmpty ? 500 : spots.map((spot) => spot.y).reduce(math.max);
    maxCalories = math.max(maxCalories + 100, 200);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 250,
        width: math.max(MediaQuery.of(context).size.width, totalDays * 50.0),
        padding: EdgeInsets.fromLTRB(16, 16, 32, 16),
        child: LineChart(
          LineChartData(
            minX: startDate.millisecondsSinceEpoch.toDouble(),
            maxX: endDate.millisecondsSinceEpoch.toDouble(),
            minY: 0,
            maxY: maxCalories,
            gridData: FlGridData(
              show: true,
              horizontalInterval: 100,
              verticalInterval: interval,
            ),
            lineTouchData: LineTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    return Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        '${date.day}/${date.month}',
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  interval: 100,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text(
                        '${value.toInt()}',
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                preventCurveOverShooting: true,
                isStrokeCapRound: false,
                barWidth: 2,
                color: Colors.red,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.red,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseDistributionChart() {
    if (_workoutHistory.isEmpty) {
      return Center(child: Text('No workout data available'));
    }

    // Count exercises by type
    final exerciseCounts = <String, int>{};
    for (var workout in _workoutHistory) {
      final exercise = workout['exercise'] as String;
      exerciseCounts[exercise] = (exerciseCounts[exercise] ?? 0) + 1;
    }

    return Container(
      height: 250,
      padding: EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: exerciseCounts.values.reduce((a, b) => a > b ? a : b).toDouble(),
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= exerciseCounts.keys.length) return Text('');
                  return Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      exerciseCounts.keys.elementAt(value.toInt()),
                      style: TextStyle(fontSize: 12),
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
                  return Text(value.toInt().toString());
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: exerciseCounts.entries.map((entry) {
            return BarChartGroupData(
              x: exerciseCounts.keys.toList().indexOf(entry.key),
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: Colors.purple,
                  width: 20,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWorkoutStreakChart() {
    if (_workoutHistory.isEmpty) {
      return Center(child: Text('No workout data available'));
    }

    // Calculate streak
    int currentStreak = 0;
    DateTime? lastWorkoutDate;
    
    final sortedWorkouts = List<Map<String, dynamic>>.from(_workoutHistory);
    sortedWorkouts.sort((a, b) {
      final dateA = DateTime.parse(a['date'] as String);
      final dateB = DateTime.parse(b['date'] as String);
      return dateB.compareTo(dateA);
    });

    for (var workout in sortedWorkouts) {
      final workoutDate = DateTime.parse(workout['date'] as String);
      if (lastWorkoutDate == null) {
        currentStreak = 1;
        lastWorkoutDate = workoutDate;
      } else {
        final difference = lastWorkoutDate.difference(workoutDate).inDays;
        if (difference == 1) {
          currentStreak++;
          lastWorkoutDate = workoutDate;
        } else {
          break;
        }
      }
    }

    return Container(
      height: 100,
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_fire_department, color: Colors.orange, size: 40),
          SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$currentStreak days',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('Current Streak'),
            ],
          ),
        ],
      ),
    );
  }
} 