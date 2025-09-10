import 'package:carro_2_fin_expo_sqlite/data/sqlite_db.dart';
import 'package:carro_2_fin_expo_sqlite/models/modelo_item.dart';
import 'package:sqflite/sqflite.dart';

class ModeloItemDao {
  final AppDb _appDb;
  static const _table = AppDb.table; // 'productos'

  ModeloItemDao(this._appDb);

  Future<Database> get _db async => _appDb.database;

  Future<ModeloItem> guardar(String nombre, int quantity, double price) async {
    final db = await _db;
    final id = await db.insert(_table, <String, Object?>{
      'name': nombre,
      'inCart': 0,
      'quantity': quantity < 0 ? 0 : quantity,
      'price': price < 0 ? 0.0 : price,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
    return ModeloItem(
      id: id,
      name: nombre,
      inCart: false,
      quantity: quantity,
      price: price,
    );
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

  Future<int> modificarCantidad(int id, int nuevaCantidad) async {
    final db = await _db;
    final updateMap = <String, Object?>{
      'quantity': nuevaCantidad < 0 ? 0 : nuevaCantidad,
    };
    return db.update(_table, updateMap, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> modificarPrecio(int id, double nuevoPrecio) async {
    final db = await _db;
    final updateMap = <String, Object?>{
      'price': nuevoPrecio < 0 ? 0.0 : nuevoPrecio,
    };
    return db.update(_table, updateMap, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ModeloItem>> listarTodo({String orderBy = 'id ASC'}) async {
    final db = await _db;
    final rows = await db.query(_table, orderBy: orderBy);
    return rows.map(ModeloItem.fromMap).toList(growable: false);
  }

  //Listar en el carrito
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

  Future<List<ModeloItem>> buscarPorNombre(
    String filtro, {
    String orderBy = 'name COLLATE NOCASE ASC',
  }) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'name LIKE ?',
      whereArgs: ['%$filtro%'],
      orderBy: orderBy,
    );
    return rows.map(ModeloItem.fromMap).toList(growable: false);
  }

  Future<List<ModeloItem>> buscarPorPrecio(
    double min,
    double max, {
    String orderBy = 'price ASC',
  }) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'price BETWEEN ? AND ?',
      whereArgs: [min, max],
      orderBy: orderBy,
    );
    return rows.map(ModeloItem.fromMap).toList(growable: false);
  }
}
