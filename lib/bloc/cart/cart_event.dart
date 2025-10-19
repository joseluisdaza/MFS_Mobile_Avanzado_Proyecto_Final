import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {}

class ProcessPayment extends CartEvent {}

class ClearCart extends CartEvent {}

class CalculateTotal extends CartEvent {}

class LoadCartWithStores extends CartEvent {}

class SelectStoreForPurchase extends CartEvent {
  final int storeId;

  const SelectStoreForPurchase(this.storeId);

  @override
  List<Object?> get props => [storeId];
}

class ProcessPaymentFromStore extends CartEvent {
  final int storeId;

  const ProcessPaymentFromStore(this.storeId);

  @override
  List<Object?> get props => [storeId];
}

class ValidateStockAvailability extends CartEvent {
  final int storeId;

  const ValidateStockAvailability(this.storeId);

  @override
  List<Object?> get props => [storeId];
}
