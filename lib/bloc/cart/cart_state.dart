import 'package:equatable/equatable.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<Product> cartItems;
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
    List<Product>? cartItems,
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

class CartWithStoresLoaded extends CartState {
  final List<Product> cartItems;
  final double total;
  final int totalItems;
  final List<Store> stores;
  final Store? selectedStore;
  final Map<int, bool> storeStockValidation; // storeId -> hasEnoughStock
  final List<String> stockIssues; // Mensajes de productos sin stock suficiente

  const CartWithStoresLoaded({
    required this.cartItems,
    required this.total,
    required this.totalItems,
    required this.stores,
    this.selectedStore,
    this.storeStockValidation = const {},
    this.stockIssues = const [],
  });

  @override
  List<Object?> get props => [
    cartItems,
    total,
    totalItems,
    stores,
    selectedStore,
    storeStockValidation,
    stockIssues,
  ];

  CartWithStoresLoaded copyWith({
    List<Product>? cartItems,
    double? total,
    int? totalItems,
    List<Store>? stores,
    Store? selectedStore,
    Map<int, bool>? storeStockValidation,
    List<String>? stockIssues,
  }) {
    return CartWithStoresLoaded(
      cartItems: cartItems ?? this.cartItems,
      total: total ?? this.total,
      totalItems: totalItems ?? this.totalItems,
      stores: stores ?? this.stores,
      selectedStore: selectedStore ?? this.selectedStore,
      storeStockValidation: storeStockValidation ?? this.storeStockValidation,
      stockIssues: stockIssues ?? this.stockIssues,
    );
  }
}
