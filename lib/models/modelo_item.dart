class ModeloItem {
  final int? id;
  final String? name;
  final int quantity;
  final double price;
  final bool inCart;

  ModeloItem({
    required this.id,
    required this.name,
    required this.inCart,
    required this.quantity,
    required this.price,
  });

  //---------

  factory ModeloItem.fromMap(Map<String, Object?> map) => ModeloItem(
    id: map['id'] as int,
    name: map['name'] as String,
    inCart: (map['inCart'] as int) == 1,
    quantity: map['quantity'] as int,
    price: map['price'] as double,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'inCart': inCart ? 1 : 0,
    'quantity': quantity < 0 ? 0 : quantity,
    'price': price < 0 ? 0.0 : price,
  };

  //----------
  ModeloItem copyWith({
    int? id,
    String? name,
    bool? inCart,
    int? quantity,
    double? price,
  }) {
    return ModeloItem(
      id: id ?? this.id,
      name: name ?? this.name,
      inCart: inCart ?? this.inCart,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  // atajo util para invertir el flag
  //ModeloItem toggleIncart() => copyWith(inCart: !inCart);
}
