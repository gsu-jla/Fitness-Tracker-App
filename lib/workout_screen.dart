import 'package:flutter/material.dart';

class WorkoutScreen extends StatefulWidget {
  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _workouts = [
    {
      'name': 'Push-ups',
      'sets': 3,
      'reps': 12,
      'icon': Icons.fitness_center,
      'description': 'Standard push-ups targeting chest and triceps',
      'difficulty': 'Intermediate',
      'date': DateTime.now().subtract(Duration(days: 1)),
    },
    {
      'name': 'Pull-ups',
      'sets': 3,
      'reps': 8,
      'icon': Icons.fitness_center,
      'description': 'Full body pull-ups targeting back and biceps',
      'difficulty': 'Advanced',
      'date': DateTime.now().subtract(Duration(days: 2)),
    },
    {
      'name': 'Squats',
      'sets': 3,
      'reps': 15,
      'icon': Icons.fitness_center,
      'description': 'Body weight squats targeting legs and core',
      'difficulty': 'Beginner',
      'date': DateTime.now().subtract(Duration(days: 3)),
    },
  ];

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      _buildRecentWorkouts(),
      _buildAllWorkouts(),
      _buildWorkoutHistory(),
    ]);
  }

  Widget _buildRecentWorkouts() {
    final recentWorkouts = _workouts.take(3).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Workouts',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddWorkoutDialog,
                icon: Icon(Icons.add),
                label: Text('Add Workout'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: recentWorkouts.length,
            itemBuilder: (context, index) {
              final workout = recentWorkouts[index];
              return _buildWorkoutCard(workout, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllWorkouts() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Workouts',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddWorkoutDialog,
                icon: Icon(Icons.add),
                label: Text('Add Workout'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _workouts.length,
            itemBuilder: (context, index) {
              return _buildWorkoutCard(_workouts[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutHistory() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Workout History',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _workouts.length,
            itemBuilder: (context, index) {
              final workout = _workouts[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Icon(workout['icon']),
                  title: Text(workout['name']),
                  subtitle: Text(
                    '${workout['sets']} sets × ${workout['reps']} reps\n${_formatDate(workout['date'])}',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout, int index) {
    return Card(
      margin: EdgeInsets.all(8.0),
      elevation: 4.0,
      child: ExpansionTile(
        leading: Icon(workout['icon']),
        title: Text(
          workout['name'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${workout['sets']} sets × ${workout['reps']} reps'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description: ${workout['description']}'),
                SizedBox(height: 8),
                Text('Difficulty: ${workout['difficulty']}'),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement start workout functionality
                      },
                      icon: Icon(Icons.play_arrow),
                      label: Text('Start'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEditWorkoutDialog(workout, index),
                      icon: Icon(Icons.edit),
                      label: Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _workouts.removeAt(index);
                        });
                      },
                      icon: Icon(Icons.delete, color: Colors.red),
                      label: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddWorkoutDialog() {
    showDialog(
      context: context,
      builder: (context) => _WorkoutDialog(
        onSave: (workout) {
          setState(() {
            _workouts.insert(0, workout);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditWorkoutDialog(Map<String, dynamic> workout, int index) {
    showDialog(
      context: context,
      builder: (context) => _WorkoutDialog(
        workout: workout,
        onSave: (updatedWorkout) {
          setState(() {
            _workouts[index] = updatedWorkout;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workouts'),
        backgroundColor: Colors.purple,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Recent',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'All Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class _WorkoutDialog extends StatefulWidget {
  final Map<String, dynamic>? workout;
  final Function(Map<String, dynamic>) onSave;

  const _WorkoutDialog({
    Key? key,
    this.workout,
    required this.onSave,
  }) : super(key: key);

  @override
  _WorkoutDialogState createState() => _WorkoutDialogState();
}

class _WorkoutDialogState extends State<_WorkoutDialog> {
  late TextEditingController _nameController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _descriptionController;
  late String _difficulty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workout?['name'] ?? '');
    _setsController = TextEditingController(text: widget.workout?['sets']?.toString() ?? '');
    _repsController = TextEditingController(text: widget.workout?['reps']?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.workout?['description'] ?? '');
    _difficulty = widget.workout?['difficulty'] ?? 'Beginner';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.workout == null ? 'Add New Workout' : 'Edit Workout'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: InputDecoration(labelText: 'Difficulty'),
              items: ['Beginner', 'Intermediate', 'Advanced']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _difficulty = newValue;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final workout = {
              'name': _nameController.text,
              'sets': int.tryParse(_setsController.text) ?? 3,
              'reps': int.tryParse(_repsController.text) ?? 12,
              'icon': Icons.fitness_center,
              'description': _descriptionController.text,
              'difficulty': _difficulty,
            };
            widget.onSave(workout);
          },
          child: Text('Save'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
        ),
      ],
    );
  }
} 