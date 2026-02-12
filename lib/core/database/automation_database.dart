import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Automated task model
class AutomatedTask {
  final int? id;
  final String name;
  final String command;
  final String? schedule; // cron syntax
  final bool enabled;
  final DateTime? lastRun;
  final DateTime createdAt;

  AutomatedTask({
    this.id,
    required this.name,
    required this.command,
    this.schedule,
    this.enabled = true,
    this.lastRun,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'command': command,
      'schedule': schedule,
      'enabled': enabled ? 1 : 0,
      'last_run': lastRun?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AutomatedTask.fromMap(Map<String, dynamic> map) {
    return AutomatedTask(
      id: map['id'],
      name: map['name'],
      command: map['command'],
      schedule: map['schedule'],
      enabled: map['enabled'] == 1,
      lastRun: map['last_run'] != null ? DateTime.parse(map['last_run']) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  AutomatedTask copyWith({
    int? id,
    String? name,
    String? command,
    String? schedule,
    bool? enabled,
    DateTime? lastRun,
    DateTime? createdAt,
  }) {
    return AutomatedTask(
      id: id ?? this.id,
      name: name ?? this.name,
      command: command ?? this.command,
      schedule: schedule ?? this.schedule,
      enabled: enabled ?? this.enabled,
      lastRun: lastRun ?? this.lastRun,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Task execution log
class TaskLog {
  final int? id;
  final int taskId;
  final String output;
  final String status; // success, error
  final DateTime timestamp;

  TaskLog({
    this.id,
    required this.taskId,
    required this.output,
    required this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'output': output,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TaskLog.fromMap(Map<String, dynamic> map) {
    return TaskLog(
      id: map['id'],
      taskId: map['task_id'],
      output: map['output'],
      status: map['status'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

/// Database service for automation
class AutomationDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'brainiac_automation.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            command TEXT NOT NULL,
            schedule TEXT,
            enabled INTEGER DEFAULT 1,
            last_run TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id INTEGER NOT NULL,
            output TEXT NOT NULL,
            status TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // Task CRUD operations
  static Future<int> insertTask(AutomatedTask task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  static Future<List<AutomatedTask>> getTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'created_at DESC');
    return maps.map((map) => AutomatedTask.fromMap(map)).toList();
  }

  static Future<int> updateTask(AutomatedTask task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  static Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Log operations
  static Future<int> insertLog(TaskLog log) async {
    final db = await database;
    return await db.insert('logs', log.toMap());
  }

  static Future<List<TaskLog>> getLogsForTask(int taskId) async {
    final db = await database;
    final maps = await db.query(
      'logs',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'timestamp DESC',
      limit: 50,
    );
    return maps.map((map) => TaskLog.fromMap(map)).toList();
  }
}
