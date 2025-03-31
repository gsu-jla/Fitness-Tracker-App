import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

// Database helper class to manage all SQLite operations
class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Get database instance, creating it if needed
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fitness_tracker.db');
    return _database!;
  }

  // Initialize the database with required tables
  Future<Database> _initDB(String filePath) async {
    final documentsPath = Directory.current.path;
    final dbPath = join(documentsPath, '.dart_tool', 'sqflite_common_ffi', 'databases');
    final path = join(dbPath, filePath);

    // Ensure the directory exists
    await Directory(dbPath).create(recursive: true);

    // Delete existing database to force recreation
    try {
      await File(path).delete();
      print('Deleted existing database');
    } catch (e) {
      print('No existing database to delete');
    }

    print('Creating new database at: $path');

    return await openDatabase(
      path,
      version: 4, // Increment version number
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    print('Creating new database with version $version');
    
    // Create workouts table
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        level TEXT NOT NULL,
        exercises TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Not Started',
        completed_at TEXT
      )
    ''');

    // Create workout_logs table
    await db.execute('''
      CREATE TABLE workout_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL NOT NULL,
        date TEXT NOT NULL,
        duration INTEGER NOT NULL,
        calories INTEGER NOT NULL
      )
    ''');

    // Create weight_history table
    await db.execute('''
      CREATE TABLE weight_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Insert default weight unit setting
    await db.insert('settings', {
      'key': 'weight_unit',
      'value': 'lbs'
    });

    // Add meals table
    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Add foods table
    await db.execute('''
      CREATE TABLE foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        FOREIGN KEY (meal_id) REFERENCES meals (id)
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from $oldVersion to $newVersion');
    if (oldVersion < newVersion) {
      // Drop existing tables
      await db.execute('DROP TABLE IF EXISTS workout_logs');
      await db.execute('DROP TABLE IF EXISTS workouts');
      await db.execute('DROP TABLE IF EXISTS meals');
      await db.execute('DROP TABLE IF EXISTS foods');
      
      // Recreate workout_logs table
      await db.execute('''
        CREATE TABLE workout_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          exercise TEXT,
          sets INTEGER,
          reps INTEGER,
          weight REAL,
          date TEXT,
          duration INTEGER DEFAULT 0,
          calories INTEGER DEFAULT 0,
          completed BOOLEAN DEFAULT 0
        )
      ''');

      // Recreate workouts table
      await db.execute('''
        CREATE TABLE workouts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          level TEXT NOT NULL,
          exercises TEXT NOT NULL,
          date TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'Not Started',
          completed_at TEXT
        )
      ''');

      // Recreate meals table
      await db.execute('''
        CREATE TABLE meals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          date TEXT NOT NULL
        )
      ''');

      // Recreate foods table
      await db.execute('''
        CREATE TABLE foods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          meal_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          calories INTEGER NOT NULL,
          FOREIGN KEY (meal_id) REFERENCES meals (id)
        )
      ''');
    }
  }

  // Create tables if they don't exist
  Future<void> _createTablesIfNotExist() async {
    final db = await instance.database;
    
    // Check if tables exist
    final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    final tableNames = tables.map((table) => table['name'] as String).toList();

    // Create meals table
    if (!tableNames.contains('meals')) {
      await db.execute('''
        CREATE TABLE meals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          date TEXT NOT NULL
        )
      ''');
    }

    // Create foods table
    if (!tableNames.contains('foods')) {
      await db.execute('''
        CREATE TABLE foods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          meal_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          calories INTEGER NOT NULL,
          FOREIGN KEY (meal_id) REFERENCES meals (id)
        )
      ''');
    }

    // Create settings table
    if (!tableNames.contains('settings')) {
      await db.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT NOT NULL UNIQUE,
          value TEXT NOT NULL
        )
      ''');
    }

    // Create progress_metrics table
    if (!tableNames.contains('progress_metrics')) {
      await db.execute('''
        CREATE TABLE progress_metrics (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          current_value REAL NOT NULL,
          goal_value REAL NOT NULL,
          unit TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    // Create progress_history table
    if (!tableNames.contains('progress_history')) {
      await db.execute('''
        CREATE TABLE progress_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          metric_id INTEGER NOT NULL,
          value REAL NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY (metric_id) REFERENCES progress_metrics (id)
        )
      ''');
    }

    // Check if default settings exist
    final settings = await db.query('settings');
    if (settings.isEmpty) {
      await db.insert('settings', {
        'key': 'daily_calorie_goal',
        'value': '2000',
      });
    }
  }

  // Close database
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // Save daily calorie goal
  Future<void> saveDailyCalorieGoal(int goal) async {
    final db = await instance.database;
    await db.update(
      'settings',
      {'value': goal.toString()},
      where: 'key = ?',
      whereArgs: ['daily_calorie_goal'],
    );
  }

  // Get daily calorie goal
  Future<int> getDailyCalorieGoal() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['daily_calorie_goal'],
    );
    
    if (results.isEmpty) {
      return 2000; // Default value
    }
    
    return int.parse(results.first['value'] as String);
  }

  // Save meal
  Future<int> saveMeal(String type, DateTime date) async {
    final db = await instance.database;
    return await db.insert('meals', {
      'type': type,
      'date': date.toIso8601String(),
    });
  }

  // Save food
  Future<void> saveFood(int mealId, String name, int calories) async {
    final db = await instance.database;
    await db.insert('foods', {
      'meal_id': mealId,
      'name': name,
      'calories': calories,
    });
  }

  // Get meals for a specific date
  Future<List<Map<String, dynamic>>> getMealsForDate(DateTime date) async {
    final db = await instance.database;
    final dateStr = date.toIso8601String().split('T')[0];
    
    // Get meals for the date
    final meals = await db.query(
      'meals',
      where: 'date LIKE ?',
      whereArgs: ['$dateStr%'],
    );

    // Get foods for each meal
    List<Map<String, dynamic>> result = [];
    for (var meal in meals) {
      final foods = await db.query(
        'foods',
        where: 'meal_id = ?',
        whereArgs: [meal['id']],
      );

      result.add({
        ...meal,
        'foods': foods,
      });
    }

    return result;
  }

  // Save workout
  Future<int> saveWorkout({
    required String name,
    required String level,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final db = await database;
    
    try {
      // Convert exercises list to JSON string for storage
      final exercisesJson = exercises.toString();
      
      final workoutData = {
        'name': name,
        'level': level,
        'exercises': exercisesJson,
        'date': DateTime.now().toIso8601String(),
        'status': 'Not Started',
      };

      final id = await db.insert(
        'workouts',
        workoutData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('Saved workout with ID: $id'); // Debug print
      return id;
    } catch (e) {
      print('Error saving workout: $e');
      throw e;
    }
  }

  // Get workouts for a specific date
  Future<List<Map<String, dynamic>>> getWorkoutsForDate(DateTime date) async {
    final db = await instance.database;
    final dateStr = date.toIso8601String().split('T')[0];
    
    return await db.query(
      'workouts',
      where: 'date LIKE ?',
      whereArgs: ['$dateStr%'],
    );
  }

  // Save progress metric
  Future<void> saveProgressMetric(String name, double currentValue, double goalValue) async {
    final db = await instance.database;
    await db.insert('progress_metrics', {
      'name': name,
      'current_value': currentValue,
      'goal_value': goalValue,
      'date': DateTime.now().toIso8601String(),
    });
  }

  // Get progress metrics
  Future<List<Map<String, dynamic>>> getProgressMetrics() async {
    final db = await instance.database;
    final metrics = await db.query('progress_metrics');
    
    for (var metric in metrics) {
      final history = await db.query(
        'progress_history',
        where: 'metric_id = ?',
        whereArgs: [metric['id']],
      );
      metric['history'] = history;
    }
    
    return metrics;
  }

  // Progress Tracking Methods
  Future<void> addProgressMetric(String name, double currentValue, double goalValue, String unit) async {
    final db = await database;
    final id = await db.insert('progress_metrics', {
      'name': name,
      'current_value': currentValue,
      'goal_value': goalValue,
      'unit': unit,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('progress_history', {
      'metric_id': id,
      'value': currentValue,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateProgressMetric(int id, double currentValue, double goalValue) async {
    final db = await database;
    await db.update(
      'progress_metrics',
      {
        'current_value': currentValue,
        'goal_value': goalValue,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await db.insert('progress_history', {
      'metric_id': id,
      'value': currentValue,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteProgressMetric(int id) async {
    final db = await database;
    await db.delete('progress_history', where: 'metric_id = ?', whereArgs: [id]);
    await db.delete('progress_metrics', where: 'id = ?', whereArgs: [id]);
  }

  // Get a specific workout by ID
  Future<Map<String, dynamic>> getWorkout(int id) async {
    final db = await database;
    final results = await db.query(
      'workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (results.isEmpty) {
      throw Exception('Workout not found');
    }

    final workout = results.first;
    return {
      ...workout,
      'exercises': workout['exercises'], // This is already a JSON string
    };
  }

  // Update workout status
  Future<void> updateWorkoutStatus(int id, String status, DateTime completedAt) async {
    final db = await database;
    await db.update(
      'workouts',
      {
        'status': status,
        'completed_at': completedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Save workout history
  Future<void> saveWorkoutHistory({
    required int duration,
    required int calories,
    required int exercises,
  }) async {
    final db = await database;
    await db.insert(
      'workout_history',
      {
        'date': DateTime.now().toIso8601String(),
        'duration': duration,
        'calories': calories,
        'exercises': exercises,
      },
    );
  }

  // Get workout history
  Future<List<Map<String, dynamic>>> getWorkoutHistory() async {
    final db = await database;
    try {
      final results = await db.query(
        'workout_logs',
        orderBy: 'date DESC',
      );
      print('Workout history query results: $results');
      return results;
    } catch (e) {
      print('Error getting workout history: $e');
      return [];
    }
  }

  // Add this method if it doesn't exist
  Future<List<Map<String, dynamic>>> getWorkouts() async {
    final db = await database;
    return await db.query('workouts', orderBy: 'date DESC');
  }

  Future<void> setDailyCalorieGoal(int goal) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'daily_calorie_goal', 'value': goal.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMealType(int mealId, String newType) async {
    final db = await database;
    await db.update(
      'meals',
      {'type': newType},
      where: 'id = ?',
      whereArgs: [mealId],
    );
  }

  Future<void> updateFood(int foodId, String name, int calories) async {
    final db = await database;
    await db.update(
      'foods',
      {
        'name': name,
        'calories': calories,
      },
      where: 'id = ?',
      whereArgs: [foodId],
    );
  }

  Future<void> deleteFood(int foodId) async {
    final db = await database;
    await db.delete(
      'foods',
      where: 'id = ?',
      whereArgs: [foodId],
    );
  }

  Future<void> deleteMeal(int mealId) async {
    final db = await database;
    // First delete all foods associated with this meal
    await db.delete(
      'foods',
      where: 'meal_id = ?',
      whereArgs: [mealId],
    );
    // Then delete the meal itself
    await db.delete(
      'meals',
      where: 'id = ?',
      whereArgs: [mealId],
    );
  }

  Future<void> saveWorkoutLog({
    required String exercise,
    required int sets,
    required int reps,
    required double weight,
    required DateTime date,
    required int duration,
    required int calories,
  }) async {
    final db = await database;
    await db.insert(
      'workout_logs',
      {
        'exercise': exercise,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'date': date.toIso8601String(),
        'duration': duration,
        'calories': calories,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getWorkoutLogs() async {
    final db = await database;
    return await db.query(
      'workout_logs',
      orderBy: 'date DESC',
    );
  }

  Future<void> updateWeight(double weight) async {
    final db = await database;
    await db.insert(
      'weight_history',
      {
        'weight': weight,
        'date': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get user's weight progress data
  Future<Map<String, double>> getWeightProgress() async {
    final db = await database;
    final unit = await getWeightUnit();
    // Convert weight to appropriate unit (kg/lbs)
    final multiplier = unit == 'lbs' ? 2.20462 : 1.0;
    
    // Get first recorded weight
    final startingWeight = await db.query(
      'weight_history',
      orderBy: 'date ASC',
      limit: 1,
    );
    
    // Get most recent weight
    final currentWeight = await db.query(
      'weight_history',
      orderBy: 'date DESC',
      limit: 1,
    );
    
    // Get user's goal weight from settings
    final goalWeight = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['weight_goal'],
    );
    
    // Return weight data with appropriate unit conversion
    return {
      'starting': startingWeight.isNotEmpty ? (startingWeight.first['weight'] as num).toDouble() * multiplier : 0.0,
      'current': currentWeight.isNotEmpty ? (currentWeight.first['weight'] as num).toDouble() * multiplier : 0.0,
      'goal': goalWeight.isNotEmpty ? double.parse(goalWeight.first['value'].toString()) * multiplier : 0.0,
    };
  }

  // Get summary of workouts for current week
  Future<Map<String, int>> getWeeklySummary() async {
    final db = await database;
    // Calculate start of current week
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1).toIso8601String();
    
    try {
      // Query to get workout totals for current week
      final result = await db.rawQuery('''
        SELECT 
          COUNT(DISTINCT date) as sessions,
          COALESCE(SUM(duration), 0) as total_minutes,
          COALESCE(SUM(calories), 0) as total_calories
        FROM workout_logs
        WHERE date >= ?
      ''', [weekStart]);
      
      // Return workout summary data
      return {
        'sessions': (result.first['sessions'] as num?)?.toInt() ?? 0,
        'minutes': (result.first['total_minutes'] as num?)?.toInt() ?? 0,
        'calories': (result.first['total_calories'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      // Return zeros if query fails
      return {
        'sessions': 0,
        'minutes': 0,
        'calories': 0,
      };
    }
  }

  Future<void> updateWeightGoal(double goal) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'key': 'weight_goal',
        'value': goal.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveWeightUnit(String unit) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'key': 'weight_unit',
        'value': unit,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> getWeightUnit() async {
    final db = await database;
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['weight_unit'],
    );
    
    return results.isEmpty ? 'lbs' : results.first['value'] as String;
  }

  Future<List<Map<String, dynamic>>> getWeightHistory() async {
    final db = await database;
    try {
      final results = await db.query(
        'weight_history',
        orderBy: 'date DESC',
      );
      print('Weight history query results: $results');
      return results;
    } catch (e) {
      print('Error getting weight history: $e');
      return [];
    }
  }

  Future<void> saveUserWeight(double weightKg) async {
    final db = await database;
    await db.insert(
      'weight_history',
      {
        'weight': weightKg,
        'date': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> getUserWeight() async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['user_weight'],
    );
    
    if (result.isEmpty) {
      return 70.0; // Default weight in kg
    }
    
    return double.parse(result.first['value'] as String);
  }

  Future<int> getTodayCaloriesBurned() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    
    final result = await db.rawQuery('''
      SELECT SUM(calories) as total_calories
      FROM workout_logs
      WHERE date >= ?
    ''', [startOfDay]);
    
    return (result.first['total_calories'] as num?)?.toInt() ?? 0;
  }
} 