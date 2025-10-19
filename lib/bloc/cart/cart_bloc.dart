import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final AppDatabase database;

  CartBloc({required this.database}) : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<ProcessPayment>(_onProcessPayment);
    on<ClearCart>(_onClearCart);
    on<CalculateTotal>(_onCalculateTotal);
    on<LoadCartWithStores>(_onLoadCartWithStores);
    on<SelectStoreForPurchase>(_onSelectStoreForPurchase);
    on<ProcessPaymentFromStore>(_onProcessPaymentFromStore);
    on<ValidateStockAvailability>(_onValidateStockAvailability);
  }

  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    emit(CartLoading());
    try {
      final cartItems = await database.getCartProducts();

      final total = _calculateTotal(cartItems);
      final totalItems = _calculateTotalItems(cartItems);

      emit(
        CartLoaded(cartItems: cartItems, total: total, totalItems: totalItems),
      );
    } catch (e) {
      emit(CartError('Error al cargar carrito: $e'));
    }
  }

  Future<void> _onProcessPayment(
    ProcessPayment event,
    Emitter<CartState> emit,
  ) async {
    if (state is CartWithStoresLoaded) {
      final currentState = state as CartWithStoresLoaded;

      try {
        // Actualizar inventario de la tienda seleccionada y limpiar carrito
        for (final item in currentState.cartItems) {
          // Actualizar inventario en la tienda seleccionada
          final inventoryData = await database.getProductInventoryInStore(
            item.id,
            currentState.selectedStore!.id,
          );
          final currentQuantity = inventoryData?.availableQuantity ?? 0;
          final newQuantity = currentQuantity - item.shoppingCartQuantity;

          await database.updateInventoryQuantity(
            currentState.selectedStore!.id,
            item.id,
            newQuantity >= 0 ? newQuantity : 0,
          );

          // Limpiar estado del carrito para este producto
          final updatedItem = item.copyWith(
            inCart: false,
            shoppingCartQuantity: 0,
          );

          await database.updateProduct(updatedItem);
        }

        emit(
          PaymentProcessed('¡Pago realizado exitosamente!', currentState.total),
        );

        // Recargar el carrito (estará vacío ahora)
        add(LoadCart());
      } catch (e) {
        emit(CartError('Error al procesar pago: $e'));
      }
    }
  }

  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    try {
      // Limpiar todos los items del carrito
      await (database.update(
        database.products,
      )..where((p) => p.inCart.equals(true))).write(
        ProductsCompanion(
          inCart: const Value(false),
          shoppingCartQuantity: const Value(0),
        ),
      );

      emit(const CartLoaded(cartItems: [], total: 0.0, totalItems: 0));
    } catch (e) {
      emit(CartError('Error al limpiar carrito: $e'));
    }
  }

  Future<void> _onCalculateTotal(
    CalculateTotal event,
    Emitter<CartState> emit,
  ) async {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final total = _calculateTotal(currentState.cartItems);
      final totalItems = _calculateTotalItems(currentState.cartItems);

      emit(currentState.copyWith(total: total, totalItems: totalItems));
    }
  }

  double _calculateTotal(List<Product> items) {
    return items.fold(
      0.0,
      (sum, item) => sum + (item.price * item.shoppingCartQuantity),
    );
  }

  int _calculateTotalItems(List<Product> items) {
    return items.fold(0, (sum, item) => sum + item.shoppingCartQuantity);
  }

  Future<void> _onLoadCartWithStores(
    LoadCartWithStores event,
    Emitter<CartState> emit,
  ) async {
    emit(CartLoading());
    try {
      final cartItems = await database.getCartProducts();
      final stores = await database.getAllStores();
      final total = _calculateTotal(cartItems);
      final totalItems = _calculateTotalItems(cartItems);

      emit(
        CartWithStoresLoaded(
          cartItems: cartItems,
          total: total,
          totalItems: totalItems,
          stores: stores,
        ),
      );
    } catch (e) {
      emit(CartError('Error al cargar carrito con tiendas: $e'));
    }
  }

  Future<void> _onSelectStoreForPurchase(
    SelectStoreForPurchase event,
    Emitter<CartState> emit,
  ) async {
    if (state is CartWithStoresLoaded) {
      final currentState = state as CartWithStoresLoaded;
      final selectedStore = currentState.stores.firstWhere(
        (store) => store.id == event.storeId,
      );

      emit(currentState.copyWith(selectedStore: selectedStore));

      // Validar stock automáticamente al seleccionar tienda
      add(ValidateStockAvailability(event.storeId));
    }
  }

  Future<void> _onValidateStockAvailability(
    ValidateStockAvailability event,
    Emitter<CartState> emit,
  ) async {
    if (state is CartWithStoresLoaded) {
      final currentState = state as CartWithStoresLoaded;

      try {
        List<String> stockIssues = [];
        bool hasEnoughStock = true;

        for (final cartItem in currentState.cartItems) {
          final storeInventory = await database.getProductsWithStoreInventory(
            event.storeId,
          );
          final productInventory = storeInventory.firstWhere(
            (inv) => (inv['product'] as Product).id == cartItem.id,
            orElse: () => {'storeQuantity': 0},
          );

          final availableQuantity = productInventory['storeQuantity'] as int;
          final requiredQuantity = cartItem.shoppingCartQuantity;

          if (availableQuantity < requiredQuantity) {
            hasEnoughStock = false;
            stockIssues.add(
              '${cartItem.name}: necesita $requiredQuantity, disponible $availableQuantity',
            );
          }
        }

        final updatedValidation = Map<int, bool>.from(
          currentState.storeStockValidation,
        );
        updatedValidation[event.storeId] = hasEnoughStock;

        emit(
          currentState.copyWith(
            storeStockValidation: updatedValidation,
            stockIssues: stockIssues,
          ),
        );
      } catch (e) {
        emit(CartError('Error al validar stock: $e'));
      }
    }
  }

  Future<void> _onProcessPaymentFromStore(
    ProcessPaymentFromStore event,
    Emitter<CartState> emit,
  ) async {
    if (state is CartWithStoresLoaded) {
      final currentState = state as CartWithStoresLoaded;

      try {
        // Validar stock antes de procesar pago
        List<Map<String, dynamic>> purchaseItems = [];

        for (final cartItem in currentState.cartItems) {
          final storeInventory = await database.getProductsWithStoreInventory(
            event.storeId,
          );
          final productInventory = storeInventory.firstWhere(
            (inv) => (inv['product'] as Product).id == cartItem.id,
            orElse: () => {'storeQuantity': 0},
          );

          final availableQuantity = productInventory['storeQuantity'] as int;
          final requiredQuantity = cartItem.shoppingCartQuantity;

          if (availableQuantity < requiredQuantity) {
            emit(
              CartError(
                'Stock insuficiente para ${cartItem.name}: necesita $requiredQuantity, disponible $availableQuantity',
              ),
            );
            return;
          }

          purchaseItems.add({
            'productId': cartItem.id,
            'quantity': requiredQuantity,
            'unitPrice': cartItem.price,
          });
        }

        // Procesar la compra usando la nueva funcionalidad de la base de datos
        final purchaseId = await database.processPurchase(
          storeId: event.storeId,
          sellerId:
              1, // TODO: Usar usuario actual cuando se implemente autenticación
          items: purchaseItems,
        );

        // Limpiar carrito después del pago exitoso
        for (final item in currentState.cartItems) {
          final updatedItem = item.copyWith(
            inCart: false,
            shoppingCartQuantity: 0,
          );
          await database.updateProduct(updatedItem);
        }

        emit(
          PaymentProcessed(
            'Compra procesada exitosamente. ID: $purchaseId',
            currentState.total,
          ),
        );
      } catch (e) {
        emit(CartError('Error al procesar pago: $e'));
      }
    }
  }
}
