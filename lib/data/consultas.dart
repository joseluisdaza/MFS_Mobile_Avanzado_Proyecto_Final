import 'package:carro_2_fin_expo_sqlite/database/database.dart';
import 'package:carro_2_fin_expo_sqlite/models/modelo_item.dart';
import 'package:drift/drift.dart';

class ModeloItemDao {
  final AppDatabase _appDb;

  ModeloItemDao(this._appDb);

  Future<ModeloItem> guardar(
    String nombre,
    int quantity,
    double price,
    String? description,
    String? category,
    String? image,
    int shoppingCartQuantity,
  ) async {
    final id = await _appDb
        .into(_appDb.products)
        .insert(
          ProductsCompanion(
            name: Value(nombre),
            inCart: const Value(false),
            quantity: Value(quantity < 0 ? 0 : quantity),
            price: Value(price < 0 ? 0.0 : price),
            description: Value(description ?? ''),
            category: Value(category ?? ''),
            image: Value(image ?? ''),
            shoppingCartQuantity: Value(
              shoppingCartQuantity < 0 ? 0 : shoppingCartQuantity,
            ),
          ),
        );

    return ModeloItem(
      id: id,
      name: nombre,
      inCart: false,
      quantity: quantity < 0 ? 0 : quantity,
      price: price < 0 ? 0.0 : price,
      description: description,
      category: category,
      image: image,
      shoppingCartQuantity: shoppingCartQuantity < 0 ? 0 : shoppingCartQuantity,
    );
  }

  Future<int> eliminar(int id) async {
    return (_appDb.delete(_appDb.products)..where((t) => t.id.equals(id))).go();
  }

  Future<ModeloItem?> buscar(int id) async {
    final query = _appDb.select(_appDb.products)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _productToModeloItem(row) : null;
  }

  Future<int> modificar(ModeloItem item) async {
    final companion = ProductsCompanion(
      id: Value(item.id!),
      name: Value(item.name!),
      inCart: Value(item.inCart),
      quantity: Value(item.quantity < 0 ? 0 : item.quantity),
      price: Value(item.price < 0 ? 0.0 : item.price),
      description: Value(item.description ?? ''),
      category: Value(item.category ?? ''),
      image: Value(item.image ?? ''),
      shoppingCartQuantity: Value(
        item.shoppingCartQuantity < 0 ? 0 : item.shoppingCartQuantity,
      ),
    );

    return (_appDb.update(
      _appDb.products,
    )..where((t) => t.id.equals(item.id!))).write(companion);
  }

  Future<int> modificarNombre(int id, String nuevoNombre) async {
    return (_appDb.update(_appDb.products)..where((t) => t.id.equals(id)))
        .write(ProductsCompanion(name: Value(nuevoNombre)));
  }

  Future<int> modificarCantidad(int id, int nuevaCantidad) async {
    return (_appDb.update(
      _appDb.products,
    )..where((t) => t.id.equals(id))).write(
      ProductsCompanion(quantity: Value(nuevaCantidad < 0 ? 0 : nuevaCantidad)),
    );
  }

  Future<int> modificarPrecio(int id, double nuevoPrecio) async {
    return (_appDb.update(
      _appDb.products,
    )..where((t) => t.id.equals(id))).write(
      ProductsCompanion(price: Value(nuevoPrecio < 0 ? 0.0 : nuevoPrecio)),
    );
  }

  Future<int> modificarDescripcion(int id, String? nuevaDescripcion) async {
    return (_appDb.update(_appDb.products)..where((t) => t.id.equals(id)))
        .write(ProductsCompanion(description: Value(nuevaDescripcion ?? '')));
  }

  Future<int> modificarCategoria(int id, String? nuevaCategoria) async {
    return (_appDb.update(_appDb.products)..where((t) => t.id.equals(id)))
        .write(ProductsCompanion(category: Value(nuevaCategoria ?? '')));
  }

  Future<int> modificarImagen(int id, String? nuevaImagen) async {
    return (_appDb.update(_appDb.products)..where((t) => t.id.equals(id)))
        .write(ProductsCompanion(image: Value(nuevaImagen ?? '')));
  }

