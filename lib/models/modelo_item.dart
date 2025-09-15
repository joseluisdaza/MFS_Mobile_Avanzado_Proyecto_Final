class ModeloItem {
  final int? id;
  final String? name;
  final int quantity;
  final double price;
  final bool inCart;
  final String? description;
  final String? category;
  final String? image;
  final int shoppingCartQuantity;

  ModeloItem({
    required this.id,
    required this.name,
    required this.inCart,
    required this.quantity,
    required this.price,
    this.description,
    this.category,
    this.image,
    this.shoppingCartQuantity = 0,
  });

  //---------

  factory ModeloItem.fromMap(Map<String, Object?> map) => ModeloItem(
    id: map['id'] as int?,
    name: map['name'] as String?,
    inCart: (map['inCart'] as int) == 1,
    quantity: map['quantity'] as int,
    price: map['price'] as double,
    description: map['description'] as String?,
    category: map['category'] as String?,
    image: map['image'] as String?,
    shoppingCartQuantity: map['shoppingCartQuantity'] as int? ?? 0,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'inCart': inCart ? 1 : 0,
    'quantity': quantity < 0 ? 0 : quantity,
    'price': price < 0 ? 0.0 : price,
    'description': description,
    'category': category,
    'image': image,
    'shoppingCartQuantity': shoppingCartQuantity,
  };

  //----------

  ModeloItem copyWith({
    int? id,
    String? name,
    bool? inCart,
    int? quantity,
    double? price,
    String? description,
    String? category,
    String? image,
    int? shoppingCartQuantity,
  }) {
    return ModeloItem(
      id: id ?? this.id,
      name: name ?? this.name,
      inCart: inCart ?? this.inCart,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      image: image ?? this.image,
      shoppingCartQuantity: shoppingCartQuantity ?? this.shoppingCartQuantity,
    );
  }

  // atajo util para invertir el flag
  //ModeloItem toggleIncart() => copyWith(inCart: !inCart);
}
