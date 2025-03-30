import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Initialize database
  Future<void> init() async {
    // Initialize FFI for desktop platforms
    sqfliteFfiInit();
    // Set the database factory
    databaseFactory = databaseFactoryFfi;
    
    _database = await _initDB('fitness_tracker.db');
    // Ensure tables are created
    await _createTablesIfNotExist();
  }

  // Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
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

  // Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Settings table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Meals table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Foods table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        FOREIGN KEY (meal_id) REFERENCES meals (id)
      )
    ''');

    // Workouts table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        duration INTEGER,
        status TEXT NOT NULL
      )
    ''');

    // Progress metrics table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS progress_metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        current_value REAL NOT NULL,
        goal_value REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Check if default settings exist
    final List<Map<String, dynamic>> settings = await db.query('settings');
    if (settings.isEmpty) {
      // Insert default settings
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

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fitness_tracker.db');
    return _database!;
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
    
    final List<Map<String, dynamic>> meals = await db.query(
      'meals',
      where: 'date LIKE ?',
      whereArgs: ['$dateStr%'],
    );

    for (var meal in meals) {
      final List<Map<String, dynamic>> foods = await db.query(
        'foods',
        where: 'meal_id = ?',
        whereArgs: [meal['id']],
      );
      meal['foods'] = foods;
    }

    return meals;
  }

  // Save workout
  Future<int> saveWorkout(String name, DateTime date, int duration, String status) async {
    final db = await instance.database;
    return await db.insert('workouts', {
      'name': name,
      'date': date.toIso8601String(),
      'duration': duration,
      'status': status,
    });
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
    final List<Map<String, dynamic>> maps = await db.query(
      'workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) {
      throw Exception('Workout not found');
    }
    return maps.first;
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
} 