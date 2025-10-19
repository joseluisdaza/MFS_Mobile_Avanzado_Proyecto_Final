import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Define the Products table
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BoolColumn get inCart => boolean().withDefault(Constant(false))();
  RealColumn get price => real()();
  TextColumn get description => text()();
  TextColumn get category => text()();
  TextColumn get image => text()();
  IntColumn get shoppingCartQuantity => integer().withDefault(Constant(0))();
}

// Define the Stores table
class Stores extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get location => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Define the Users table (vendedores)
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 1, max: 50)();
  TextColumn get password => text()(); // En producción debería estar hasheada
  TextColumn get fullName => text()();
  TextColumn get role =>
      text().withDefault(Constant('seller'))(); // seller, admin, etc.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Define the StoreInventory table (enlace producto-tienda)
class StoreInventory extends Table {
  IntColumn get storeId => integer().references(Stores, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get availableQuantity => integer().withDefault(Constant(0))();
  DateTimeColumn get lastUpdated =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {storeId, productId}; // Llave compuesta
}

// Define the PurchaseHistory table (historial de compras)
class PurchaseHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get purchaseId => text().unique()(); // ID único de la compra
  DateTimeColumn get purchaseDate =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get customerId => integer()
      .nullable()(); // Usuario que compra (puede ser null para compras anónimas)
  IntColumn get sellerId =>
      integer().references(Users, #id)(); // Vendedor que procesó la venta
  IntColumn get storeId =>
      integer().references(Stores, #id)(); // Tienda donde se realizó la compra
  RealColumn get totalAmount => real()();
}

// Define the PurchaseItems table (items individuales de cada compra)
class PurchaseItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseHistoryId =>
      integer().references(PurchaseHistory, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
}

// Database class
@DriftDatabase(
  tables: [
    Products,
    Stores,
    Users,
    StoreInventory,
    PurchaseHistory,
    PurchaseItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from == 1) {
        // Migración de versión 1 a 2: agregar nuevas tablas
        await migrator.createTable(stores);
        await migrator.createTable(users);
        await migrator.createTable(storeInventory);
        await migrator.createTable(purchaseHistory);
        await migrator.createTable(purchaseItems);
      }
    },
  );

  // CRUD Operations
  Future<List<Product>> getAllProducts() => select(products).get();

  Future<int> insertProduct(ProductsCompanion product) =>
      into(products).insert(product);

  Future<bool> updateProduct(Product product) =>
      update(products).replace(product);

  Future<int> deleteProduct(int id) =>
      (delete(products)..where((p) => p.id.equals(id))).go();

  // Additional methods for cart functionality
  Future<List<Product>> getCartProducts() =>
      (select(products)..where((p) => p.inCart.equals(true))).get();

  Future<List<Product>> getAvailableProducts() =>
      select(products).get(); // Now availability is managed by store inventory

  // === STORES CRUD ===
  Future<List<Store>> getAllStores() => select(stores).get();

  Future<int> insertStore(StoresCompanion store) => into(stores).insert(store);

  Future<bool> updateStore(Store store) => update(stores).replace(store);

  Future<int> deleteStore(int id) =>
      (delete(stores)..where((s) => s.id.equals(id))).go();

