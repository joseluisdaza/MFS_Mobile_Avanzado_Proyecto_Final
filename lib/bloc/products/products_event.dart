import 'package:equatable/equatable.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductsEvent {}

class FilterProducts extends ProductsEvent {
  final String filter; // 'inventario', 'carrito', 'comprar'

  const FilterProducts(this.filter);

  @override
  List<Object?> get props => [filter];
}

class AddProduct extends ProductsEvent {
  final Product product;

  const AddProduct(this.product);

  @override
  List<Object?> get props => [product];
}

class UpdateProduct extends ProductsEvent {
  final Product product;

  const UpdateProduct(this.product);

  @override
  List<Object?> get props => [product];
}

class DeleteProduct extends ProductsEvent {
  final int productId;

  const DeleteProduct(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ToggleCart extends ProductsEvent {
  final int productId;
  final bool inCart;

  const ToggleCart(this.productId, this.inCart);

  @override
  List<Object?> get props => [productId, inCart];
}

class UpdateCartQuantity extends ProductsEvent {
  final int productId;
  final int quantity;

  const UpdateCartQuantity(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}
