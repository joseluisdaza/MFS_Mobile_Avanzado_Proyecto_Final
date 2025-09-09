import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDb {
  static const _dbName = 'app.db1';
  static const _dbVersion = 1;
  static const table = 'productos';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $table(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            inCart INTEGER NOT NULL DEFAULT 1
          );
        ''');
        await db.execute('CREATE INDEX idx_productos_nombre ON $table(name);');
      },
    );
    return _db!;
  }
}
