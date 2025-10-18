import 'package:equatable/equatable.dart';
import 'package:carro_2_fin_expo_sqlite/data/app_database.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<ModeloItem> cartItems;
  final double total;
  final int totalItems;

  const CartLoaded({
    required this.cartItems,
    required this.total,
    required this.totalItems,
  });

  @override
  List<Object?> get props => [cartItems, total, totalItems];

  CartLoaded copyWith({
    List<ModeloItem>? cartItems,
    double? total,
    int? totalItems,
  }) {
    return CartLoaded(
      cartItems: cartItems ?? this.cartItems,
      total: total ?? this.total,
      totalItems: totalItems ?? this.totalItems,
    );
  }
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

class PaymentProcessed extends CartState {
  final String message;
  final double totalPaid;

  const PaymentProcessed(this.message, this.totalPaid);

  @override
  List<Object?> get props => [message, totalPaid];
}
