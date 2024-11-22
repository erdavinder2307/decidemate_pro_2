import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

// Initialize the database factory for sqflite_common_ffi
void initializeDatabaseFactory() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

// ...existing code...

class FirebaseService {
  // ...existing code...

  Future<Database> _getDatabase() async {
    initializeDatabaseFactory(); // Ensure the database factory is initialized

    // Ensure the database directory exists
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'choices_database.db');
        //await deleteAndRecreateDatabase();
    if (!await Directory(directory.path).exists()) {
      await Directory(directory.path).create(recursive: true);
    }

    return openDatabase(
      path,
      onCreate: (db, version) {
        db.execute(
          "CREATE TABLE decisions(id TEXT PRIMARY KEY, chooseFor TEXT, count INTEGER DEFAULT 0)",
        );
        db.execute(
          "CREATE TABLE choices(id TEXT PRIMARY KEY, choice TEXT, decisionId TEXT, FOREIGN KEY(decisionId) REFERENCES decisions(id))",
        );
        db.execute(
          "CREATE TABLE results(id TEXT PRIMARY KEY, decisionId TEXT, choiceId TEXT, FOREIGN KEY(decisionId) REFERENCES decisions(id), FOREIGN KEY(choiceId) REFERENCES choices(id))",
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "CREATE TABLE results(id TEXT PRIMARY KEY, decisionId TEXT, choiceId TEXT, FOREIGN KEY(decisionId) REFERENCES decisions(id), FOREIGN KEY(choiceId) REFERENCES choices(id))",
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE decisions ADD COLUMN count INTEGER DEFAULT 0",
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            "ALTER TABLE choices ADD COLUMN decisionId TEXT",
          );
        }
      },
      version: 4, // Increment the version number
    );
  }

  Future<void> insertDecision(String id, String chooseFor) async {
    final Database db = await _getDatabase();
    await db.insert(
      'decisions',
      {'id': id, 'chooseFor': chooseFor, 'count': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertChoices(String decisionId, List<String> choices) async {
    final Database db = await _getDatabase();
    for (var choice in choices) {
      await db.insert(
        'choices',
        {'id': Uuid().v4(), 'choice': choice, 'decisionId': decisionId},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> incrementDecisionCount(String id) async {
    final Database db = await _getDatabase();
    await db.rawUpdate(
      'UPDATE decisions SET count = count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<List<Map<String, dynamic>>> getDecisions() async {
    final Database db = await _getDatabase();
    return await db.query('decisions');
  }

  Future<void> deleteDecision(String id) async {
    final Database db = await _getDatabase();
    await db.delete(
      'decisions',
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'choices',
      where: 'decisionId = ?',
      whereArgs: [id],
    );
    await db.delete(
      'results',
      where: 'decisionId = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateChoices(String decisionId, List<String> choices) async {
    final Database db = await _getDatabase();
    await db.delete(
      'choices',
      where: 'decisionId = ?',
      whereArgs: [decisionId],
    );
    for (var choice in choices) {
      await db.insert(
        'choices',
        {'id': Uuid().v4(), 'choice': choice, 'decisionId': decisionId},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getChoicesFor(String decisionId) async {
    final Database db = await _getDatabase();
    return await db.query(
      'choices',
      where: 'decisionId = ?',
      whereArgs: [decisionId],
    );
  }

  Future<void> insertResult(String id, String decisionId, String choiceId) async {
    final Database db = await _getDatabase();
    await db.insert(
      'results',
      {'id': id, 'decisionId': decisionId, 'choiceId': choiceId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getResultsFor(String decisionId) async {
    final Database db = await _getDatabase();
    return await db.query(
      'results',
      where: 'decisionId = ?',
      whereArgs: [decisionId],
    );
  }

  Future<void> clearResultsFor(String decisionId) async {
    final Database db = await _getDatabase();
    await db.delete(
      'results',
      where: 'decisionId = ?',
      whereArgs: [decisionId],
    );
  }

  Future<List<Map<String, dynamic>>> getDecisionsWithCounts() async {
    final Database db = await _getDatabase();
    return await db.rawQuery('''
      SELECT id, chooseFor, COUNT(*) as count
      FROM decisions
      GROUP BY id, chooseFor
    ''');
  }

  Future<void> clearDatabase() async {
    await deleteAndRecreateDatabase();
    final Database db = await _getDatabase();
    try {
      await db.delete('decisions');
    } catch (e) {
      print('Error deleting decisions table: $e');
    }
    try {
      await db.delete('choices');
    } catch (e) {
      print('Error deleting choices table: $e');
    }
    try {
      await db.delete('results');
    } catch (e) {
      print('Error deleting results table: $e');
    }
    
    // Recreate tables
    await db.execute(
      "CREATE TABLE IF NOT EXISTS decisions(id TEXT PRIMARY KEY, chooseFor TEXT, count INTEGER DEFAULT 0)",
    );
    await db.execute(
      "CREATE TABLE IF NOT EXISTS choices(id TEXT PRIMARY KEY, choice TEXT, decisionId TEXT, FOREIGN KEY(decisionId) REFERENCES decisions(id))",
    );
    await db.execute(
      "CREATE TABLE IF NOT EXISTS results(id TEXT PRIMARY KEY, decisionId TEXT, choiceId TEXT, FOREIGN KEY(decisionId) REFERENCES decisions(id), FOREIGN KEY(choiceId) REFERENCES choices(id))",
    );
  }

  Future<void> deleteAndRecreateDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'choices_database.db');
    
    // Delete the database file
    if (await File(path).exists()) {
      await File(path).delete();
    }

    // Recreate the database
    await _getDatabase();
  }

  Future<void> updateDecision(String id, String chooseFor) async {
    final Database db = await _getDatabase();
    await db.update(
      'decisions',
      {'chooseFor': chooseFor},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
