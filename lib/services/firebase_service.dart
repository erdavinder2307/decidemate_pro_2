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
    if (!await Directory(directory.path).exists()) {
      await Directory(directory.path).create(recursive: true);
    }

    return openDatabase(
      path,
      onCreate: (db, version) {
        db.execute(
          "CREATE TABLE decisions(id TEXT PRIMARY KEY, chooseFor TEXT, count INTEGER DEFAULT 0, category TEXT)",
        );
        db.execute(
          "CREATE TABLE choices(id TEXT PRIMARY KEY, choice TEXT, decisionId TEXT, FOREIGN KEY(decisionId) REFERENCES decisions(id))",
        );
        db.execute(
          "CREATE TABLE results(id TEXT PRIMARY KEY, decisionId TEXT, choiceId TEXT, timestamp TEXT NOT NULL, FOREIGN KEY(decisionId) REFERENCES decisions(id), FOREIGN KEY(choiceId) REFERENCES choices(id))",
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "CREATE TABLE results(id TEXT PRIMARY KEY, decisionId TEXT, choiceId TEXT, timestamp TEXT NOT NULL, FOREIGN KEY(decisionId) REFERENCES decisions(id), FOREIGN KEY(choiceId) REFERENCES choices(id))",
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
        if (oldVersion < 5) {
          await db.execute(
            "ALTER TABLE results ADD COLUMN timestamp TEXT NOT NULL",
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            "ALTER TABLE decisions ADD COLUMN category TEXT",
          );
        }
      },
      version: 6, // Increment the version number
    );
  }

  Future<void> insertDecision(String id, String chooseFor, {String? category}) async {
    final Database db = await _getDatabase();
    await db.insert(
      'decisions',
      {'id': id, 'chooseFor': chooseFor ?? '', 'count': 0, 'category': category},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertChoices(String decisionId, List<String> choices) async {
    final Database db = await _getDatabase();
    for (var choice in choices) {
      await db.insert(
        'choices',
        {'id': Uuid().v4(), 'choice': choice ?? '', 'decisionId': decisionId},
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
      {
        'id': id,
        'decisionId': decisionId,
        'choiceId': choiceId,
        'timestamp': DateTime.now().toIso8601String()
      },
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
      "CREATE TABLE IF NOT EXISTS decisions(id TEXT PRIMARY KEY, chooseFor TEXT, count INTEGER DEFAULT 0, category TEXT)",
    );
    await db.execute(
      "CREATE TABLE IF NOT EXISTS choices(id TEXT PRIMARY KEY, choice TEXT, decisionId TEXT, FOREIGN KEY(decisionId) REFERENCES decisions(id))",
    );
    await db.execute(
      "CREATE TABLE IF NOT EXISTS results(id TEXT PRIMARY KEY, decisionId TEXT, choiceId TEXT, timestamp TEXT NOT NULL, FOREIGN KEY(decisionId) REFERENCES decisions(id), FOREIGN KEY(choiceId) REFERENCES choices(id))",
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

  Future<void> updateDecision(String id, String chooseFor, {String? category}) async {
    final Database db = await _getDatabase();
    await db.update(
      'decisions',
      {'chooseFor': chooseFor ?? '', 'category': category},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getDecisionHistory() async {
    final Database db = await _getDatabase();
    return await db.rawQuery('''
      SELECT decisions.chooseFor, results.choiceId, results.timestamp
      FROM decisions
      LEFT JOIN results ON decisions.id = results.decisionId
      GROUP BY decisions.chooseFor
      ORDER BY results.timestamp DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getSpinHistory() async {
    final Database db = await _getDatabase();
    return await db.rawQuery('''
      SELECT decisions.chooseFor, results.choiceId, results.timestamp
      FROM decisions
      INNER JOIN results ON decisions.id = results.decisionId
      ORDER BY results.timestamp DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getDecisionHistoryWithCounts() async {
    final Database db = await _getDatabase();
    return await db.rawQuery('''
      SELECT decisions.chooseFor, results.choiceId, results.timestamp, COUNT(results.id) as count
      FROM decisions
      LEFT JOIN results ON decisions.id = results.decisionId
      GROUP BY decisions.chooseFor, results.choiceId, results.timestamp
      ORDER BY results.timestamp DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getLastThreeSpinResults() async {
    final Database db = await _getDatabase();
    return await db.rawQuery('''
      SELECT decisions.*
      FROM decisions
      INNER JOIN results ON decisions.id = results.decisionId
      ORDER BY results.timestamp DESC
      LIMIT 3
    ''');
  }

  Future<Map<String, dynamic>?> getRandomResultFromLastThree() async {
    final results = await getLastThreeSpinResults();
    if (results.isNotEmpty) {
      final mutableResults = List<Map<String, dynamic>>.from(results);
      mutableResults.shuffle();
      return mutableResults.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getFilteredSpinHistory({String? searchQuery, String? timeRange, String? category}) async {
    final Database db = await _getDatabase();
    String whereClause = "";
    List<String> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += " AND (decisions.chooseFor LIKE ? OR results.choiceId LIKE ?)";
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
    }

    if (timeRange != null) {
      DateTime now = DateTime.now();
      DateTime startDate;

      switch (timeRange) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'This Week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'Last Month':
          startDate = DateTime(now.year, now.month - 1, 1);
          break;
        default:
          startDate = DateTime(1970);
      }

      whereClause += " AND results.timestamp >= ?";
      whereArgs.add(startDate.toIso8601String());
    }

    if (category != null && category.isNotEmpty) {
      whereClause += " AND decisions.category = ?";
      whereArgs.add(category);
    }

    return await db.rawQuery('''
      SELECT decisions.id as decisionId,choices.choice, decisions.chooseFor, results.choiceId, results.timestamp, decisions.category
      FROM decisions
      INNER JOIN results ON decisions.id = results.decisionId
      INNER JOIN choices ON results.choiceId = choices.id
      $whereClause
      ORDER BY results.timestamp DESC
    ''', whereArgs);
  }

  Future<Map<String, dynamic>?> getChoiceWithHighestCount(String decisionId) async {
    final Database db = await _getDatabase();
    final result = await db.rawQuery('''
      SELECT choices.choice, COUNT(results.choiceId) as count
      FROM results
      INNER JOIN choices ON results.choiceId = choices.id
      WHERE results.decisionId = ?
      GROUP BY results.choiceId
      ORDER BY count DESC
      LIMIT 1
    ''', [decisionId]);

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getChoiceWithRecentResult(String decisionId) async {
    final Database db = await _getDatabase();
    final result = await db.rawQuery('''
      SELECT choices.choice, results.timestamp
      FROM results
      INNER JOIN choices ON results.choiceId = choices.id
      WHERE results.decisionId = ?
      ORDER BY results.timestamp DESC
      LIMIT 1
    ''', [decisionId]);

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getSpinFrequencyByList() async {
    final Database db = await _getDatabase();
    return await db.rawQuery('''
      SELECT decisions.chooseFor AS list_name, COUNT(results.id) AS spin_count
      FROM results
      INNER JOIN decisions ON results.decisionId = decisions.id
      GROUP BY decisions.chooseFor
    ''');
  }

  Future<List<Map<String, dynamic>>> getOutcomeDistribution(String listName) async {
    final Database db = await _getDatabase();
    return await db.rawQuery('''
      SELECT choices.choice AS outcome, COUNT(results.id) AS count
      FROM results
      INNER JOIN choices ON results.choiceId = choices.id
      INNER JOIN decisions ON results.decisionId = decisions.id
      WHERE decisions.chooseFor = ?
      GROUP BY choices.choice
    ''', [listName]);
  }

  Future<List<Map<String, dynamic>>> getSpinFrequencyTrends() async {
    final Database db = await _getDatabase();
    return await db.rawQuery('''
      SELECT DATE(results.timestamp) AS date, COUNT(results.id) AS spin_count
      FROM results
      GROUP BY DATE(results.timestamp)
    ''');
  }

  Future<Map<String, dynamic>> getKeyMetrics() async {
    final Database db = await _getDatabase();
    final totalSpins = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM results'));
    final mostUsedList = await db.rawQuery('''
      SELECT decisions.chooseFor, COUNT(results.id) AS count
      FROM results
      INNER JOIN decisions ON results.decisionId = decisions.id
      GROUP BY decisions.chooseFor
      ORDER BY count DESC
      LIMIT 1
    ''');
    final mostFrequentOutcome = await db.rawQuery('''
      SELECT choices.choice, COUNT(results.id) AS count
      FROM results
      INNER JOIN choices ON results.choiceId = choices.id
      GROUP BY choices.choice
      ORDER BY count DESC
      LIMIT 1
    ''');
    return {
      'totalSpins': totalSpins,
      'mostUsedList': mostUsedList.isNotEmpty ? mostUsedList.first : null,
      'mostFrequentOutcome': mostFrequentOutcome.isNotEmpty ? mostFrequentOutcome.first : null,
    };
  }
}
