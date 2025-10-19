import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';
import 'stores_event.dart';
import 'stores_state.dart';

class StoresBloc extends Bloc<StoresEvent, StoresState> {
  final AppDatabase database;

  StoresBloc({required this.database}) : super(StoresInitial()) {
    on<LoadStores>(_onLoadStores);
    on<SelectStore>(_onSelectStore);
    on<LoadStoreInventory>(_onLoadStoreInventory);
    on<UpdateStoreInventoryQuantity>(_onUpdateStoreInventoryQuantity);
    on<AddProductToStore>(_onAddProductToStore);
  }

  Future<void> _onLoadStores(
    LoadStores event,
    Emitter<StoresState> emit,
  ) async {
    emit(StoresLoading());
    try {
      await database.initializeDefaultData(); // Asegurar datos iniciales
      final stores = await database.getAllStores();
      emit(StoresLoaded(stores: stores));
    } catch (e) {
      emit(StoresError('Error al cargar tiendas: $e'));
    }
  }

  Future<void> _onSelectStore(
    SelectStore event,
    Emitter<StoresState> emit,
  ) async {
    if (state is StoresLoaded) {
      final currentState = state as StoresLoaded;
      final selectedStore = currentState.stores.firstWhere(
        (store) => store.id == event.storeId,
      );

      emit(currentState.copyWith(selectedStore: selectedStore));

      // Cargar inventario de la tienda seleccionada
      add(LoadStoreInventory(event.storeId));
    }
  }

  Future<void> _onLoadStoreInventory(
    LoadStoreInventory event,
    Emitter<StoresState> emit,
  ) async {
    if (state is StoresLoaded) {
      final currentState = state as StoresLoaded;
      try {
        final inventory = await database.getProductsWithStoreInventory(
          event.storeId,
        );
        emit(currentState.copyWith(storeInventory: inventory));
      } catch (e) {
        emit(StoresError('Error al cargar inventario: $e'));
      }
    }
  }

  Future<void> _onUpdateStoreInventoryQuantity(
    UpdateStoreInventoryQuantity event,
    Emitter<StoresState> emit,
  ) async {
    try {
      await database.updateInventoryQuantity(
        event.storeId,
        event.productId,
        event.newQuantity,
      );

      emit(const StoreInventoryUpdated('Inventario actualizado exitosamente'));

      // Recargar inventario
      add(LoadStoreInventory(event.storeId));
    } catch (e) {
      emit(StoresError('Error al actualizar inventario: $e'));
    }
  }

  Future<void> _onAddProductToStore(
    AddProductToStore event,
    Emitter<StoresState> emit,
  ) async {
    try {
      await database.insertStoreInventory(
        StoreInventoryCompanion.insert(
          storeId: event.storeId,
          productId: event.productId,
          availableQuantity: Value(event.quantity),
        ),
      );

      emit(
        const StoreInventoryUpdated(
          'Producto agregado a la tienda exitosamente',
        ),
      );

      // Recargar inventario
      add(LoadStoreInventory(event.storeId));
    } catch (e) {
      emit(StoresError('Error al agregar producto: $e'));
    }
  }
}