  // === USERS CRUD ===
  Future<List<User>> getAllUsers() => select(users).get();

  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);

  Future<bool> updateUser(User user) => update(users).replace(user);

  Future<int> deleteUser(int id) =>
      (delete(users)..where((u) => u.id.equals(id))).go();

  Future<User?> getUserByUsername(String username) => (select(
    users,
  )..where((u) => u.username.equals(username))).getSingleOrNull();

  // === STORE INVENTORY CRUD ===
  Future<List<StoreInventoryData>> getInventoryByStore(int storeId) =>
      (select(storeInventory)..where((si) => si.storeId.equals(storeId))).get();

  Future<List<StoreInventoryData>> getInventoryByProduct(int productId) =>
      (select(
        storeInventory,
      )..where((si) => si.productId.equals(productId))).get();

  Future<int> insertStoreInventory(StoreInventoryCompanion inventory) =>
      into(storeInventory).insert(inventory);

  Future<bool> updateStoreInventory(StoreInventoryData inventory) =>
      update(storeInventory).replace(inventory);

  Future<int> updateInventoryQuantity(
    int storeId,
    int productId,
    int newQuantity,
  ) =>
      (update(storeInventory)..where(
            (si) => si.storeId.equals(storeId) & si.productId.equals(productId),
          ))
          .write(
            StoreInventoryCompanion(availableQuantity: Value(newQuantity)),
          );

  // Crear inventario inicial para un producto en todas las tiendas
  Future<void> createInitialInventoryForProduct(int productId) async {
    final stores = await getAllStores();
    for (final store in stores) {
      await insertStoreInventory(
        StoreInventoryCompanion(
          storeId: Value(store.id),
          productId: Value(productId),
          availableQuantity: const Value(0),
        ),
      );
    }
  }

  // Obtener inventario de un producto por tienda específica
  Future<StoreInventoryData?> getProductInventoryInStore(
    int productId,
    int storeId,
  ) async {
    final result =
        await (select(storeInventory)..where(
              (si) =>
                  si.productId.equals(productId) & si.storeId.equals(storeId),
            ))
            .getSingleOrNull();
    return result;
  }

  // === PURCHASE HISTORY CRUD ===
  Future<List<PurchaseHistoryData>> getAllPurchases() =>
      select(purchaseHistory).get();

  Future<List<PurchaseHistoryData>> getPurchasesByStore(int storeId) => (select(
    purchaseHistory,
  )..where((ph) => ph.storeId.equals(storeId))).get();

  Future<List<PurchaseHistoryData>> getPurchasesBySeller(int sellerId) =>
      (select(
        purchaseHistory,
      )..where((ph) => ph.sellerId.equals(sellerId))).get();

  Future<int> insertPurchaseHistory(PurchaseHistoryCompanion purchase) =>
      into(purchaseHistory).insert(purchase);

  // === PURCHASE ITEMS CRUD ===
  Future<List<PurchaseItem>> getPurchaseItems(int purchaseHistoryId) => (select(
    purchaseItems,
  )..where((pi) => pi.purchaseHistoryId.equals(purchaseHistoryId))).get();

  Future<int> insertPurchaseItem(PurchaseItemsCompanion item) =>
      into(purchaseItems).insert(item);

  // === COMPLEX QUERIES ===

  // Obtener productos con su inventario por tienda
  Future<List<Map<String, dynamic>>> getProductsWithStoreInventory(
    int storeId,
  ) async {
    final query = select(products).join([
      leftOuterJoin(
        storeInventory,
        storeInventory.productId.equalsExp(products.id) &
            storeInventory.storeId.equals(storeId),
      ),
    ]);

    final results = await query.get();
    return results.map((row) {
      final product = row.readTable(products);
      final inventory = row.readTableOrNull(storeInventory);

      return {
        'product': product,
        'storeQuantity': inventory?.availableQuantity ?? 0,
        'hasInventory': inventory != null,
      };
    }).toList();
  }

  // Procesar una compra completa
  Future<String> processPurchase({
    required int storeId,
    required int sellerId,
    required List<Map<String, dynamic>>
    items, // {productId: int, quantity: int, unitPrice: double}
    int? customerId,
  }) async {
    return await transaction(() async {
      // Generar ID único de compra
      final purchaseId = 'PUR_${DateTime.now().millisecondsSinceEpoch}';

      // Calcular total
      double totalAmount = 0;
      for (final item in items) {
        totalAmount +=
            (item['quantity'] as int) * (item['unitPrice'] as double);
      }

      // Insertar historial de compra
      final purchaseHistoryId = await into(purchaseHistory).insert(
        PurchaseHistoryCompanion(
          purchaseId: Value(purchaseId),
          customerId: Value(customerId),
          sellerId: Value(sellerId),
          storeId: Value(storeId),
          totalAmount: Value(totalAmount),
        ),
      );

      // Insertar items de la compra y actualizar inventario
      for (final item in items) {
        final productId = item['productId'] as int;
        final quantity = item['quantity'] as int;
        final unitPrice = item['unitPrice'] as double;

        // Insertar item de compra
        await into(purchaseItems).insert(
          PurchaseItemsCompanion(
            purchaseHistoryId: Value(purchaseHistoryId),
            productId: Value(productId),
            quantity: Value(quantity),
            unitPrice: Value(unitPrice),
            totalPrice: Value(quantity * unitPrice),
          ),
        );

        // Reducir inventario de la tienda
        // Primero obtenemos la cantidad actual
        final currentInventory =
            await (select(storeInventory)..where(
                  (si) =>
                      si.storeId.equals(storeId) &
                      si.productId.equals(productId),
                ))
                .getSingleOrNull();

        if (currentInventory != null) {
          final newQuantity = currentInventory.availableQuantity - quantity;
          await (update(storeInventory)..where(
                (si) =>
                    si.storeId.equals(storeId) & si.productId.equals(productId),
              ))
              .write(
                StoreInventoryCompanion(
                  availableQuantity: Value(newQuantity >= 0 ? newQuantity : 0),
                ),
              );
        }
      }

      return purchaseId;
    });
  }

  // === MÉTODOS DE INICIALIZACIÓN ===

  Future<void> initializeDefaultData() async {
    // Verificar si ya hay datos
    final storeCount = await (selectOnly(
      stores,
    )..addColumns([stores.id.count()])).getSingle();

    if (storeCount.read(stores.id.count()) == 0) {
      // Crear tiendas por defecto
      final store1Id = await insertStore(
        StoresCompanion.insert(
          name: 'Tienda Centro',
          location: 'Centro Comercial Cala Cala',
        ),
      );

      final store2Id = await insertStore(
        StoresCompanion.insert(
          name: 'Tienda Norte',
          location: 'Zona Norte - Av. Libertador 123',
        ),
      );

      // Crear usuario vendedor por defecto
      await insertUser(
        UsersCompanion.insert(
          username: 'admin',
          password: '123456', // En producción debería estar hasheada
          fullName: 'Administrador del Sistema',
          role: const Value('admin'),
        ),
      );

      await insertUser(
        UsersCompanion.insert(
          username: 'vendedor1',
          password: '123456',
          fullName: 'Juan Pérez',
          role: const Value('seller'),
        ),
      );

      // Si hay productos existentes, crear inventario inicial para ambas tiendas
      final products = await getAllProducts();
      for (final product in products) {
        // Inventario para tienda sur (cantidad inicial fija)
        await insertStoreInventory(
          StoreInventoryCompanion.insert(
            storeId: store1Id,
            productId: product.id,
            availableQuantity: const Value(15), // Cantidad inicial fija
          ),
        );

        // Inventario para tienda norte (cantidad inicial fija)
        await insertStoreInventory(
          StoreInventoryCompanion.insert(
            storeId: store2Id,
            productId: product.id,
            availableQuantity: const Value(10), // Cantidad inicial fija
          ),
        );
      }
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'products.db'));
    return NativeDatabase.createInBackground(file);
  });
}
