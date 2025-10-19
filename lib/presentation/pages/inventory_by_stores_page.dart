import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_event.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_state.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';

class InventoryByStoresPage extends StatelessWidget {
  const InventoryByStoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario por Sucursal'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProductsBloc>().add(
                const LoadProductsWithStoreInventory(),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ProductsBloc, ProductsState>(
        listener: (context, state) {
          if (state is ProductsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProductsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductsWithStoreInventoryLoaded) {
            return _buildInventoryList(context, state);
          }

          if (state is ProductsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProductsBloc>().add(
                        const LoadProductsWithStoreInventory(),
                      );
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Cargando inventario...'));
        },
      ),
    );
  }

  Widget _buildInventoryList(
    BuildContext context,
    ProductsWithStoreInventoryLoaded state,
  ) {
    if (state.productsWithInventory.isEmpty) {
      return const Center(
        child: Text(
          'No hay productos en el inventario',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.productsWithInventory.length,
      itemBuilder: (context, index) {
        final productData = state.productsWithInventory[index];
        final product = productData['product'] as Product;
        final storeInventories =
            productData['storeInventories'] as List<Map<String, dynamic>>;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.image,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image),
                  );
                },
              ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Categoría: ${product.category}'),
                Text('Precio: \$${product.price.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                _buildTotalInventoryIndicator(storeInventories),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventario por Sucursal:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...storeInventories.map((storeInventory) {
                      final store = storeInventory['store'] as Store;
                      final quantity = storeInventory['quantity'] as int;
                      final hasInventory =
                          storeInventory['hasInventory'] as bool;

                      return _buildStoreInventoryRow(
                        context,
                        product,
                        store,
                        quantity,
                        hasInventory,
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalInventoryIndicator(
    List<Map<String, dynamic>> storeInventories,
  ) {
    final totalQuantity = storeInventories
        .map((inv) => inv['quantity'] as int)
        .fold(0, (sum, quantity) => sum + quantity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: totalQuantity > 0 ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Total: $totalQuantity unidades',
        style: TextStyle(
          fontSize: 12,
          color: totalQuantity > 0 ? Colors.green[700] : Colors.red[700],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStoreInventoryRow(
    BuildContext context,
    Product product,
    Store store,
    int quantity,
    bool hasInventory,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: quantity > 0 ? Colors.green[50] : Colors.red[50],
      ),
      child: Row(
        children: [
          // Ícono de la tienda
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: quantity > 0 ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.store,
              size: 20,
              color: quantity > 0 ? Colors.green[700] : Colors.red[700],
            ),
          ),
          const SizedBox(width: 12),

          // Información de la tienda
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  store.location,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Cantidad actual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: quantity > 0 ? Colors.green[200] : Colors.red[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: quantity > 0 ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botón editar
          IconButton(
            onPressed: () =>
                _showEditQuantityDialog(context, product, store, quantity),
            icon: const Icon(Icons.edit),
            iconSize: 20,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  void _showEditQuantityDialog(
    BuildContext context,
    Product product,
    Store store,
    int currentQuantity,
  ) {
    final quantityController = TextEditingController(
      text: currentQuantity.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Editar Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Producto: ${product.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tienda: ${store.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Cantidad actual: $currentQuantity'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nueva cantidad',
                border: OutlineInputBorder(),
                helperText: 'Ingrese la nueva cantidad para esta tienda',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuantity = int.tryParse(quantityController.text);
              if (newQuantity == null || newQuantity < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingrese una cantidad válida'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              context.read<ProductsBloc>().add(
                UpdateStoreInventoryFromProducts(
                  store.id,
                  product.id,
                  newQuantity,
                ),
              );

              Navigator.of(dialogContext).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Stock actualizado: ${store.name} - ${product.name} = $newQuantity unidades',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}
