import 'package:flutter/material.dart';

// Screen for tracking daily calorie intake
class CalorieTrackerScreen extends StatefulWidget {
  @override
  _CalorieTrackerScreenState createState() => _CalorieTrackerScreenState();
}

class _CalorieTrackerScreenState extends State<CalorieTrackerScreen> {
  // Daily calorie goal for the user
  final int _dailyCalorieGoal = 2000;
  
  // List of meals with their items and details
  final List<Map<String, dynamic>> _meals = [
    {
      'name': 'Breakfast',
      'items': [
        {
          'name': 'Oatmeal',
          'calories': 300,
          'time': DateTime.now().subtract(Duration(hours: 4)),
        },
        {
          'name': 'Banana',
          'calories': 105,
          'time': DateTime.now().subtract(Duration(hours: 4)),
        },
      ],
    },
    {
      'name': 'Lunch',
      'items': [
        {
          'name': 'Chicken Salad',
          'calories': 450,
          'time': DateTime.now().subtract(Duration(hours: 1)),
        },
      ],
    },
  ];

  // Calculate total calories from all meals
  int get _totalCalories {
    return _meals.expand((meal) => meal['items']).fold(
          0,
          (sum, item) => sum + (item['calories'] as int),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with title and purple theme
      appBar: AppBar(
        title: Text('Calorie Tracker'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Calorie summary section at the top
          _buildCalorieSummary(),
          // Scrollable list of meals
          Expanded(
            child: _buildMealList(),
          ),
        ],
      ),
      // Floating action button to add new meals
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMealDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.purple,
      ),
    );
  }

  // Build the calorie summary section with progress bar
  Widget _buildCalorieSummary() {
    final progress = _totalCalories / _dailyCalorieGoal;
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.purple.withOpacity(0.1),
      child: Column(
        children: [
          // Display daily goal and remaining calories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Goal: $_dailyCalorieGoal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Remaining: ${_dailyCalorieGoal - _totalCalories}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Progress bar showing calorie intake
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.red : Colors.purple,
            ),
            minHeight: 10,
          ),
        ],
      ),
    );
  }

  // Build the list of meals
  Widget _buildMealList() {
    return ListView.builder(
      itemCount: _meals.length,
      itemBuilder: (context, index) {
        final meal = _meals[index];
        // Calculate total calories for this meal
        final mealCalories = meal['items'].fold(
          0,
          (sum, item) => sum + item['calories'],
        );

        // Create expandable card for each meal
        return Card(
          margin: EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text(
              meal['name'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('$mealCalories calories'),
            children: [
              // List of food items in this meal
              ...meal['items'].map<Widget>((item) => ListTile(
                    title: Text(item['name']),
                    subtitle: Text('${item['calories']} calories'),
                    trailing: Text(_formatTime(item['time'])),
                  )),
              // Add food button for this meal
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAddFoodDialog(meal),
                      icon: Icon(Icons.add),
                      label: Text('Add Food'),
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

  // Show dialog to add a new meal
  void _showAddMealDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Meal'),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Meal Name',
            hintText: 'e.g., Breakfast, Lunch, Dinner, Snack',
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _meals.add({
                  'name': value,
                  'items': [],
                });
              });
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Show dialog to add food to a specific meal
  void _showAddFoodDialog(Map<String, dynamic> meal) {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Food to ${meal['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Food Name'),
            ),
            TextField(
              controller: caloriesController,
              decoration: InputDecoration(labelText: 'Calories'),
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
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  caloriesController.text.isNotEmpty) {
                setState(() {
                  meal['items'].add({
                    'name': nameController.text,
                    'calories': int.parse(caloriesController.text),
                    'time': DateTime.now(),
                  });
                });
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          ),
        ],
      ),
    );
  }

  // Format time to HH:MM format
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
} 