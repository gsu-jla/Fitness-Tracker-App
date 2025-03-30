import 'package:flutter/material.dart';
import 'workout_screen.dart';
import 'database/database_helper.dart';

// Screen for logging completed workouts
class WorkoutLogScreen extends StatefulWidget {
  @override
  _WorkoutLogScreenState createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  List<Map<String, dynamic>> _workoutLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  Future<void> _loadWorkoutData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final logs = await DatabaseHelper.instance.getWorkoutLogs();
      
      setState(() {
        _workoutLogs = List<Map<String, dynamic>>.from(logs);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading workout data: $e');
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
        title: Text('Workout Log'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Quick log buttons section
          Container(
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickLogButton('Push-ups', Icons.fitness_center, Colors.blue),
                _buildQuickLogButton('Pull-ups', Icons.fitness_center, Colors.green),
                _buildQuickLogButton('Squats', Icons.fitness_center, Colors.orange),
                _buildQuickLogButton('Planks', Icons.fitness_center, Colors.red),
              ],
            ),
          ),
          // Scrollable list of logged workouts
          Expanded(
            child: _buildWorkoutLogList(),
          ),
        ],
      ),
      // Floating action button to add new logs
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickLogDialog(),
        child: Icon(Icons.add),
        backgroundColor: Colors.purple,
      ),
    );
  }

  // Build a quick log button with custom color
  Widget _buildQuickLogButton(String name, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () => _showQuickLogDialog(exerciseName: name),
      icon: Icon(icon),
      label: Text(name),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Build the list of logged workouts
  Widget _buildWorkoutLogList() {
    return ListView.builder(
      itemCount: _workoutLogs.length,
      itemBuilder: (context, index) {
        final log = _workoutLogs[index];
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            // Status indicator
            leading: CircleAvatar(
              backgroundColor: log['completed'] == true ? Colors.green : Colors.grey,
              child: Icon(
                log['completed'] == true ? Icons.check : Icons.pending,
                color: Colors.white,
              ),
            ),
            // Workout details
            title: Text(log['workoutName'] ?? log['exercise'] ?? 'Unnamed workout'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${log['sets']} sets × ${log['reps']} reps'),
                if (log['weight'] != null && log['weight'] > 0) 
                  Text('Weight: ${log['weight']} kg'),
              ],
            ),
            trailing: Text(_formatDate(log['date'] is DateTime 
                ? log['date'] 
                : DateTime.parse(log['date']))),
            onTap: () => _showEditLogDialog(log, index),
          ),
        );
      },
    );
  }

  // Show dialog for quick logging a workout
  void _showQuickLogDialog({String? exerciseName}) {
    final exerciseController = TextEditingController(text: exerciseName);
    final setsController = TextEditingController();
    final repsController = TextEditingController();
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quick Log: ${exerciseName ?? "Workout"}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (exerciseName == null)
              TextField(
                controller: exerciseController,
                decoration: InputDecoration(labelText: 'Exercise Name'),
              ),
            TextField(
              controller: setsController,
              decoration: InputDecoration(labelText: 'Sets'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: repsController,
              decoration: InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: weightController,
              decoration: InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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
              try {
                if (exerciseController.text.isEmpty ||
                    setsController.text.isEmpty ||
                    repsController.text.isEmpty) {
                  throw 'Please fill in all required fields';
                }

                final sets = int.parse(setsController.text);
                final reps = int.parse(repsController.text);
                final weight = weightController.text.isNotEmpty 
                    ? double.parse(weightController.text) 
                    : 0.0;

                await DatabaseHelper.instance.saveWorkoutLog(
                  exerciseController.text,
                  sets,
                  reps,
                  weight,
                  DateTime.now(),
                );

                Navigator.pop(context);
                await _loadWorkoutData();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Workout logged successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('Error logging workout: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e is String ? e : 'Error logging workout'),
                    backgroundColor: Colors.red,
                  ),
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

  // Show dialog to add a new workout log
  void _showAddLogDialog() {
    showDialog(
      context: context,
      builder: (context) => _WorkoutLogDialog(
        onSave: (log) {
          setState(() {
            _workoutLogs.insert(0, log);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  // Show dialog to edit an existing workout log
  void _showEditLogDialog(Map<String, dynamic> log, int index) {
    showDialog(
      context: context,
      builder: (context) => _WorkoutLogDialog(
        log: log,
        onSave: (updatedLog) {
          setState(() {
            _workoutLogs[index] = updatedLog;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  // Format date to DD/MM/YYYY format
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _startWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutScreen(
          workoutId: null,
          routine: {
            'name': 'Custom Workout',
            'exercises': [],
          },
        ),
      ),
    ).then((completed) {
      if (completed == true) {
        _loadWorkoutData();
      }
    });
  }
}

// Dialog for adding or editing workout logs
class _WorkoutLogDialog extends StatefulWidget {
  final Map<String, dynamic>? log;
  final String? workoutName;
  final Function(Map<String, dynamic>) onSave;

  const _WorkoutLogDialog({
    Key? key,
    this.log,
    this.workoutName,
    required this.onSave,
  }) : super(key: key);

  @override
  _WorkoutLogDialogState createState() => _WorkoutLogDialogState();
}

class _WorkoutLogDialogState extends State<_WorkoutLogDialog> {
  // Controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _notesController;
  late Duration _duration;
  late bool _completed;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing log data or defaults
    _nameController = TextEditingController(text: widget.log?['workoutName'] ?? widget.workoutName ?? '');
    _setsController = TextEditingController(text: widget.log?['sets']?.toString() ?? '');
    _repsController = TextEditingController(text: widget.log?['reps']?.toString() ?? '');
    _notesController = TextEditingController(text: widget.log?['notes'] ?? '');
    _duration = widget.log?['duration'] ?? Duration(minutes: 15);
    _completed = widget.log?['completed'] ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.log == null ? 'Log Workout' : 'Edit Workout Log'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Form fields for workout details
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Workout Name'),
            ),
            TextField(
              controller: _setsController,
              decoration: InputDecoration(labelText: 'Number of Sets'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _repsController,
              decoration: InputDecoration(labelText: 'Number of Reps'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            // Duration dropdown
            Row(
              children: [
                Text('Duration: '),
                DropdownButton<Duration>(
                  value: _duration,
                  items: [
                    Duration(minutes: 5),
                    Duration(minutes: 10),
                    Duration(minutes: 15),
                    Duration(minutes: 20),
                    Duration(minutes: 30),
                    Duration(minutes: 45),
                    Duration(minutes: 60),
                  ].map((Duration duration) {
                    return DropdownMenuItem<Duration>(
                      value: duration,
                      child: Text('${duration.inMinutes} minutes'),
                    );
                  }).toList(),
                  onChanged: (Duration? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _duration = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            // Completion status toggle
            SwitchListTile(
              title: Text('Completed'),
              value: _completed,
              onChanged: (bool value) {
                setState(() {
                  _completed = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        // Cancel and Save buttons
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final log = {
              'date': DateTime.now(),
              'workoutName': _nameController.text,
              'sets': int.tryParse(_setsController.text) ?? 3,
              'reps': int.tryParse(_repsController.text) ?? 12,
              'duration': _duration,
              'notes': _notesController.text,
              'completed': _completed,
            };
            widget.onSave(log);
          },
          child: Text('Save'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
        ),
      ],
    );
  }
} 