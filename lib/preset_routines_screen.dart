import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'workout_screen.dart';

// Screen for managing preset workout routines
class PresetRoutinesScreen extends StatefulWidget {
  @override
  _PresetRoutinesScreenState createState() => _PresetRoutinesScreenState();
}

class _PresetRoutinesScreenState extends State<PresetRoutinesScreen> {
  // Sample preset routines data
  final List<Map<String, dynamic>> _routines = [
    {
      'name': 'Beginner Full Body',
      'level': 'Beginner',
      'exercises': [
        {'name': 'Push-ups', 'sets': 3, 'reps': '8-10', 'rest': '60s'},
        {'name': 'Squats', 'sets': 3, 'reps': '10-12', 'rest': '60s'},
        {'name': 'Plank', 'sets': 3, 'duration': '30s', 'rest': '60s'},
        {'name': 'Dumbbell Rows', 'sets': 3, 'reps': '10-12', 'rest': '60s'},
      ],
    },
    {
      'name': 'Intermediate Strength',
      'level': 'Intermediate',
      'exercises': [
        {'name': 'Bench Press', 'sets': 4, 'reps': '8-10', 'rest': '90s'},
        {'name': 'Deadlifts', 'sets': 4, 'reps': '6-8', 'rest': '90s'},
        {'name': 'Pull-ups', 'sets': 4, 'reps': '6-8', 'rest': '90s'},
        {'name': 'Squats', 'sets': 4, 'reps': '8-10', 'rest': '90s'},
      ],
    },
    {
      'name': 'Advanced Power',
      'level': 'Advanced',
      'exercises': [
        {'name': 'Power Cleans', 'sets': 5, 'reps': '5', 'rest': '120s'},
        {'name': 'Weighted Pull-ups', 'sets': 5, 'reps': '6-8', 'rest': '120s'},
        {'name': 'Front Squats', 'sets': 5, 'reps': '5', 'rest': '120s'},
        {'name': 'Overhead Press', 'sets': 5, 'reps': '5', 'rest': '120s'},
      ],
    },
    {
      'name': 'Beginner Cardio',
      'level': 'Beginner',
      'exercises': [
        {'name': 'Walking', 'duration': '20min', 'intensity': 'Moderate'},
        {'name': 'Light Jogging', 'duration': '10min', 'intensity': 'Low'},
        {'name': 'Jump Rope', 'duration': '5min', 'intensity': 'Low'},
      ],
    },
    {
      'name': 'Intermediate HIIT',
      'level': 'Intermediate',
      'exercises': [
        {'name': 'Sprint Intervals', 'sets': 8, 'work': '30s', 'rest': '60s'},
        {'name': 'Burpees', 'sets': 5, 'reps': '10', 'rest': '60s'},
        {'name': 'Mountain Climbers', 'sets': 5, 'duration': '45s', 'rest': '60s'},
      ],
    },
    {
      'name': 'Advanced Endurance',
      'level': 'Advanced',
      'exercises': [
        {'name': 'Long Distance Run', 'duration': '45min', 'intensity': 'High'},
        {'name': 'Tabata Intervals', 'sets': 8, 'work': '20s', 'rest': '10s'},
        {'name': 'Hill Sprints', 'sets': 10, 'work': '30s', 'rest': '90s'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preset Routines'),
        backgroundColor: Colors.purple,
      ),
      body: ListView.builder(
        itemCount: _routines.length,
        itemBuilder: (context, index) {
          final routine = _routines[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ExpansionTile(
              title: Text(
                routine['name'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(routine['level']),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercises:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      ...routine['exercises'].map<Widget>((exercise) => ListTile(
                            title: Text(exercise['name']),
                            subtitle: Text(
                              exercise['sets'] != null
                                  ? '${exercise['sets']} sets × ${exercise['reps']} reps (Rest: ${exercise['rest']})'
                                  : '${exercise['duration']} (${exercise['intensity']} intensity)',
                            ),
                          )),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _startRoutine(routine),
                        child: Text('Start Workout'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _startRoutine(Map<String, dynamic> routine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start ${routine['name']}?'),
        content: Text('This will create a new workout session with these exercises.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Create a new workout session
                final workoutId = await DatabaseHelper.instance.saveWorkout(
                  routine['name'],
                  DateTime.now(),
                  0, // Duration will be updated when workout is completed
                  'In Progress',
                );

                // Navigate to workout screen with the routine
                Navigator.pop(context); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutScreen(
                      workoutId: workoutId,
                      routine: routine,
                    ),
                  ),
                );
              } catch (e) {
                print('Error starting workout: $e');
                // Show error message to user
              }
            },
            child: Text('Start'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          ),
        ],
      ),
    );
  }
} 