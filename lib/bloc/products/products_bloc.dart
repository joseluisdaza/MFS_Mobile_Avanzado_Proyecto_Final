import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';
import 'products_event.dart';
import 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final AppDatabase database;

  ProductsBloc({required this.database}) : super(ProductsInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<FilterProducts>(_onFilterProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<ToggleCart>(_onToggleCart);
    on<UpdateCartQuantity>(_onUpdateCartQuantity);
    on<LoadProductsWithStoreInventory>(_onLoadProductsWithStoreInventory);
    on<UpdateStoreInventoryFromProducts>(_onUpdateStoreInventoryFromProducts);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductsState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final products = await database.getAllProducts();

      // Preservar el filtro actual si existe
      String currentFilter = 'inventario'; // default
      if (state is ProductsLoaded) {
        currentFilter = (state as ProductsLoaded).currentFilter;
      }

      emit(
        ProductsLoaded(
          products: products,
          filteredProducts: _filterProductsByType(products, currentFilter),
          currentFilter: currentFilter,
        ),
      );
    } catch (e) {
      emit(ProductsError('Error al cargar productos: $e'));
    }
  }

  Future<void> _onFilterProducts(
    FilterProducts event,
    Emitter<ProductsState> emit,
  ) async {
    if (state is ProductsLoaded) {
      final currentState = state as ProductsLoaded;
      final filtered = _filterProductsByType(
        currentState.products,
        event.filter,
      );

      emit(
        currentState.copyWith(
          filteredProducts: filtered,
          currentFilter: event.filter,
        ),
      );
    }
  }

  Future<void> _onAddProduct(
    AddProduct event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      await database.insertProduct(
        ProductsCompanion.insert(
          name: event.product.name,
          quantity: event.product.quantity,
          price: event.product.price,
          description: event.product.description,
          category: event.product.category,
          image: event.product.image,
          inCart: Value(event.product.inCart),
          shoppingCartQuantity: Value(event.product.shoppingCartQuantity),
        ),
      );
      add(LoadProducts()); // Recargar productos
      emit(const ProductOperationSuccess('Producto agregado exitosamente'));
    } catch (e) {
      emit(ProductsError('Error al agregar producto: $e'));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      await database.updateProduct(event.product);
      add(LoadProducts()); // Recargar productos
      emit(const ProductOperationSuccess('Producto actualizado exitosamente'));
    } catch (e) {
      emit(ProductsError('Error al actualizar producto: $e'));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      await database.deleteProduct(event.productId);
      add(LoadProducts()); // Recargar productos
      emit(const ProductOperationSuccess('Producto eliminado exitosamente'));
    } catch (e) {
      emit(ProductsError('Error al eliminar producto: $e'));
    }
  }

  Future<void> _onToggleCart(
    ToggleCart event,
    Emitter<ProductsState> emit,
  ) async {
    if (state is ProductsLoaded) {
      final currentState = state as ProductsLoaded;
      final product = currentState.products.firstWhere(
        (p) => p.id == event.productId,
      );

      final updatedProduct = product.copyWith(
        inCart: event.inCart,
        shoppingCartQuantity: event.inCart ? 1 : 0,
      );

      try {
        // Actualizar en la base de datos
        await database.updateProduct(updatedProduct);

        // Actualizar en el estado local
        final updatedProducts = currentState.products.map((p) {
          return p.id == event.productId ? updatedProduct : p;
        }).toList();

        emit(
          currentState.copyWith(
            products: updatedProducts,
            filteredProducts: _filterProductsByType(
              updatedProducts,
              currentState.currentFilter,
            ),
          ),
        );
      } catch (e) {
        emit(ProductsError('Error al actualizar carrito: $e'));
      }
    }
  }

  Future<void> _onUpdateCartQuantity(
    UpdateCartQuantity event,
    Emitter<ProductsState> emit,
  ) async {
    if (state is ProductsLoaded) {
      final currentState = state as ProductsLoaded;
      final product = currentState.products.firstWhere(
        (p) => p.id == event.productId,
      );

      final updatedProduct = product.copyWith(
        shoppingCartQuantity: event.quantity,
      );

      try {
        // Actualizar en la base de datos
        await database.updateProduct(updatedProduct);

        // Actualizar en el estado local
        final updatedProducts = currentState.products.map((p) {
          return p.id == event.productId ? updatedProduct : p;
        }).toList();

        emit(
          currentState.copyWith(
            products: updatedProducts,
            filteredProducts: _filterProductsByType(
              updatedProducts,
              currentState.currentFilter,
            ),
          ),
        );
      } catch (e) {
        emit(ProductsError('Error al actualizar cantidad: $e'));
      }
    }
  }

  List<Product> _filterProductsByType(List<Product> products, String filter) {
    switch (filter) {
      case 'inventario':
        return products;
      case 'carrito':
        return products.where((item) => item.inCart == true).toList();
      case 'comprar':
        return products.where((item) => item.quantity > 0).toList();
      default:
        return products;
    }
  }

  Future<void> _onLoadProductsWithStoreInventory(
    LoadProductsWithStoreInventory event,
    Emitter<ProductsState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final stores = await database.getAllStores();
      final products = await database.getAllProducts();

      // Crear un mapa de productos con su inventario por tienda
      List<Map<String, dynamic>> productsWithInventory = [];

      for (final product in products) {
        Map<String, dynamic> productData = {
          'product': product,
          'storeInventories': <Map<String, dynamic>>[],
        };

        for (final store in stores) {
          final storeInventoryData = await database
              .getProductsWithStoreInventory(store.id);

          Map<String, dynamic>? productInventory;
          try {
            productInventory = storeInventoryData.firstWhere(
              (item) => (item['product'] as Product).id == product.id,
            );
          } catch (e) {
            // Si no se encuentra el producto en el inventario de esta tienda
            productInventory = <String, dynamic>{
              'product': product,
              'storeQuantity': 0,
              'hasInventory': false,
            };
          }

          (productData['storeInventories'] as List<Map<String, dynamic>>)
              .add(<String, dynamic>{
                'store': store,
                'quantity': productInventory['storeQuantity'],
                'hasInventory': productInventory['hasInventory'],
              });
        }

        productsWithInventory.add(productData);
      }

      emit(
        ProductsWithStoreInventoryLoaded(
          productsWithInventory: productsWithInventory,
          stores: stores,
          currentFilter: 'inventario',
        ),
      );
    } catch (e) {
      emit(ProductsError('Error al cargar productos con inventario: $e'));
    }
  }

  Future<void> _onUpdateStoreInventoryFromProducts(
    UpdateStoreInventoryFromProducts event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      await database.updateInventoryQuantity(
        event.storeId,
        event.productId,
        event.quantity,
      );

      // Recargar datos actualizados
      add(const LoadProductsWithStoreInventory());
    } catch (e) {
      emit(ProductsError('Error al actualizar inventario: $e'));
    }
  }
}
