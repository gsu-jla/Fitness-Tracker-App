import 'package:flutter/material.dart';

class WorkoutScreen extends StatefulWidget {
  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final List<Map<String, dynamic>> _workouts = [
    {
      'name': 'Push-ups',
      'sets': 3,
      'reps': 12,
      'icon': Icons.fitness_center,
    },
    {
      'name': 'Pull-ups',
      'sets': 3,
      'reps': 8,
      'icon': Icons.fitness_center,
    },
    {
      'name': 'Squats',
      'sets': 3,
      'reps': 15,
      'icon': Icons.fitness_center,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workouts'),
        backgroundColor: Colors.purple,
      ),
      body: ListView.builder(
        itemCount: _workouts.length,
        itemBuilder: (context, index) {
          final workout = _workouts[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              leading: Icon(workout['icon']),
              title: Text(workout['name']),
              subtitle: Text('${workout['sets']} sets × ${workout['reps']} reps'),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  // TODO: Implement edit functionality
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add new workout functionality
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.purple,
      ),
    );
  }
} 