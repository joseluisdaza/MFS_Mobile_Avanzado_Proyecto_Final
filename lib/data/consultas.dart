import 'package:carro_2_fin_expo_sqlite/data/sqlite_db.dart';
import 'package:carro_2_fin_expo_sqlite/models/modelo_item.dart';
import 'package:sqflite/sqflite.dart';

class ModeloItemDao {
  final AppDb _appDb;
  static const _table = AppDb.table; // 'productos'

  ModeloItemDao(this._appDb);

  Future<Database> get _db async => _appDb.database;

  Future<ModeloItem> guardar(String nombre) async {
    final db = await _db;
    final id = await db.insert(_table, <String, Object?>{
      'name': nombre,
      'inCart': 0,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
    return ModeloItem(id: id, name: nombre, inCart: false);
  }

  Future<int> eliminar(int id) async {
    final db = await _db;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<ModeloItem?> buscar(int id) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ModeloItem.fromMap(rows.first);
  }

  Future<int> modificarNombre(int id, String nuevoNombre) async {
    final db = await _db;
    final updateMap = <String, Object?>{'name': nuevoNombre};
    return db.update(_table, updateMap, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ModeloItem>> listarTodo({String orderBy = 'id ASC'}) async {
    final db = await _db;
    final rows = await db.query(_table, orderBy: orderBy);
    return rows.map(ModeloItem.fromMap).toList(growable: false);
  }

  Future<List<ModeloItem>> listarFiltrado(
    bool inCart, {
    String orderBy = 'name COLLATE NOCASE ASC',
  }) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'inCart = ?',
      whereArgs: [inCart ? 1 : 0],
      orderBy: orderBy,
    );
    return rows.map(ModeloItem.fromMap).toList(growable: false);
  }
}
