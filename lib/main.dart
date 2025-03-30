// Import required Flutter material package and custom screens
import 'package:flutter/material.dart';
import 'workout_screen.dart';
import 'workout_log_screen.dart';
import 'calorie_tracker_screen.dart';
import 'progress_tracker_screen.dart';
import 'preset_routines_screen.dart';
import 'database/database_helper.dart';

// Main entry point of the application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the database by accessing it
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
            buildButton(context, 'Workout Log', Icons.event_note),
            SizedBox(height: 16),
            buildButton(context, 'Calorie Tracker', Icons.event_note),
            SizedBox(height: 16),
            buildButton(context, 'Progress Tracker', Icons.event_note),
            SizedBox(height: 16),
            buildButton(context, 'Workouts', Icons.fitness_center),
          ],
        ),
      ),
    );
  }

  // Helper method to create consistent navigation buttons
  Widget buildButton(BuildContext context, String title, IconData icon) {
    return Container(
      // Button styling with rounded corners and border
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: ListTile(
        title: Center(child: Text(title)),
        trailing: Icon(icon),
        // Navigation logic based on button title
        onTap: () {
          if (title == 'Workouts') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WorkoutScreen()),
            );
          } else if (title == 'Workout Log') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WorkoutLogScreen()),
            );
          } else if (title == 'Calorie Tracker') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CalorieTrackerScreen()),
            );
          } else if (title == 'Progress Tracker') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProgressTrackerScreen()),
            );
          }
        },
      ),
    );
  }
}
