import 'package:flutter/material.dart';
import 'progress_charts_screen.dart';
import 'database/database_helper.dart';

// Screen for tracking fitness progress over time
class ProgressTrackerScreen extends StatefulWidget {
  @override
  _ProgressTrackerScreenState createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends State<ProgressTrackerScreen> {
  List<Map<String, dynamic>> _progressData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  // Load progress data from database
  Future<void> _loadProgressData() async {
    try {
      final data = await DatabaseHelper.instance.getProgressMetrics();
      setState(() {
        _progressData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with title and purple theme
      appBar: AppBar(
        title: Text('Progress Tracker'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProgressChartsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary section at the top
                _buildSummarySection(),
                // List of progress metrics
                Expanded(
                  child: _buildProgressList(),
                ),
              ],
            ),
      // Floating action button to add new metrics
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMetricDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.purple,
      ),
    );
  }

  // Build the summary section showing overall progress
  Widget _buildSummarySection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.purple.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Progress',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          // Calculate and display overall progress
          Text(
            '${_calculateOverallProgress().toStringAsFixed(2)}% of goals achieved',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 8),
          // Progress bar for overall progress
          LinearProgressIndicator(
            value: _calculateOverallProgress() / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            minHeight: 10,
          ),
        ],
      ),
    );
  }

  // Build the list of progress metrics
  Widget _buildProgressList() {
    return ListView.builder(
      itemCount: _progressData.length,
      itemBuilder: (context, index) {
        final metric = _progressData[index];
        return Card(
          margin: EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text(
              metric['name'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${metric['current_value']} ${metric['unit']} / Goal: ${metric['goal_value']} ${metric['unit']}',
            ),
            children: [
              // Progress details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress bar for this metric
                    LinearProgressIndicator(
                      value: metric['current_value'] / metric['goal_value'],
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        metric['current_value'] >= metric['goal_value'] ? Colors.green : Colors.purple,
                      ),
                      minHeight: 10,
                    ),
                    SizedBox(height: 16),
                    // History section
                    Text(
                      'History',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    // List of historical values
                    ...metric['history'].map<Widget>((record) => ListTile(
                          title: Text('${record['value']} ${metric['unit']}'),
                          subtitle: Text(_formatDate(record['date'])),
                        )),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showEditMetricDialog(metric, index),
                          icon: Icon(Icons.edit),
                          label: Text('Edit'),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _progressData.removeAt(index);
                            });
                          },
                          icon: Icon(Icons.delete, color: Colors.red),
                          label: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    Text(
                      'Current: ${metric['current_value']} ${metric['unit']}',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Goal: ${metric['goal_value']} ${metric['unit']}',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Progress: ${(metric['current_value'] / metric['goal_value'] * 100).toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: _getProgressColor(metric['current_value'] / metric['goal_value']),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Calculate overall progress percentage
  double _calculateOverallProgress() {
    if (_progressData.isEmpty) return 0;
    
    double totalProgress = 0;
    for (var metric in _progressData) {
      totalProgress += (metric['current_value'] / metric['goal_value']) * 100;
    }
    return totalProgress / _progressData.length;
  }

  // Show dialog to add a new metric
  void _showAddMetricDialog() {
    final nameController = TextEditingController();
    final currentController = TextEditingController();
    final goalController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Metric'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Metric Name'),
            ),
            TextField(
              controller: currentController,
              decoration: InputDecoration(labelText: 'Current Value'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: goalController,
              decoration: InputDecoration(labelText: 'Goal Value'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: unitController,
              decoration: InputDecoration(labelText: 'Unit (e.g., kg, reps, km)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  currentController.text.isNotEmpty &&
                  goalController.text.isNotEmpty &&
                  unitController.text.isNotEmpty) {
                try {
                  await DatabaseHelper.instance.addProgressMetric(
                    nameController.text,
                    double.parse(currentController.text),
                    double.parse(goalController.text),
                    unitController.text,
                  );
                  Navigator.pop(context);
                  _loadProgressData(); // Reload data
                } catch (e) {
                  print('Error adding metric: $e');
                  // Show error message to user
                }
              }
            },
            child: Text('Add'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          ),
        ],
      ),
    );
  }

  // Show dialog to edit an existing metric
  void _showEditMetricDialog(Map<String, dynamic> metric, int index) {
    final currentController = TextEditingController(text: metric['current_value'].toString());
    final goalController = TextEditingController(text: metric['goal_value'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${metric['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              decoration: InputDecoration(labelText: 'Current Value'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: goalController,
              decoration: InputDecoration(labelText: 'Goal Value'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (currentController.text.isNotEmpty &&
                  goalController.text.isNotEmpty) {
                try {
                  await DatabaseHelper.instance.updateProgressMetric(
                    metric['id'],
                    double.parse(currentController.text),
                    double.parse(goalController.text),
                  );
                  Navigator.pop(context);
                  _loadProgressData(); // Reload data
                } catch (e) {
                  print('Error updating metric: $e');
                  // Show error message to user
                }
              }
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          ),
        ],
      ),
    );
  }

  // Format date to DD/MM/YYYY format
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get progress color based on progress percentage
  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.5) return Colors.yellow;
    return Colors.red;
  }
} 