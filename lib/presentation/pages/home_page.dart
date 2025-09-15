import 'package:carro_2_fin_expo_sqlite/application/manager_state.dart';
import 'package:carro_2_fin_expo_sqlite/models/modelo_item.dart';
import 'package:carro_2_fin_expo_sqlite/presentation/dialogos/carga_datos.dart';
import 'package:carro_2_fin_expo_sqlite/presentation/pages/edit_item_dialog.dart';
import 'package:carro_2_fin_expo_sqlite/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<ModeloItem> carItems = ref.watch(fiteredCartListProvider);

    return Scaffold(
      backgroundColor: Colors.brown.shade200,
      appBar: AppBar(
        title: Text('Mercado libre'),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            tooltip: 'Cambiar tema',
            onPressed: () {
              final current = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state =
                  current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          DropdownButton(
            items: menuItems
                .map((String e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (String? value) {
              debugPrint('Selected menu item: $value');
              ref.read(menuProvider.notifier).update((_) => value!);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text('Menú', style: TextStyle(fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text(filtroInventario),
              selected: ref.watch(menuProvider) == filtroInventario,
              onTap: () {
                ref.read(menuProvider.notifier).state = filtroInventario;
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text(filtroCarrito),
              selected: ref.watch(menuProvider) == filtroCarrito,
              onTap: () {
                ref.read(menuProvider.notifier).state = filtroCarrito;
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text(filtroComprar),
              selected: ref.watch(menuProvider) == filtroComprar,
              onTap: () {
                ref.read(menuProvider.notifier).state = filtroComprar;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ListView.builder(
          itemCount: carItems.length,
          itemBuilder: (context, index) {
            final item = carItems[index];
            final selectedMenu = ref.watch(menuProvider);

            // Common product image widget
            Widget productImage = _buildProductImage(item.image);

            Widget content = Card(
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Product Image
                    productImage,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.id.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'S/ ${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (selectedMenu == filtroInventario)
                            Text(
                              '${item.quantity} item(s)',
                              style: const TextStyle(fontSize: 16),
                            ),
                          // Show category and description if available
                          if (item.category != null &&
                              item.category!.isNotEmpty)
                            Text(
                              'Categoría: ${item.category}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          if (item.description != null &&
                              item.description!.isNotEmpty)
                            Text(
                              item.description!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),

                    // Add edit button for inventory view
                    if (selectedMenu == filtroInventario)
                      PopupMenuButton<String>(
                        onSelected: (String value) {
                          if (value == 'edit') {
                            _showEditItemDialog(context, ref, item);
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(context, ref, item);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Eliminar'),
                              ],
                            ),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert),
                      ),
                  ],
                ),
              ),
            );

            if (selectedMenu == filtroComprar) {
              return Padding(
                padding: const EdgeInsets.all(5.0),
                child: Card(
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Product Image
                        productImage,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.id.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'S/ ${item.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (item.category != null &&
                                  item.category!.isNotEmpty)
                                Text(
                                  item.category!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: item.inCart,
                          onChanged: (value) {
                            ref
                                .read(managerProvider.notifier)
                                .toggleSelectedById(item.id);

                            if (value == true) {
                              ref
                                  .read(managerProvider.notifier)
                                  .actualizarCartQuantity(item.id, 1);
                            } else {
                              ref
                                  .read(managerProvider.notifier)
                                  .actualizarCartQuantity(item.id, 0);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else if (selectedMenu == filtroCarrito) {
              return Padding(
                padding: const EdgeInsets.all(5.0),
                child: Card(
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Product Image
                        productImage,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.id.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'S/ ${item.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      ref
                                          .read(managerProvider.notifier)
                                          .decrementCartQuantity(item.id);
                                    },
                                  ),
                                  Text(
                                    '${item.shoppingCartQuantity}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      ref
                                          .read(managerProvider.notifier)
                                          .incrementCartQuantity(item.id);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(5.0),
                child: content,
              );
            }
          },
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final selectedMenu = ref.watch(menuProvider);
          if (selectedMenu == filtroInventario) {
            return FloatingActionButton(
              onPressed: () {
                debugPrint('Josh: Agregando nuevo ítem...');
                showItemDialog(context, ref);
              },
              tooltip: 'Agregar producto',
              child: const Icon(Icons.add),
            );
          } else if (selectedMenu == filtroCarrito) {
            return FloatingActionButton(
              onPressed: () {
                debugPrint('Josh: Pagando...');
                final carItems = ref.watch(fiteredCartListProvider);
                final total = carItems.fold<double>(
                  0,
                  (sum, item) =>
                      sum + item.price * (item.shoppingCartQuantity ?? 1),
                );
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Resumen de compra'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...carItems.map(
                              (item) => ListTile(
                                leading: _buildProductImage(
                                  item.image,
                                  size: 40,
                                ),
                                title: Text(item.name ?? ''),
                                subtitle: Text(
                                  '${item.shoppingCartQuantity} unidades',
                                ),
                                trailing: Text(
                                  'S/ ${(item.price * item.shoppingCartQuantity).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const Divider(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Total: S/ ${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Actualizar inventario: quantity = quantity - shoppingCartQuantity
                            for (final item in carItems) {
                              if (item.shoppingCartQuantity > 0) {
                                ref
                                    .read(managerProvider.notifier)
                                    .addOrUpdateWith(
                                      item.copyWith(
                                        quantity:
                                            (item.quantity -
                                            item.shoppingCartQuantity),
                                        shoppingCartQuantity: 0,
                                        inCart: false,
                                      ),
                                    );
                              }
                            }
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('¡Pago realizado!')),
                            );
                          },
                          child: const Text('Pagar'),
                        ),
                      ],
                    );
                  },
                );
              },
              tooltip: 'Pagar',
              child: const Icon(Icons.payment),
            );
          } else {
            return SizedBox.shrink();
          }
        },
      ),
    );
  }

  // Method to show edit item dialog
  void _showEditItemDialog(
    BuildContext context,
    WidgetRef ref,
    ModeloItem item,
  ) {
    showEditItemDialog(context, ref, item);
  }

  // Method to show delete confirmation dialog
  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    ModeloItem item,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Estás seguro de que quieres eliminar "${item.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(managerProvider.notifier).removeItemById(item.id!);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name} eliminado')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to build product image widget
  Widget _buildProductImage(String? imageUrl, {double size = 60}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      // Default placeholder when no image URL
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!, width: 1),
        ),
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[600],
          size: size * 0.4,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                Icons.broken_image,
                color: Colors.red[300],
                size: size * 0.4,
              ),
            );
          },
        ),
      ),
    );
  }
}
