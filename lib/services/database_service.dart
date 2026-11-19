import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/analytics_event.dart';
import '../models/journal_entry.dart';
import '../models/user_account.dart';

/// Single source of truth database service managing SQLite operations
/// using sqflite_common_ffi databaseFactory across all non-web platforms.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static Database? _database;
  static Future<Database>? _initFuture;
  static bool _isFactoryInitialized = false;
  static String? _customDatabasePath;

  /// Sets an override database path (e.g. `inMemoryDatabasePath` or a unique temp path)
  /// to guarantee test isolation and eliminate SQLite file locks during concurrent test runs.
  static void setCustomDatabasePath(String? path) {
    _customDatabasePath = path;
  }

  /// Closes and resets the database singleton for test harness execution.
  static Future<void> resetForTesting({String? dbPath}) async {
    await instance.close();
    _customDatabasePath = dbPath;
    _initFuture = null;
    _database = null;
  }

  /// Ensures SQLite databaseFactory is initialized cross-platform BEFORE any DB calls.
  static void initializeFactory() {
    if (_isFactoryInitialized) return;
    if (kIsWeb) {
      // Web: sqflite web factory backed by sqlite3.wasm + IndexedDB persistence.
      // Requires the web assets installed via:
      //   flutter pub run sqflite_common_ffi_web:setup
      // (installs sqlite3.wasm and sqflite_sw.js into the web/ folder).
      databaseFactory = databaseFactoryFfiWeb;
    } else {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _isFactoryInitialized = true;
  }

  /// Returns the singleton SQLite Database instance safely avoiding duplicate async initialization.
  Future<Database> get database async {
    initializeFactory();
    if (_database != null && _database!.isOpen) return _database!;
    _initFuture ??= _initDatabase();
    _database = await _initFuture;
    return _database!;
  }

  /// Initializes the SQLite database cross-platform using databaseFactory.
  Future<Database> _initDatabase() async {
    try {
      initializeFactory();

      final String path;
      if (_customDatabasePath != null) {
        path = _customDatabasePath!;
      } else if (kIsWeb) {
        // Web: there is no real filesystem; use a plain database name as the
        // IndexedDB key (matching the sqflite_common_ffi_web recommendation).
        path = 'cognitive_gym.db';
      } else {
        final dbPath = await databaseFactory.getDatabasesPath();
        path = join(dbPath, 'cognitive_gym.db');
      }

      return await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } catch (e) {
      _initFuture = null;
      _database = null;
      rethrow;
    }
  }

  /// Creates database schema tables.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        profileImage TEXT,
        totalXP INTEGER DEFAULT 0,
        creativityPoints INTEGER DEFAULT 0,
        observationPoints INTEGER DEFAULT 0,
        logicPoints INTEGER DEFAULT 0,
        decisionMakingPoints INTEGER DEFAULT 0,
        knowledgePoints INTEGER DEFAULT 0,
        exercisesCompleted INTEGER DEFAULT 0,
        treeStage INTEGER DEFAULT 1,
        currentRank TEXT DEFAULT 'Forest Sage',
        createdAt TEXT NOT NULL
      )
    ''');

    await _createAnalyticsEventsTable(db);
    await _createJournalEntriesTable(db);
  }

  /// Handles schema migration on version upgrade.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createAnalyticsEventsTable(db);
    }
    if (oldVersion < 3) {
      // Safe, idempotent column additions for v3 schema upgrade
      try {
        await db.execute('ALTER TABLE analytics_events ADD COLUMN criticalThinkingDelta INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE analytics_events ADD COLUMN memoryDelta INTEGER DEFAULT 0');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      await _createJournalEntriesTable(db);
    }
  }

  Future<void> _createJournalEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_entries (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        moodEmoji TEXT NOT NULL,
        moodLabel TEXT NOT NULL,
        entryText TEXT NOT NULL,
        category TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_journal_user_created 
      ON journal_entries (userId, createdAt DESC)
    ''');
  }

  Future<void> _createAnalyticsEventsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS analytics_events (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        exerciseType TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        xpEarned INTEGER NOT NULL,
        score REAL DEFAULT 1.0,
        accuracy REAL DEFAULT 1.0,
        durationSeconds INTEGER DEFAULT 60,
        criticalThinkingDelta INTEGER DEFAULT 0,
        memoryDelta INTEGER DEFAULT 0,
        creativityDelta INTEGER DEFAULT 0,
        observationDelta INTEGER DEFAULT 0,
        logicDelta INTEGER DEFAULT 0,
        decisionMakingDelta INTEGER DEFAULT 0,
        knowledgeDelta INTEGER DEFAULT 0
      )
    ''');
  }

  /// Inserts a new user account into SQLite database.
  Future<int> insertUser(UserAccount user) async {
    final db = await database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Updates an existing user account in SQLite.
  Future<int> updateUser(UserAccount user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Fetches user account by unique user ID.
  Future<UserAccount?> getUserById(String id) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return UserAccount.fromMap(results.first);
    }
    return null;
  }

  /// Fetches user by Email or Username (used for Login).
  Future<UserAccount?> getUserByEmailOrUsername(String identifier) async {
    final db = await database;
    final lowerIdentifier = identifier.trim().toLowerCase();

    final results = await db.query(
      'users',
      where: 'LOWER(email) = ? OR LOWER(username) = ?',
      whereArgs: [lowerIdentifier, lowerIdentifier],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return UserAccount.fromMap(results.first);
    }
    return null;
  }

  /// Checks if username is already registered.
  Future<bool> isUsernameTaken(String username, {String? excludeUserId}) async {
    final db = await database;
    final lowerUsername = username.trim().toLowerCase();

    final results = await db.query(
      'users',
      where: excludeUserId != null
          ? 'LOWER(username) = ? AND id != ?'
          : 'LOWER(username) = ?',
      whereArgs: excludeUserId != null
          ? [lowerUsername, excludeUserId]
          : [lowerUsername],
      limit: 1,
    );

    return results.isNotEmpty;
  }

  /// Checks if email address is already registered.
  Future<bool> isEmailTaken(String email, {String? excludeUserId}) async {
    final db = await database;
    final lowerEmail = email.trim().toLowerCase();

    final results = await db.query(
      'users',
      where: excludeUserId != null
          ? 'LOWER(email) = ? AND id != ?'
          : 'LOWER(email) = ?',
      whereArgs: excludeUserId != null
          ? [lowerEmail, excludeUserId]
          : [lowerEmail],
      limit: 1,
    );

    return results.isNotEmpty;
  }

  /// Returns total count of registered accounts in SQLite.
  Future<int> getUsersCount() async {
    final db = await database;
    final results = await db.rawQuery('SELECT COUNT(*) FROM users');
    return _firstIntValue(results) ?? 0;
  }

  int? _firstIntValue(List<Map<String, Object?>> list) {
    if (list.isNotEmpty && list.first.isNotEmpty) {
      final value = list.first.values.first;
      if (value is int) return value;
      if (value is num) return value.toInt();
    }
    return null;
  }

  /// Deletes all records from users table (for test reset).
  Future<void> clearAllUsers() async {
    final db = await database;
    await db.delete('users');
  }

  // ===========================================================================
  // ANALYTICS EVENTS CRUD
  // ===========================================================================

  /// Inserts a new analytics exercise event into SQLite database.
  Future<int> insertAnalyticsEvent(AnalyticsEvent event) async {
    final db = await database;
    return await db.insert(
      'analytics_events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all recorded analytics events, optionally filtered by user or date range.
  Future<List<AnalyticsEvent>> getAnalyticsEvents({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (userId != null && userId.isNotEmpty) {
      whereClauses.add('userId = ?');
      whereArgs.add(userId);
    }
    if (startDate != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final results = await db.query(
      'analytics_events',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp ASC',
    );

    return results.map((map) => AnalyticsEvent.fromMap(map)).toList();
  }

  /// Deletes all records from analytics_events table.
  Future<void> clearAllAnalyticsEvents() async {
    final db = await database;
    await db.delete('analytics_events');
  }

  // ==========================================
  // JOURNAL ENTRIES TABLE OPERATIONS
  // ==========================================

  /// Inserts or replaces a journal entry in SQLite.
  Future<int> insertJournalEntry(JournalEntry entry) async {
    final db = await database;
    return await db.insert(
      'journal_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves journal entries for a user, sorted newest first.
  Future<List<JournalEntry>> getJournalEntries({required String userId}) async {
    final db = await database;
    final results = await db.query(
      'journal_entries',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => JournalEntry.fromMap(map)).toList();
  }

  /// Deletes a journal entry by ID.
  Future<int> deleteJournalEntry(String entryId) async {
    final db = await database;
    return await db.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  /// Clears all journal entries (for testing).
  Future<void> clearAllJournalEntries() async {
    final db = await database;
    await db.delete('journal_entries');
  }
  

  /// Closes database connection (mainly for testing cleanup).
  Future<void> close() async {
    try {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
      }
    } catch (_) {}
    _database = null;
    _initFuture = null;
  }
}
