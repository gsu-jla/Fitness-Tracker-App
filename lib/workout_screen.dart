import 'package:flutter/material.dart';
import 'database/database_helper.dart';

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
  DateTime? _workoutStartTime;
  Duration get _workoutDuration {
    if (_workoutStartTime == null) return Duration.zero;
    return DateTime.now().difference(_workoutStartTime!);
  }
  
  // Estimate calories burned (this is a simple calculation, you might want to make it more sophisticated)
  int get _caloriesBurned {
    // Basic calculation: 6 calories per minute of exercise
    return (_workoutDuration.inMinutes * 6).round();
  }

  @override
  void initState() {
    super.initState();
    _workoutStartTime = DateTime.now(); // Start timing when workout screen opens
    _loadWorkout();
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
        // Save workout status
        await DatabaseHelper.instance.updateWorkoutStatus(
          widget.workoutId!,
          'Completed',
          DateTime.now(),
        );
        
        // Save workout history
        await DatabaseHelper.instance.saveWorkoutHistory(
          duration: _workoutDuration.inMinutes,
          calories: _caloriesBurned,
          exercises: widget.routine?['exercises'].length ?? 0,
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Workout saved successfully!')),
        );
      }
      Navigator.pop(context, true); // Pass back true to indicate completion
    } catch (e) {
      print('Error completing workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving workout')),
      );
    }
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
      return Scaffold(
        appBar: AppBar(
          title: Text('Workout'),
          backgroundColor: Colors.purple,
        ),
        body: Center(child: Text('No routine selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine!['name']),
        backgroundColor: Colors.purple,
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