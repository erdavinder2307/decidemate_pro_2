import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
        return db.execute(
          "CREATE TABLE choices(id INTEGER PRIMARY KEY, chooseFor TEXT, choice TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<void> insertChoice(String chooseFor, String choice) async {
    final Database db = await _getDatabase();
    await db.insert(
      'choices',
      {'chooseFor': chooseFor, 'choice': choice},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertChoices(String chooseFor, List<String> choices) async {
    final Database db = await _getDatabase();
    for (var choice in choices) {
      await db.insert(
        'choices',
        {'chooseFor': chooseFor, 'choice': choice},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getChooseForItems() async {
    final Database db = await _getDatabase();
    return await db.query('choices', distinct: true, columns: ['chooseFor']);
  }
}
