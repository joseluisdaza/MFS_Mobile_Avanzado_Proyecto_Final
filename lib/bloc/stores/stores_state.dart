import 'package:equatable/equatable.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';

abstract class StoresState extends Equatable {
  const StoresState();

  @override
  List<Object?> get props => [];
}

class StoresInitial extends StoresState {}

class StoresLoading extends StoresState {}

class StoresLoaded extends StoresState {
  final List<Store> stores;
  final Store? selectedStore;
  final List<Map<String, dynamic>> storeInventory;

  const StoresLoaded({
    required this.stores,
    this.selectedStore,
    this.storeInventory = const [],
  });

  @override
  List<Object?> get props => [stores, selectedStore, storeInventory];

  StoresLoaded copyWith({
    List<Store>? stores,
    Store? selectedStore,
    List<Map<String, dynamic>>? storeInventory,
  }) {
    return StoresLoaded(
      stores: stores ?? this.stores,
      selectedStore: selectedStore ?? this.selectedStore,
      storeInventory: storeInventory ?? this.storeInventory,
    );
  }
}

class StoresError extends StoresState {
  final String message;

  const StoresError(this.message);

  @override
  List<Object?> get props => [message];
}

class StoreInventoryUpdated extends StoresState {
  final String message;

  const StoreInventoryUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductTransferred extends StoresState {
  final String message;

  const ProductTransferred(this.message);

  @override
  List<Object?> get props => [message];
}
