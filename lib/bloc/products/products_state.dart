import 'package:equatable/equatable.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {}

class ProductsLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final List<Product> filteredProducts;
  final String currentFilter;

  const ProductsLoaded({
    required this.products,
    required this.filteredProducts,
    required this.currentFilter,
  });

  @override
  List<Object?> get props => [products, filteredProducts, currentFilter];

  ProductsLoaded copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    String? currentFilter,
  }) {
    return ProductsLoaded(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class ProductsError extends ProductsState {
  final String message;

  const ProductsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductOperationSuccess extends ProductsState {
  final String message;

  const ProductOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
