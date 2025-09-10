import 'package:carro_2_fin_expo_sqlite/application/container_state.dart';
import 'package:carro_2_fin_expo_sqlite/application/provider_consultas.dart';
import 'package:carro_2_fin_expo_sqlite/data/consultas.dart';
import 'package:carro_2_fin_expo_sqlite/data/sqlite_db.dart';
import 'package:carro_2_fin_expo_sqlite/models/modelo_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManagerStateNotifier extends StateNotifier<ContainerState> {
  final Ref ref;
  late final ModeloItemDao _dao;

  ManagerStateNotifier(this.ref)
    : super(
        ContainerState(
          listaItem: [],
          inputItem: ModeloItem(id: -1, name: '', inCart: false),
        ),
      ) {
    _dao = ref.read(modeloItemDaoProvider);
    _init(); // carga inicial no bloqueante
  }

  Future<void> _init() async {
    final items = await _dao.listarTodo(orderBy: 'id ASC');
    state = state.copyWith(items, null);
  }

  // metodo para agregar o para modificar un item en la lista
  bool addOrUpdateWith(ModeloItem item) {
    if (item.id == -1 || item.name!.trim().isEmpty) return false;
    final idx = state.listaItem.indexWhere((e) => e.id == item.id);
    final listaTemporal = [...state.listaItem];
    if (idx == -1) {
      listaTemporal.add(item);
      //---
      final response = ref
          .read(modeloItemControllerProvider.notifier)
          .guardar(item.name.toString());
      //---
    } else {
      listaTemporal[idx] = item;
      //---
      final response = ref
          .read(modeloItemControllerProvider.notifier)
          .modificarNombre(item.id, item.name.toString());
      //---
    }
    state = state.copyWith(listaTemporal, null);
    return true;
  }

  // Cargar un item existente para su edicion
  bool editItemById(int id) {
    final idx = state.listaItem.indexWhere((e) => e.id == id);
    if (idx == -1) return false;
    state = state.copyWith(null, state.listaItem[idx]);
    return true;
  }

  // Devuelve un item existente de la lista
  ModeloItem itemElement(int idx) {
    return state.listaItem[idx];
  }

  // Elimina un item existente en base al id
  bool removeItemById(int id) {
    final listaTemporal = state.listaItem
        .where((e) => e.id != id)
        .toList(); // (growable: false);
    // growable=false significa: crea una lista de tamaño fijo
    final changed = listaTemporal != state.listaItem;
    if (changed) {
      state.copyWith(listaTemporal, null);
    }
    return changed;
  }

  // eliminamos un item de manera segura
  bool removeItemByIdx(int idx) {
    if (idx < 0 || idx >= state.listaItem.length) {
      return false;
    } else {
      final listaTemporal = [...state.listaItem]..removeAt(idx);
      state = state.copyWith(listaTemporal, null);
      return true;
    }
  }

  // limpiar el estado de inpuItem
  void clearInput() {
    state = state.copyWith(null, ModeloItem(id: -1, name: '', inCart: false));
  }

  // limpiar todo es state
  void clearAllState() {
    state = state.copyWith([], ModeloItem(id: -1, name: '', inCart: false));
  }

  // Devolver la lista completa
  List<ModeloItem> listaCompleta() {
    return state.listaItem;
  }

  bool toggleSelectedById(int? id) {
    final idx = state.listaItem.indexWhere((e) => e.id == id);
    if (idx == -1) return false;
    final itemAnterior = state.listaItem[idx];
    final itemActualizado = itemAnterior.copyWith(inCart: !itemAnterior.inCart);
    final listaTemporal = [...state.listaItem];
    listaTemporal[idx] = itemActualizado;
    // que tal si el cambio es de un item que eta en el state, tambien lo cambiamos
    final sameAsInput = state.inputItem.id == id;
    state = state.copyWith(
      listaTemporal,
      sameAsInput
          ? state.inputItem.copyWith(inCart: itemActualizado.inCart)
          : null,
    );
    return true;
  }
}

final managerProvider =
    StateNotifierProvider<ManagerStateNotifier, ContainerState>(
      (ref) => ManagerStateNotifier(ref),
    );

var menuItems = ['En el carrito', 'Por comprar', 'Completa'];

final menuProvider = StateProvider<String>((ref) {
  return 'Completa';
});

final fiteredCartListProvider = Provider<List<ModeloItem>>((ref) {
  final filter = ref.watch(menuProvider);
  final listaTemporal = ref.watch(managerProvider).listaItem;
  switch (filter) {
    case 'Completa':
      return listaTemporal;
    case 'En el carrito':
      return listaTemporal.where((item) => item.inCart).toList();
    case 'Por comprar':
      return listaTemporal.where((item) => !item.inCart).toList();
  }
  throw {};
});

// provider database
final dbProvider = Provider<AppDb>((_) => AppDb());
