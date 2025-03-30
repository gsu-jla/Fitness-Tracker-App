import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'preset_routines_screen.dart';
import 'workout_log_screen.dart';

// Screen for executing preset workout routines
class WorkoutScreen extends StatefulWidget {
  final int? workoutId;
  final Map<String, dynamic>? routine;

  const WorkoutScreen({
    Key? key,
    this.workoutId,
    this.routine,
  }) : super(key: key);

  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int _currentExerciseIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _currentWorkout;
  
  // Add these new variables
  late DateTime _workoutStartTime;
  Duration get _workoutDuration {
    if (_workoutStartTime == null) return Duration.zero;
    return DateTime.now().difference(_workoutStartTime);
  }
  
  // Add MET values for different exercise types
  Map<String, double> exerciseMETs = {
    'Push-ups': 3.8,
    'Pull-ups': 3.8,
    'Squats': 5.0,
    'Lunges': 4.0,
    'Plank': 3.0,
    'Burpees': 8.0,
    'Mountain Climbers': 8.0,
    'Jumping Jacks': 8.0,
    'Dumbbell Rows': 3.5,
    'Bench Press': 3.8,
    'Deadlifts': 6.0,
    'Overhead Press': 3.5,
    // Add more exercises as needed
    'default': 4.0, // Default MET value for unknown exercises
  };

  // Estimate calories burned based on exercise type, duration, and user's weight
  // We'll use the MET formula: Calories = MET × weight (kg) × duration (hours)
  Future<int> calculateCaloriesBurned() async {
    if (widget.routine == null) return 0;
    
    double totalCalories = 0;
    final userWeight = await DatabaseHelper.instance.getUserWeight(); // Get actual weight
    
    for (var exercise in widget.routine!['exercises']) {
      // Get the MET value for this exercise
      final met = exerciseMETs[exercise['name']] ?? exerciseMETs['default']!;
      
      // Calculate duration in hours
      double durationHours;
      if (exercise['duration'] != null) {
        // If duration is specified (e.g., "30s" for planks)
        final durationStr = exercise['duration'] as String;
        final seconds = int.parse(durationStr.replaceAll('s', ''));
        durationHours = seconds / 3600;
      } else {
        // If reps are specified, estimate 30 seconds per set
        final sets = exercise['sets'] as int;
        durationHours = (sets * 30) / 3600;
      }

      // Calculate calories for this exercise
      final exerciseCalories = met * userWeight * durationHours;
      totalCalories += exerciseCalories;
    }

    // Add calories burned during rest periods
    final restPeriods = widget.routine!['exercises'].length - 1;
    final restDurationHours = (restPeriods * 60) / 3600; // Assume 60s rest between exercises
    final restCalories = 1.5 * userWeight * restDurationHours; // 1.5 MET for standing/light activity

    return (totalCalories + restCalories).round();
  }

  // Update the getter to handle the Future
  int get _caloriesBurned {
    // Use a cached value or default to 0 since we can't make the getter async
    return _cachedCalories;
  }

  // Add a field to cache the calories
  int _cachedCalories = 0;

  @override
  void initState() {
    super.initState();
    _workoutStartTime = DateTime.now();
    _loadWorkout();
    _updateCalories();
  }

  // Load workout from database
  Future<void> _loadWorkout() async {
    try {
      if (widget.workoutId != null) {
        final workout = await DatabaseHelper.instance.getWorkout(widget.workoutId!);
        setState(() {
          _currentWorkout = workout;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading workout: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add method to update calories
  Future<void> _updateCalories() async {
    final calories = await calculateCaloriesBurned();
    setState(() {
      _cachedCalories = calories;
    });
  }

  // Get current exercise
  Map<String, dynamic>? get _currentExercise {
    if (widget.routine == null || _currentExerciseIndex >= widget.routine!['exercises'].length) {
      return null;
    }
    return widget.routine!['exercises'][_currentExerciseIndex];
  }

  // Move to next exercise
  void _nextExercise() {
    if (_currentExerciseIndex < widget.routine!['exercises'].length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    } else {
      _completeWorkout();
    }
  }

  // Complete the workout
  Future<void> _completeWorkout() async {
    try {
      if (widget.workoutId != null) {
        final duration = DateTime.now().difference(_workoutStartTime).inMinutes;
        final calories = await calculateCaloriesBurned();

        // Save workout status
        await DatabaseHelper.instance.updateWorkoutStatus(
          widget.workoutId!,
          'Completed',
          DateTime.now(),
        );
        
        // Save workout log with named parameters
        await DatabaseHelper.instance.saveWorkoutLog(
          exercise: widget.routine!['name'],
          sets: widget.routine!['exercises'].length,
          reps: 1,
          weight: 0.0,
          date: DateTime.now(),
          duration: duration,
          calories: calories,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Workout completed! Burned $calories calories')),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      print('Error completing workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving workout')),
      );
    }
  }

  // Add a method to save user weight in settings
  Future<void> _showWeightInputDialog() async {
    final weightController = TextEditingController();
    final weightUnit = await DatabaseHelper.instance.getWeightUnit();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Your Weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Weight ($weightUnit)',
                hintText: 'Enter your weight',
              ),
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
                double weight = double.parse(weightController.text);
                // Convert to kg if weight is in lbs
                if (weightUnit == 'lbs') {
                  weight = weight / 2.20462;
                }
                await DatabaseHelper.instance.saveUserWeight(weight);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Weight saved successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a valid weight')),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Workout'),
          backgroundColor: Colors.purple,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.routine == null) {
      // Improved empty state with helpful actions
      return Scaffold(
        appBar: AppBar(
          title: Text('Workout'),
          backgroundColor: Colors.purple,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No workout selected'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to preset routines
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => PresetRoutinesScreen()),
                  );
                },
                child: Text('Choose a Preset Workout'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // Navigate to workout log
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => WorkoutLogScreen()),
                  );
                },
                child: Text('View Workout History'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine!['name']),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(Icons.fitness_center),
            onPressed: _showWeightInputDialog,
            tooltip: 'Set Weight',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentExerciseIndex + 1) / widget.routine!['exercises'].length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            minHeight: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Exercise ${_currentExerciseIndex + 1} of ${widget.routine!['exercises'].length}',
              style: TextStyle(fontSize: 16),
            ),
          ),
          // Current exercise
          Expanded(
            child: Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentExercise!['name'],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    if (_currentExercise!['sets'] != null)
                      Column(
                        children: [
                          Text(
                            '${_currentExercise!['sets']} sets',
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            '${_currentExercise!['reps']} reps',
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            'Rest: ${_currentExercise!['rest']}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Text(
                            _currentExercise!['duration'],
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            'Intensity: ${_currentExercise!['intensity']}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_currentExerciseIndex > 0)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentExerciseIndex--;
                      });
                    },
                    icon: Icon(Icons.arrow_back),
                    label: Text('Previous'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  ),
                ElevatedButton.icon(
                  onPressed: _nextExercise,
                  icon: Icon(_currentExerciseIndex == widget.routine!['exercises'].length - 1
                      ? Icons.check
                      : Icons.arrow_forward),
                  label: Text(_currentExerciseIndex == widget.routine!['exercises'].length - 1
                      ? 'Complete'
                      : 'Next'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 