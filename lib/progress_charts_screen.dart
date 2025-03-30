import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Screen for visualizing progress with charts
class ProgressChartsScreen extends StatefulWidget {
  @override
  _ProgressChartsScreenState createState() => _ProgressChartsScreenState();
}

class _ProgressChartsScreenState extends State<ProgressChartsScreen> {
  // Sample workout history data
  final List<Map<String, dynamic>> _workoutHistory = [
    {
      'date': DateTime.now().subtract(Duration(days: 30)),
      'duration': 45,
      'calories': 350,
      'exercises': 5,
    },
    {
      'date': DateTime.now().subtract(Duration(days: 25)),
      'duration': 60,
      'calories': 450,
      'exercises': 6,
    },
    {
      'date': DateTime.now().subtract(Duration(days: 20)),
      'duration': 45,
      'calories': 400,
      'exercises': 5,
    },
    {
      'date': DateTime.now().subtract(Duration(days: 15)),
      'duration': 75,
      'calories': 550,
      'exercises': 8,
    },
    {
      'date': DateTime.now().subtract(Duration(days: 10)),
      'duration': 60,
      'calories': 500,
      'exercises': 7,
    },
    {
      'date': DateTime.now().subtract(Duration(days: 5)),
      'duration': 90,
      'calories': 650,
      'exercises': 9,
    },
    {
      'date': DateTime.now(),
      'duration': 75,
      'calories': 600,
      'exercises': 8,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
            _buildWorkoutDurationChart(),
            SizedBox(height: 24),
            _buildCaloriesBurnedChart(),
            SizedBox(height: 24),
            _buildExercisesCompletedChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutDurationChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Duration (minutes)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= _workoutHistory.length) return Text('');
                          final date = _workoutHistory[value.toInt()]['date'];
                          return Text('${date.day}/${date.month}');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _workoutHistory.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['duration'].toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.purple,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesBurnedChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calories Burned',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= _workoutHistory.length) return Text('');
                          final date = _workoutHistory[value.toInt()]['date'];
                          return Text('${date.day}/${date.month}');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _workoutHistory.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['calories'].toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesCompletedChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exercises Completed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= _workoutHistory.length) return Text('');
                          final date = _workoutHistory[value.toInt()]['date'];
                          return Text('${date.day}/${date.month}');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _workoutHistory.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['exercises'].toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 