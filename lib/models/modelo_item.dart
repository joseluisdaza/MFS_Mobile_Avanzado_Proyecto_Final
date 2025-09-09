class ModeloItem {
  final int? id;
  final String? name;
  final bool inCart;

  ModeloItem({required this.id, required this.name, required this.inCart});

  //---------

  factory ModeloItem.fromMap(Map<String, Object?> map) => ModeloItem(
    id: map['id'] as int,
    name: map['name'] as String,
    inCart: (map['inCart'] as int) == 1,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'inCart': inCart ? 1 : 0,
  };

  //----------
  ModeloItem copyWith({int? id, String? name, bool? inCart}) {
    return ModeloItem(
      id: id ?? this.id,
      name: name ?? this.name,
      inCart: inCart ?? this.inCart,
    );
  }

  // atajo util para invertir el flag
  //ModeloItem toggleIncart() => copyWith(inCart: !inCart);
}
