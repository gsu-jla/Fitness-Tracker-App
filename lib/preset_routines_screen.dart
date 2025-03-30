import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'workout_screen.dart';

// Screen for managing preset workout routines
class PresetRoutinesScreen extends StatefulWidget {
  @override
  _PresetRoutinesScreenState createState() => _PresetRoutinesScreenState();
}

class _PresetRoutinesScreenState extends State<PresetRoutinesScreen> {
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
      'name': 'Core Strength',
      'level': 'Beginner',
      'exercises': [
        {'name': 'Crunches', 'sets': 3, 'reps': '15', 'rest': '45s'},
        {'name': 'Plank', 'sets': 3, 'duration': '30s', 'rest': '45s'},
        {'name': 'Russian Twists', 'sets': 3, 'reps': '20', 'rest': '45s'},
        {'name': 'Mountain Climbers', 'sets': 3, 'duration': '30s', 'rest': '45s'},
      ],
    },
    {
      'name': 'Upper Body Focus',
      'level': 'Intermediate',
      'exercises': [
        {'name': 'Push-ups', 'sets': 4, 'reps': '12', 'rest': '60s'},
        {'name': 'Pull-ups', 'sets': 4, 'reps': '8', 'rest': '60s'},
        {'name': 'Dips', 'sets': 4, 'reps': '10', 'rest': '60s'},
        {'name': 'Diamond Push-ups', 'sets': 3, 'reps': '10', 'rest': '60s'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Routines'),
        backgroundColor: Colors.purple,
      ),
      body: ListView.builder(
        itemCount: _routines.length,
        itemBuilder: (context, index) {
          final routine = _routines[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ExpansionTile(
              title: Row(
                children: [
                  Icon(
                    _getRoutineIcon(routine['level']),
                    color: _getLevelColor(routine['level']),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          routine['level'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercises:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...routine['exercises'].map<Widget>((exercise) {
                        return Card(
                          color: Colors.grey[100],
                          child: ListTile(
                            leading: Icon(Icons.fitness_center),
                            title: Text(exercise['name']),
                            subtitle: Text(
                              exercise['duration'] != null
                                  ? '${exercise['sets']} sets × ${exercise['duration']} (Rest: ${exercise['rest']})'
                                  : '${exercise['sets']} sets × ${exercise['reps']} reps (Rest: ${exercise['rest']})',
                            ),
                          ),
                        );
                      }).toList(),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _startRoutine(routine),
                          icon: Icon(Icons.play_arrow),
                          label: Text('Start Workout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
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

  IconData _getRoutineIcon(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Icons.star_outline;
      case 'intermediate':
        return Icons.star_half;
      case 'advanced':
        return Icons.star;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  void _startRoutine(Map<String, dynamic> routine) async {
    try {
      // Save the routine to the database and get its ID
      final workoutId = await DatabaseHelper.instance.saveWorkout(
        name: routine['name'],
        level: routine['level'],
        exercises: routine['exercises'],
      );

      // Navigate to the workout screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutScreen(
            workoutId: workoutId,
            routine: routine,
          ),
        ),
      );

      // If workout was completed, show success message
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Workout completed!')),
        );
      }
    } catch (e) {
      print('Error starting workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting workout')),
      );
    }
  }
} 