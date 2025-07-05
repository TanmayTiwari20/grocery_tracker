import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/grocery_item.dart';

class GroceryDatabase {
  static final GroceryDatabase instance = GroceryDatabase._init();
  static Database? _database;

  GroceryDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('grocery.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<Database> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE groceries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      quantity TEXT NOT NULL,
      expiry_date TEXT NOT NULL,
      added_on TEXT NOT NULL
    )
    ''');
    return db;
  }

  Future<GroceryItem> insert(GroceryItem item) async {
    final db = await instance.database;
    final id = await db.insert('groceries', item.toMap());
    return item.copyWith(id: id);
  }

  Future<List<GroceryItem>> getAllItems({bool sortByExpiry = true}) async {
    final db = await instance.database;
    final orderBy = sortByExpiry ? 'expiry_date ASC' : 'added_on DESC';
    final result = await db.query('groceries', orderBy: orderBy);
    return result.map((map) => GroceryItem.fromMap(map)).toList();
  }

  Future<int> updateItem(GroceryItem item) async {
    final db = await instance.database;
    return db.update(
      'groceries',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return db.delete('groceries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await instance.database;
    await db.delete('groceries', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
