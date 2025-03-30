// Import required Flutter material package and custom screens
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'workout_screen.dart';
import 'workout_log_screen.dart';
import 'calorie_tracker_screen.dart';
import 'progress_tracker_screen.dart';
import 'preset_routines_screen.dart';
import 'database/database_helper.dart';
import 'dart:io';

// Main entry point of the application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite_common_ffi
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Delete existing database to apply schema changes
  final dbPath = join(Directory.current.path, '.dart_tool/sqflite_common_ffi/databases/fitness_tracker.db');
  try {
    await File(dbPath).delete();
    print('Deleted existing database');
  } catch (e) {
    print('No existing database to delete');
  }

  // Initialize database with new schema
  await DatabaseHelper.instance.database;

  runApp(MyApp());
}

// Root widget of the application
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(), // Set HomePage as the initial screen
    );
  }
}

// Home page widget that displays the main navigation menu
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with title and purple background
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Colors.purple,
      ),
      // Main content area with navigation buttons
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Navigation buttons for different features
            buildButton(context, 'Workout Log', Icons.event_note, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WorkoutLogScreen()),
              );
            }),
            SizedBox(height: 16),
            buildButton(context, 'Calorie Tracker', Icons.event_note, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalorieTrackerScreen()),
              );
            }),
            SizedBox(height: 16),
            buildButton(context, 'Progress Tracker', Icons.event_note, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProgressTrackerScreen()),
              );
            }),
            SizedBox(height: 16),
            buildButton(context, 'Preset Workouts', Icons.fitness_center, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PresetRoutinesScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Helper method to create consistent navigation buttons
  Widget buildButton(BuildContext context, String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
