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
      emit(
        ProductsLoaded(
          products: products,
          filteredProducts: products,
          currentFilter: 'inventario',
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
      List<Product> filtered;

      switch (event.filter) {
        case 'inventario':
          filtered = currentState.products;
          break;
        case 'carrito':
          filtered = currentState.products
              .where((item) => item.inCart == true)
              .toList();
          break;
        case 'comprar':
          filtered = currentState.products
              .where((item) => item.quantity > 0)
              .toList();
          break;
        default:
          filtered = currentState.products;
      }

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

      add(UpdateProduct(updatedProduct));
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

      add(UpdateProduct(updatedProduct));
    }
  }
}
