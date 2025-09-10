import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDb {
  static const _dbName = 'app.db2';
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
            inCart INTEGER NOT NULL DEFAULT 1,
            quantity INTEGER NOT NULL DEFAULT 0,
            price REAL NOT NULL DEFAULT 0.0
          );
        ''');
        await db.execute('CREATE INDEX idx_productos_nombre ON $table(name);');
        await db.execute('CREATE INDEX idx_productos_precio ON $table(price);');
      },
    );
    return _db!;
  }
}
