import 'package:carro_2_fin_expo_sqlite/models/modelo_item.dart';

class ContainerState {
  final List<ModeloItem> listaItem;
  final ModeloItem inputItem;

  ContainerState({required this.listaItem, required this.inputItem});

  ContainerState copyWith(List<ModeloItem>? listaItem, ModeloItem? inputItem) {
    return ContainerState(
      listaItem: listaItem ?? this.listaItem,
      inputItem: inputItem ?? this.inputItem,
    );
  }
}
