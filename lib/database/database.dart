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

  Future<User?> getUserByCredentials(String username, String password) =>
      (select(users)..where(
            (u) => u.username.equals(username) & u.password.equals(password),
          ))
          .getSingleOrNull();

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
    // Verificar si ya hay tiendas
    final storeCount = await (selectOnly(
      stores,
    )..addColumns([stores.id.count()])).getSingle();

    int? store1Id;
    int? store2Id;

    if (storeCount.read(stores.id.count()) == 0) {
      // Crear tiendas por defecto
      store1Id = await insertStore(
        StoresCompanion.insert(
          name: 'Tienda Centro',
          location: 'Centro Comercial Cala Cala',
        ),
      );

      store2Id = await insertStore(
        StoresCompanion.insert(
          name: 'Tienda Norte',
          location: 'Zona Norte - Av. Libertador 123',
        ),
      );
    }

    // Verificar si ya hay usuarios
    final userCount = await (selectOnly(
      users,
    )..addColumns([users.id.count()])).getSingle();

    if (userCount.read(users.id.count()) == 0) {
      print('DEBUG: Creando usuarios de prueba...');

      // Crear usuarios de prueba
      final adminId = await insertUser(
        UsersCompanion.insert(
          username: 'admin',
          password: 'admin123',
          fullName: 'Administrador del Sistema',
          role: const Value('admin'),
        ),
      );
      print('DEBUG: Usuario admin creado con ID: $adminId');

      final managerId = await insertUser(
        UsersCompanion.insert(
          username: 'manager',
          password: 'manager123',
          fullName: 'Gerente de Tienda',
          role: const Value('manager'),
        ),
      );
      print('DEBUG: Usuario manager creado con ID: $managerId');

      final sellerId = await insertUser(
        UsersCompanion.insert(
          username: 'seller',
          password: 'seller123',
          fullName: 'Vendedor de Mostrador',
          role: const Value('seller'),
        ),
      );
      print('DEBUG: Usuario seller creado con ID: $sellerId');

      final vendedorId = await insertUser(
        UsersCompanion.insert(
          username: 'vendedor1',
          password: '123456',
          fullName: 'Juan Pérez',
          role: const Value('seller'),
        ),
      );
      print('DEBUG: Usuario vendedor1 creado con ID: $vendedorId');
      print('DEBUG: Todos los usuarios de prueba creados exitosamente');
    } else {
      print(
        'DEBUG: Los usuarios ya existen, total: ${userCount.read(users.id.count())}',
      );
    }

    // Si se crearon tiendas nuevas y hay productos, crear inventario inicial
    if (store1Id != null && store2Id != null) {
      final products = await getAllProducts();
      for (final product in products) {
        // Inventario para tienda centro (cantidad inicial fija)
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

  // === MÉTODOS DE REPORTES ===

  // Obtener reporte de ventas con filtros
  Future<List<Map<String, dynamic>>> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
    int? storeId,
    int? sellerId,
  }) async {
    // Construir la consulta base
    final query = select(purchaseHistory).join([
      innerJoin(stores, stores.id.equalsExp(purchaseHistory.storeId)),
      innerJoin(users, users.id.equalsExp(purchaseHistory.sellerId)),
    ]);

    // Aplicar filtros
    var conditions = <Expression<bool>>[];

    if (startDate != null) {
      conditions.add(
        purchaseHistory.purchaseDate.isBiggerOrEqualValue(startDate),
      );
    }

    if (endDate != null) {
      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      conditions.add(
        purchaseHistory.purchaseDate.isSmallerOrEqualValue(endOfDay),
      );
    }

    if (storeId != null) {
      conditions.add(purchaseHistory.storeId.equals(storeId));
    }

    if (sellerId != null) {
      conditions.add(purchaseHistory.sellerId.equals(sellerId));
    }

    if (conditions.isNotEmpty) {
      Expression<bool> finalCondition = conditions.first;
      for (int i = 1; i < conditions.length; i++) {
        finalCondition = finalCondition & conditions[i];
      }
      query.where(finalCondition);
    }

    // Ordenar por fecha descendente
    query.orderBy([OrderingTerm.desc(purchaseHistory.purchaseDate)]);

    final results = await query.get();

    final salesData = <Map<String, dynamic>>[];

    for (final row in results) {
      final purchase = row.readTable(purchaseHistory);
      final store = row.readTable(stores);
      final seller = row.readTable(users);

      // Obtener items de la compra
      final items = await getPurchaseItems(purchase.id);
      final itemsWithProducts = <Map<String, dynamic>>[];

      for (final item in items) {
        final product = await (select(
          products,
        )..where((p) => p.id.equals(item.productId))).getSingle();
        itemsWithProducts.add({
          'productName': product.name,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'totalPrice': item.totalPrice,
        });
      }

      salesData.add({
        'purchaseId': purchase.purchaseId,
        'purchaseDate': purchase.purchaseDate,
        'storeName': store.name,
        'sellerName': seller.fullName,
        'totalAmount': purchase.totalAmount,
        'itemsCount': items.length,
        'items': itemsWithProducts,
      });
    }

    return salesData;
  }

  // Obtener resumen de ventas
  Future<Map<String, dynamic>> getSalesSummary({
    DateTime? startDate,
    DateTime? endDate,
    int? storeId,
    int? sellerId,
  }) async {
    // Consulta base para totales
    final query = selectOnly(purchaseHistory);

    // Aplicar los mismos filtros
    var conditions = <Expression<bool>>[];

    if (startDate != null) {
      conditions.add(
        purchaseHistory.purchaseDate.isBiggerOrEqualValue(startDate),
      );
    }

    if (endDate != null) {
      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      conditions.add(
        purchaseHistory.purchaseDate.isSmallerOrEqualValue(endOfDay),
      );
    }

    if (storeId != null) {
      conditions.add(purchaseHistory.storeId.equals(storeId));
    }

    if (sellerId != null) {
      conditions.add(purchaseHistory.sellerId.equals(sellerId));
    }

    if (conditions.isNotEmpty) {
      Expression<bool> finalCondition = conditions.first;
      for (int i = 1; i < conditions.length; i++) {
        finalCondition = finalCondition & conditions[i];
      }
      query.where(finalCondition);
    }

    // Agregar columnas para estadísticas
    query.addColumns([
      purchaseHistory.id.count(),
      purchaseHistory.totalAmount.sum(),
      purchaseHistory.totalAmount.avg(),
    ]);

    final result = await query.getSingle();

    final totalSales = result.read(purchaseHistory.id.count()) ?? 0;
    final totalRevenue = result.read(purchaseHistory.totalAmount.sum()) ?? 0.0;
    final averageTicket = result.read(purchaseHistory.totalAmount.avg()) ?? 0.0;

    // Obtener producto más vendido
    String topProduct = 'N/A';
    int totalItems = 0;

    // Query para obtener producto más vendido
    final productQuery = select(purchaseItems).join([
      innerJoin(products, products.id.equalsExp(purchaseItems.productId)),
      innerJoin(
        purchaseHistory,
        purchaseHistory.id.equalsExp(purchaseItems.purchaseHistoryId),
      ),
    ]);

    if (conditions.isNotEmpty) {
      Expression<bool> finalCondition = conditions.first;
      for (int i = 1; i < conditions.length; i++) {
        finalCondition = finalCondition & conditions[i];
      }
      productQuery.where(finalCondition);
    }

    final productResults = await productQuery.get();
    final productSales = <String, int>{};

    for (final row in productResults) {
      final item = row.readTable(purchaseItems);
      final product = row.readTable(products);

      productSales[product.name] =
          (productSales[product.name] ?? 0) + item.quantity;
      totalItems += item.quantity;
    }

    if (productSales.isNotEmpty) {
      final topEntry = productSales.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      topProduct = topEntry.key;
    }

    // Obtener tienda con más ventas
    String topStore = 'N/A';
    final storeQuery = select(
      purchaseHistory,
    ).join([innerJoin(stores, stores.id.equalsExp(purchaseHistory.storeId))]);

    if (conditions.isNotEmpty) {
      Expression<bool> finalCondition = conditions.first;
      for (int i = 1; i < conditions.length; i++) {
        finalCondition = finalCondition & conditions[i];
      }
      storeQuery.where(finalCondition);
    }

    final storeResults = await storeQuery.get();
    final storeSales = <String, double>{};

    for (final row in storeResults) {
      final purchase = row.readTable(purchaseHistory);
      final store = row.readTable(stores);

      storeSales[store.name] =
          (storeSales[store.name] ?? 0.0) + purchase.totalAmount;
    }

    if (storeSales.isNotEmpty) {
      final topStoreEntry = storeSales.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      topStore = topStoreEntry.key;
    }

    // Obtener mejor vendedor
    String topSeller = 'N/A';
    final sellerQuery = select(
      purchaseHistory,
    ).join([innerJoin(users, users.id.equalsExp(purchaseHistory.sellerId))]);

    if (conditions.isNotEmpty) {
      Expression<bool> finalCondition = conditions.first;
      for (int i = 1; i < conditions.length; i++) {
        finalCondition = finalCondition & conditions[i];
      }
      sellerQuery.where(finalCondition);
    }

    final sellerResults = await sellerQuery.get();
    final sellerSales = <String, double>{};

    for (final row in sellerResults) {
      final purchase = row.readTable(purchaseHistory);
      final seller = row.readTable(users);

      sellerSales[seller.fullName] =
          (sellerSales[seller.fullName] ?? 0.0) + purchase.totalAmount;
    }

    if (sellerSales.isNotEmpty) {
      final topSellerEntry = sellerSales.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      topSeller = topSellerEntry.key;
    }

    return {
      'totalSales': totalSales,
      'totalRevenue': totalRevenue,
      'averageTicket': averageTicket,
      'totalItems': totalItems,
      'topSellingProduct': topProduct,
      'topPerformingStore': topStore,
      'topSeller': topSeller,
    };
  }

  // Obtener ventas del día actual
  Future<List<Map<String, dynamic>>> getTodaysSales() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return getSalesReport(startDate: startOfDay, endDate: today);
  }

  // Obtener ventas de la semana actual
  Future<List<Map<String, dynamic>>> getWeeklySales() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    return getSalesReport(startDate: startOfDay, endDate: now);
  }

  // Obtener ventas del mes actual
  Future<List<Map<String, dynamic>>> getMonthlySales() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return getSalesReport(startDate: startOfMonth, endDate: now);
  }

  // Obtener ventas del año actual
  Future<List<Map<String, dynamic>>> getYearlySales() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    return getSalesReport(startDate: startOfYear, endDate: now);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'products.db'));
    return NativeDatabase.createInBackground(file);
  });
}
