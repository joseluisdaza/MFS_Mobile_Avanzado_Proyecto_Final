import 'package:equatable/equatable.dart';

abstract class StoresEvent extends Equatable {
  const StoresEvent();

  @override
  List<Object?> get props => [];
}

class LoadStores extends StoresEvent {}

class SelectStore extends StoresEvent {
  final int storeId;

  const SelectStore(this.storeId);

  @override
  List<Object?> get props => [storeId];
}

class LoadStoreInventory extends StoresEvent {
  final int storeId;

  const LoadStoreInventory(this.storeId);

  @override
  List<Object?> get props => [storeId];
}

class UpdateStoreInventoryQuantity extends StoresEvent {
  final int storeId;
  final int productId;
  final int newQuantity;

  const UpdateStoreInventoryQuantity(
    this.storeId,
    this.productId,
    this.newQuantity,
  );

  @override
  List<Object?> get props => [storeId, productId, newQuantity];
}

class AddProductToStore extends StoresEvent {
  final int storeId;
  final int productId;
  final int quantity;

  const AddProductToStore(this.storeId, this.productId, this.quantity);

  @override
  List<Object?> get props => [storeId, productId, quantity];
}

class TransferProductBetweenStores extends StoresEvent {
  final int fromStoreId;
  final int toStoreId;
  final int productId;
  final int quantity;

  const TransferProductBetweenStores({
    required this.fromStoreId,
    required this.toStoreId,
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [fromStoreId, toStoreId, productId, quantity];
}
