import 'package:flutter/material.dart';
import 'database/database_helper.dart';

// Screen for tracking daily calorie intake
class CalorieTrackerScreen extends StatefulWidget {
  @override
  _CalorieTrackerScreenState createState() => _CalorieTrackerScreenState();
}

class _CalorieTrackerScreenState extends State<CalorieTrackerScreen> {
  // Daily calorie goal
  int _dailyCalorieGoal = 2000; // Default value
  List<Map<String, dynamic>> _meals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load data from database
  Future<void> _loadData() async {
    try {
      final goal = await DatabaseHelper.instance.getDailyCalorieGoal();
      final meals = await DatabaseHelper.instance.getMealsForDate(DateTime.now());
      setState(() {
        _dailyCalorieGoal = goal;
        _meals = meals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Calculate total calories from all meals
  int get _totalCalories {
    int total = 0;
    for (var meal in _meals) {
      for (var food in meal['foods']) {
        total += food['calories'] as int;
      }
    }
    return total;
  }

  // Calculate remaining calories
  int get _remainingCalories {
    return _dailyCalorieGoal - _totalCalories;
  }

  // Check if goal is met
  bool get _isGoalMet {
    return _totalCalories >= _dailyCalorieGoal;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Calorie Tracker'),
          backgroundColor: Colors.purple,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Calorie Tracker'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Calorie summary section
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.purple.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Goal: $_dailyCalorieGoal cal',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Total: $_totalCalories cal',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Progress: ${(_totalCalories / _dailyCalorieGoal * 100).toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                if (_isGoalMet)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Congratulations! You\'ve met your goal!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Remaining: $_remainingCalories cal',
                    style: TextStyle(fontSize: 18),
                  ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _totalCalories / _dailyCalorieGoal,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isGoalMet ? Colors.green : Colors.purple,
                  ),
                  minHeight: 10,
                ),
              ],
            ),
          ),
          // List of meals
          Expanded(
            child: ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (context, index) {
                final meal = _meals[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Text(meal['type']),
                    subtitle: Text(
                      '${meal['foods'].fold(0, (sum, food) => sum + food['calories'])} calories',
                    ),
                    children: [
                      ...meal['foods'].map<Widget>((food) => ListTile(
                            title: Text(food['name']),
                            trailing: Text('${food['calories']} cal'),
                          )),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showEditMealDialog(meal, index),
                            icon: Icon(Icons.edit),
                            label: Text('Edit'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _meals.removeAt(index);
                              });
                            },
                            icon: Icon(Icons.delete, color: Colors.red),
                            label: Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMealDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.purple,
      ),
    );
  }

  // Show dialog to add a new meal
  void _showAddMealDialog() {
    final typeController = TextEditingController();
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Meal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: InputDecoration(labelText: 'Meal Type (e.g., Breakfast)'),
            ),
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
            onPressed: () async {
              if (typeController.text.isNotEmpty &&
                  nameController.text.isNotEmpty &&
                  caloriesController.text.isNotEmpty) {
                final mealId = await DatabaseHelper.instance.saveMeal(
                  typeController.text,
                  DateTime.now(),
                );
                await DatabaseHelper.instance.saveFood(
                  mealId,
                  nameController.text,
                  int.parse(caloriesController.text),
                );
                await _loadData();
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

  // Show dialog to edit a meal
  void _showEditMealDialog(Map<String, dynamic> meal, int mealIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${meal['type']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...meal['foods'].asMap().entries.map<Widget>((entry) {
              final food = entry.value;
              final foodIndex = entry.key;
              return ListTile(
                title: Text(food['name']),
                trailing: Text('${food['calories']} cal'),
                onTap: () => _showEditFoodDialog(mealIndex, foodIndex),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Show dialog to edit a food item
  void _showEditFoodDialog(int mealIndex, int foodIndex) {
    final nameController = TextEditingController(
      text: _meals[mealIndex]['foods'][foodIndex]['name'],
    );
    final caloriesController = TextEditingController(
      text: _meals[mealIndex]['foods'][foodIndex]['calories'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Food'),
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
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  caloriesController.text.isNotEmpty) {
                // TODO: Implement food editing in database
                await _loadData();
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          ),
        ],
      ),
    );
  }
}