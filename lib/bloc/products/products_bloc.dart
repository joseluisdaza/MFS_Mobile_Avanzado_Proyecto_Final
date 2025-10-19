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
      // Insertar el producto
      final productId = await database.insertProduct(
        ProductsCompanion.insert(
          name: event.product.name,
          price: event.product.price,
          description: event.product.description,
          category: event.product.category,
          image: event.product.image,
          inCart: Value(event.product.inCart),
          shoppingCartQuantity: Value(event.product.shoppingCartQuantity),
        ),
      );

      // Crear inventario inicial en todas las tiendas con cantidad 0
      await database.createInitialInventoryForProduct(productId);

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
        return products; // Mostrar todos los productos para compra
      default:
        return products;
    }
  }
}
