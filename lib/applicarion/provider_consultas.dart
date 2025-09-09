// modelo_item_providers.dart
import 'package:carro_2_fin_expo_sqlite/data/consultas.dart';
import 'package:carro_2_fin_expo_sqlite/data/sqlite_db.dart';
import 'package:carro_2_fin_expo_sqlite/models/modelo_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provee la DB (ajústalo si ya lo tienes en otro archivo)
final appDbProvider = Provider<AppDb>((ref) => AppDb());

// Provee el DAO
final modeloItemDaoProvider = Provider<ModeloItemDao>((ref) {
  final db = ref.watch(appDbProvider);
  return ModeloItemDao(db);
});

// Lista completa (orden por defecto: id ASC)
final itemsListaProvider = FutureProvider<List<ModeloItem>>((ref) async {
  final dao = ref.watch(modeloItemDaoProvider);
  return dao.listarTodo();
});

// Lista filtrada por inCart
final itemsFiltradosProvider = FutureProvider.family<List<ModeloItem>, bool>((
  ref,
  inCart,
) async {
  final dao = ref.watch(modeloItemDaoProvider);
  return dao.listarFiltrado(inCart);
});

// Buscar por id (puede devolver null si no existe)
final itemPorIdProvider = FutureProvider.family<ModeloItem?, int>((
  ref,
  id,
) async {
  final dao = ref.watch(modeloItemDaoProvider);
  return dao.buscar(id);
});

class ModeloItemController extends AsyncNotifier<void> {
  late final ModeloItemDao _dao;

  @override
  Future<void> build() async {
    _dao = ref.read(modeloItemDaoProvider);
    // No llevamos estado local; este controller solo orquesta acciones.
  }

  Future<ModeloItem> guardar(String nombre) async {
    state = const AsyncLoading();
    try {
      final created = await _dao.guardar(nombre);
      _refrescarListas(created.id);
      state = const AsyncData(null);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<int> eliminar(int id) async {
    state = const AsyncLoading();
    try {
      final count = await _dao.eliminar(id);
      _refrescarListas(id);
      state = const AsyncData(null);
      return count;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // Método para actualizar solo el nombre de un producto por su ID
  Future<int> modificarNombre(int? id, String nuevoNombre) async {
    final result = await _dao.modificarNombre(id!, nuevoNombre);

    return result; // Retorna el número de filas afectadas (1 si fue exitoso)
  }

  /// Invalida proveedores de listas y del item puntual (si aplica)
  void _refrescarListas(int? maybeId) {
    // Listas
    ref.invalidate(itemsListaProvider);
    ref.invalidate(itemsFiltradosProvider(true));
    ref.invalidate(itemsFiltradosProvider(false));
    // Item puntual
    if (maybeId != null) {
      ref.invalidate(itemPorIdProvider(maybeId));
    }
  }
}

final modeloItemControllerProvider =
    AsyncNotifierProvider<ModeloItemController, void>(ModeloItemController.new);
