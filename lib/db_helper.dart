
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    if (kIsWeb) {
      throw UnsupportedError('sqflite is not supported on web');
    }
    final docsDir = await getApplicationDocumentsDirectory();
    final path = join(docsDir.path, 'kelime_defteri.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE lists(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            list_id INTEGER NOT NULL,
            word TEXT NOT NULL,
            meaning TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> createList(String name) async {
    final db = await database;
    return await db.insert('lists', {'name': name});
  }

  Future<List<Map<String, dynamic>>> getLists() async {
    final db = await database;
    return await db.query('lists', orderBy: 'id DESC');
  }

  Future<int> deleteList(int id) async {
    final db = await database;
    // delete items first
    await db.delete('items', where: 'list_id = ?', whereArgs: [id]);
    return await db.delete('lists', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addItem(int listId, String word, String meaning) async {
    final db = await database;
    return await db.insert('items', {
      'list_id': listId,
      'word': word,
      'meaning': meaning,
    });
  }

  Future<bool> itemExists(int listId, String word) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM items WHERE list_id = ? AND LOWER(word) = LOWER(?)',
      [listId, word],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  Future<List<Map<String, dynamic>>> getItems(int listId) async {
    final db = await database;
    return await db.query(
      'items',
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'id DESC',
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}
