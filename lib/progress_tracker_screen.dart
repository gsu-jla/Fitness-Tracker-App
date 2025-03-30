import 'package:flutter/material.dart';
import 'progress_charts_screen.dart';
import 'database/database_helper.dart';

// Screen for tracking fitness progress over time
class ProgressTrackerScreen extends StatefulWidget {
  @override
  _ProgressTrackerScreenState createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends State<ProgressTrackerScreen> {
  bool _isLoading = true;
  Map<String, double> _weightData = {
    'starting': 0.0,
    'current': 0.0,
    'goal': 0.0,
  };
  Map<String, int> _weeklySummary = {
    'sessions': 0,
    'minutes': 0,
    'calories': 0,
  };
  String _weightUnit = 'lbs'; // Default to pounds

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      _weightUnit = await DatabaseHelper.instance.getWeightUnit();
      final weightProgress = await DatabaseHelper.instance.getWeightProgress();
      final weeklySummary = await DatabaseHelper.instance.getWeeklySummary();
      
      setState(() {
        _weightData = weightProgress;
        _weeklySummary = weeklySummary;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
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
        title: Text('Progress Tracker'),
        backgroundColor: Colors.purple,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Progress Tracker'),
        backgroundColor: Colors.purple,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Weekly Summary Card
              Card(
                child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                        'Weekly Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
          ),
          SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Workouts:'),
                          Text('${_weeklySummary['sessions']} sessions'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Time:'),
                          Text('${_weeklySummary['minutes']} minutes'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Calories Burned:'),
                          Text('${_weeklySummary['calories']} cal'),
                        ],
          ),
        ],
      ),
                ),
                    ),
                    SizedBox(height: 16),
              
              // Updated Weight Progress Card
              _buildWeightProgressCard(),
              
              SizedBox(height: 16),
              
              // Action Buttons
              _buildActionButton(
                'Update Weight',
                Icons.edit,
                () => _showUpdateWeightDialog(),
                    ),
                    SizedBox(height: 8),
              _buildActionButton(
                'View Charts',
                Icons.bar_chart,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProgressChartsScreen()),
                ),
              ),
              SizedBox(height: 8),
              _buildActionButton(
                'Set New Goals',
                Icons.flag,
                () => _showSetGoalsDialog(),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.black, width: 1),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
                    Text(
              title,
              style: TextStyle(color: Colors.black),
            ),
            Icon(icon, color: Colors.black),
                  ],
                ),
              ),
    );
  }

  void _showUpdateWeightDialog() {
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Weight'),
        content: TextField(
          controller: weightController,
          decoration: InputDecoration(
            labelText: 'Current Weight ($_weightUnit)',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (weightController.text.isEmpty) return;
                double weight = double.parse(weightController.text);
                // Convert to kg if input is in lbs
                if (_weightUnit == 'lbs') {
                  weight = weight / 2.20462;
                }
                await DatabaseHelper.instance.updateWeight(weight);
                Navigator.pop(context);
                await _loadAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Weight updated successfully')),
                );
                } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating weight')),
                );
              }
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          ),
        ],
      ),
    );
  }

  void _showSetGoalsDialog() {
    final goalController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Weight Goal'),
        content: TextField(
              controller: goalController,
          decoration: InputDecoration(
            labelText: 'Goal Weight ($_weightUnit)',
            ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (goalController.text.isEmpty) return;
                double goal = double.parse(goalController.text);
                
                // Convert to kg if input is in lbs
                if (_weightUnit == 'lbs') {
                  goal = goal / 2.20462; // Convert lbs to kg for storage
                }
                
                await DatabaseHelper.instance.updateWeightGoal(goal);
                Navigator.pop(context);
                await _loadAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Goal updated successfully')),
                );
                } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating goal')),
                );
              }
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          ),
        ],
      ),
    );
  }

  void _toggleWeightUnit() async {
    final newUnit = _weightUnit == 'lbs' ? 'kg' : 'lbs';
    await DatabaseHelper.instance.saveWeightUnit(newUnit);
    await _loadAllData(); // This will refresh the data with the new unit
  }

  double calculateProgress() {
    if (_weightData['current'] == 0.0 || _weightData['goal'] == 0.0) {
      return 0.0;
    }
    
    // Simple percentage: current/goal
    return (_weightData['current']! / _weightData['goal']!).clamp(0.0, 1.0);
  }

  Widget _buildWeightProgressCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weight Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Add current/goal text
                Text(
                  '${_weightData['current']?.toStringAsFixed(1)} / ${_weightData['goal']?.toStringAsFixed(1)} $_weightUnit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Starting: ${_weightData['starting']?.toStringAsFixed(1)} $_weightUnit',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Goal: ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          '${_weightData['goal']?.toStringAsFixed(1)} $_weightUnit',
                          style: TextStyle(color: Colors.purple),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          _weightData['starting']! > _weightData['goal']! 
                              ? Icons.arrow_downward 
                              : Icons.arrow_upward,
                          size: 16,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
                // Circular progress indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: calculateProgress(),
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        calculateProgress() < 1.0 ? Colors.purple : Colors.green,
                      ),
                    ),
                    Text(
                      '${((_weightData['current']! / _weightData['goal']!) * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_weightData['starting'] != 0.0 && 
                _weightData['current'] != 0.0 && 
                _weightData['goal'] != 0.0) ...[
              LinearProgressIndicator(
                value: calculateProgress().clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  calculateProgress() < 1.0 ? Colors.purple : Colors.green,
                ),
                minHeight: 8,
              ),
            ],
          ],
        ),
      ),
    );
  }
} 