  Future<int> modificarShoppingCartQuantity(int id, int nuevaCantidad) async {
    return (_appDb.update(
      _appDb.products,
    )..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        shoppingCartQuantity: Value(nuevaCantidad < 0 ? 0 : nuevaCantidad),
      ),
    );
  }

  Future<int> modificarInCart(int id, bool inCart) async {
    return (_appDb.update(_appDb.products)..where((t) => t.id.equals(id)))
        .write(ProductsCompanion(inCart: Value(inCart)));
  }

  Future<List<ModeloItem>> listarTodo({String orderBy = 'id'}) async {
    final query = _appDb.select(_appDb.products);

    switch (orderBy.toLowerCase()) {
      case 'name asc':
      case 'name':
        query.orderBy([(t) => OrderingTerm.asc(t.name)]);
        break;
      case 'name desc':
        query.orderBy([(t) => OrderingTerm.desc(t.name)]);
        break;
      case 'price asc':
      case 'price':
        query.orderBy([(t) => OrderingTerm.asc(t.price)]);
        break;
      case 'price desc':
        query.orderBy([(t) => OrderingTerm.desc(t.price)]);
        break;
      case 'id desc':
        query.orderBy([(t) => OrderingTerm.desc(t.id)]);
        break;
      default: // 'id asc' or 'id'
        query.orderBy([(t) => OrderingTerm.asc(t.id)]);
        break;
    }

    final rows = await query.get();
    return rows.map(_productToModeloItem).toList();
  }

  Future<List<ModeloItem>> listarFiltrado(
    bool inCart, {
    String orderBy = 'name',
  }) async {
    final query = _appDb.select(_appDb.products)
      ..where((t) => t.inCart.equals(inCart));

    switch (orderBy.toLowerCase()) {
      case 'name collate nocase asc':
      case 'name asc':
      case 'name':
        query.orderBy([(t) => OrderingTerm.asc(t.name)]);
        break;
      case 'name desc':
        query.orderBy([(t) => OrderingTerm.desc(t.name)]);
        break;
      case 'price asc':
      case 'price':
        query.orderBy([(t) => OrderingTerm.asc(t.price)]);
        break;
      case 'price desc':
        query.orderBy([(t) => OrderingTerm.desc(t.price)]);
        break;
      default:
        query.orderBy([(t) => OrderingTerm.asc(t.name)]);
        break;
    }

    final rows = await query.get();
    return rows.map(_productToModeloItem).toList();
  }

  Future<List<ModeloItem>> buscarPorNombre(
    String filtro, {
    String orderBy = 'name',
  }) async {
    final query = _appDb.select(_appDb.products)
      ..where((t) => t.name.like('%$filtro%'));

    switch (orderBy.toLowerCase()) {
      case 'name collate nocase asc':
      case 'name asc':
      case 'name':
        query.orderBy([(t) => OrderingTerm.asc(t.name)]);
        break;
      case 'name desc':
        query.orderBy([(t) => OrderingTerm.desc(t.name)]);
        break;
      case 'price asc':
      case 'price':
        query.orderBy([(t) => OrderingTerm.asc(t.price)]);
        break;
      case 'price desc':
        query.orderBy([(t) => OrderingTerm.desc(t.price)]);
        break;
      default:
        query.orderBy([(t) => OrderingTerm.asc(t.name)]);
        break;
    }

    final rows = await query.get();
    return rows.map(_productToModeloItem).toList();
  }

  Future<List<ModeloItem>> buscarPorPrecio(
    double min,
    double max, {
    String orderBy = 'price',
  }) async {
    final query = _appDb.select(_appDb.products)
      ..where((t) => t.price.isBetweenValues(min, max));

    switch (orderBy.toLowerCase()) {
      case 'price asc':
      case 'price':
        query.orderBy([(t) => OrderingTerm.asc(t.price)]);
        break;
      case 'price desc':
        query.orderBy([(t) => OrderingTerm.desc(t.price)]);
        break;
      case 'name asc':
      case 'name':
        query.orderBy([(t) => OrderingTerm.asc(t.name)]);
        break;
      case 'name desc':
        query.orderBy([(t) => OrderingTerm.desc(t.name)]);
        break;
      default:
        query.orderBy([(t) => OrderingTerm.asc(t.price)]);
        break;
    }

    final rows = await query.get();
    return rows.map(_productToModeloItem).toList();
  }

  // Helper method to convert Product (from Drift) to ModeloItem
  ModeloItem _productToModeloItem(Product product) {
    return ModeloItem(
      id: product.id,
      name: product.name,
      inCart: product.inCart,
      quantity: product.quantity,
      price: product.price,
      description: product.description.isEmpty ? null : product.description,
      category: product.category.isEmpty ? null : product.category,
      image: product.image.isEmpty ? null : product.image,
      shoppingCartQuantity: product.shoppingCartQuantity,
    );
  }
}
