import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/automation/models/automation.dart';
import '../../features/automation/models/automation_enums.dart';

/// Repository for persisting Automation objects to SQLite
class AutomationRepository {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'brainiac_automations_v2.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS automations');
          await db.execute('DROP TABLE IF EXISTS automation_logs');
          await _createTables(db);
        }
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    // Automations table
    await db.execute('''
      CREATE TABLE automations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        service TEXT NOT NULL,
        preferred_mode TEXT NOT NULL,
        trigger_type TEXT NOT NULL,
        status TEXT NOT NULL,
        config TEXT NOT NULL,
        cron_schedule TEXT,
        next_run TEXT,
        last_run TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER NOT NULL,
        is_template INTEGER NOT NULL,
        execution_count INTEGER DEFAULT 0,
        success_count INTEGER DEFAULT 0,
        failure_count INTEGER DEFAULT 0,
        tags TEXT
      )
    ''');

    // Automation logs table
    await db.execute('''
      CREATE TABLE automation_logs (
        id TEXT PRIMARY KEY,
        automation_id TEXT NOT NULL,
        execution_mode TEXT NOT NULL,
        status TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        error_message TEXT,
        result TEXT,
        steps TEXT,
        FOREIGN KEY (automation_id) REFERENCES automations (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_automation_category ON automations(category)');
    await db.execute('CREATE INDEX idx_automation_service ON automations(service)');
    await db.execute('CREATE INDEX idx_automation_status ON automations(status)');
    await db.execute('CREATE INDEX idx_automation_active ON automations(is_active)');
    await db.execute('CREATE INDEX idx_logs_automation_id ON automation_logs(automation_id)');
  }

  /// Insert a new automation
  static Future<int> insertAutomation(Automation automation) async {
    final db = await database;
    final map = automation.toMap();
    
    // SQLite doesn't support nested maps, so we need to serialize config
    map['config'] = _serializeMap(automation.config);
    
    return await db.insert('automations', map);
  }

  /// Get all automations
  static Future<List<Automation>> getAllAutomations() async {
    final db = await database;
    final maps = await db.query('automations', orderBy: 'created_at DESC');
    
    return maps.map((map) {
      final modifiedMap = Map<String, dynamic>.from(map);
      modifiedMap['config'] = _deserializeMap(map['config'] as String);
      return Automation.fromMap(modifiedMap);
    }).toList();
  }

  /// Get automations by category
  static Future<List<Automation>> getAutomationsByCategory(AutomationCategory category) async {
    final db = await database;
    final maps = await db.query(
      'automations',
      where: 'category = ?',
      whereArgs: [category.name],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) {
      final modifiedMap = Map<String, dynamic>.from(map);
      modifiedMap['config'] = _deserializeMap(map['config'] as String);
      return Automation.fromMap(modifiedMap);
    }).toList();
  }

  /// Get active automations only
  static Future<List<Automation>> getActiveAutomations() async {
    final db = await database;
    final maps = await db.query(
      'automations',
      where: 'is_active = ? AND is_template = ?',
      whereArgs: [1, 0],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) {
      final modifiedMap = Map<String, dynamic>.from(map);
      modifiedMap['config'] = _deserializeMap(map['config'] as String);
      return Automation.fromMap(modifiedMap);
    }).toList();
  }

  /// Get automation by ID
  static Future<Automation?> getAutomationById(String id) async {
    final db = await database;
    final maps = await db.query(
      'automations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    
    final map = Map<String, dynamic>.from(maps.first);
    map['config'] = _deserializeMap(maps.first['config'] as String);
    return Automation.fromMap(map);
  }

  /// Update an automation
  static Future<int> updateAutomation(Automation automation) async {
    final db = await database;
    final map = automation.toMap();
    map['config'] = _serializeMap(automation.config);
    
    return await db.update(
      'automations',
      map,
      where: 'id = ?',
      whereArgs: [automation.id],
    );
  }

  /// Delete an automation
  static Future<int> deleteAutomation(String id) async {
    final db = await database;
    return await db.delete(
      'automations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Insert automation log
  static Future<int> insertLog(AutomationLog log) async {
    final db = await database;
    final map = log.toMap();
    map['result'] = map['result'] != null ? _serializeMap(map['result']) : null;
    
    return await db.insert('automation_logs', map);
  }

  /// Get logs for a specific automation
  static Future<List<AutomationLog>> getLogsForAutomation(String automationId, {int limit = 50}) async {
    final db = await database;
    final maps = await db.query(
      'automation_logs',
      where: 'automation_id = ?',
      whereArgs: [automationId],
      orderBy: 'start_time DESC',
      limit: limit,
    );
    
    return maps.map((map) {
      final modifiedMap = Map<String, dynamic>.from(map);
      if (map['result'] != null) {
        modifiedMap['result'] = _deserializeMap(map['result'] as String);
      }
      return AutomationLog.fromMap(modifiedMap);
    }).toList();
  }

  /// Get all logs
  static Future<List<AutomationLog>> getAllLogs({int limit = 100}) async {
    final db = await database;
    final maps = await db.query(
      'automation_logs',
      orderBy: 'start_time DESC',
      limit: limit,
    );
    
    return maps.map((map) {
      final modifiedMap = Map<String, dynamic>.from(map);
      if (map['result'] != null) {
        modifiedMap['result'] = _deserializeMap(map['result'] as String);
      }
      return AutomationLog.fromMap(modifiedMap);
    }).toList();
  }

  /// Clear all data (useful for testing)
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('automation_logs');
    await db.delete('automations');
  }

  /// Get database statistics
  static Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    
    final totalAutomations = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM automations WHERE is_template = 0')
    ) ?? 0;
    
    final activeAutomations = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM automations WHERE is_active = 1 AND is_template = 0')
    ) ?? 0;
    
    final totalLogs = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM automation_logs')
    ) ?? 0;
    
    final successfulRuns = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM automation_logs WHERE status = ?', ['completed'])
    ) ?? 0;
    
    return {
      'totalAutomations': totalAutomations,
      'activeAutomations': activeAutomations,
      'totalLogs': totalLogs,
      'successfulRuns': successfulRuns,
      'failedRuns': totalLogs - successfulRuns,
    };
  }

  /// Helper: Serialize map to JSON string
  static String _serializeMap(Map<String, dynamic> map) {
    return map.entries.map((e) => '${e.key}:${e.value}').join('|');
  }

  /// Helper: Deserialize JSON string to map
  static Map<String, dynamic> _deserializeMap(String serialized) {
    if (serialized.isEmpty) return {};
    
    final map = <String, dynamic>{};
    final pairs = serialized.split('|');
    
    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    
    return map;
  }
}
