import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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

  Widget buildButton(BuildContext context, String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: ListTile(
        title: Center(child: Text(title)),
        trailing: Icon(icon),
        onTap: () {},
      ),
    );
  }
}
