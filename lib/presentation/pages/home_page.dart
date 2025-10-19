import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_event.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_state.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/cart/cart_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/cart/cart_event.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/cart/cart_state.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';
import 'package:carro_2_fin_expo_sqlite/presentation/dialogos/product_dialog.dart';
import 'package:carro_2_fin_expo_sqlite/presentation/dialogos/inventory_dialog.dart';
import 'package:carro_2_fin_expo_sqlite/presentation/pages/stores_page.dart';
import 'package:carro_2_fin_expo_sqlite/presentation/pages/users_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROYECTO FINAL')),
      drawer: _buildDrawer(context),
      body: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) {
          if (state is ProductsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductsError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is ProductsLoaded) {
            return _buildProductsList(context, state);
          }

          return const Center(child: Text('Cargando productos...'));
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            child: Text('Menú', style: TextStyle(fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Inventario'),
            onTap: () {
              context.read<ProductsBloc>().add(
                const FilterProducts('inventario'),
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Carrito'),
            onTap: () {
              context.read<ProductsBloc>().add(const FilterProducts('carrito'));
              context.read<CartBloc>().add(LoadCart());
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Comprar'),
            onTap: () {
              context.read<ProductsBloc>().add(const FilterProducts('comprar'));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Tiendas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StoresPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Usuarios'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsersPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, ProductsLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: state.filteredProducts.length,
        itemBuilder: (context, index) {
          final product = state.filteredProducts[index];
          return Card(
            child: InkWell(
              onTap: state.currentFilter == 'inventario'
                  ? () => _showProductDialog(context, product)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Imagen del producto
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        product.image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Información del producto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('\$${product.price.toStringAsFixed(2)}'),
                          if (product.description.isNotEmpty)
                            Text(
                              product.description,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),

                    // Controles según la vista
                    _buildProductControls(
                      context,
                      product,
                      state.currentFilter,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductControls(
    BuildContext context,
    dynamic product,
    String filter,
  ) {
    switch (filter) {
      case 'comprar':
        return Checkbox(
          value: product.inCart,
          onChanged: (value) {
            context.read<ProductsBloc>().add(
              ToggleCart(product.id!, value ?? false),
            );
          },
        );

      case 'carrito':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                final newQuantity = (product.shoppingCartQuantity - 1).clamp(
                  0,
                  99,
                );
                context.read<ProductsBloc>().add(
                  UpdateCartQuantity(product.id!, newQuantity),
                );
              },
              icon: const Icon(Icons.remove),
            ),
            Text('${product.shoppingCartQuantity}'),
            IconButton(
              onPressed: () {
                final newQuantity = (product.shoppingCartQuantity + 1).clamp(
                  0,
                  99,
                );
                context.read<ProductsBloc>().add(
                  UpdateCartQuantity(product.id!, newQuantity),
                );
              },
              icon: const Icon(Icons.add),
            ),
          ],
        );

      case 'inventario':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                _showProductDialog(context, product);
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Editar producto',
            ),
            IconButton(
              onPressed: () {
                _showInventoryDialog(context, product);
              },
              icon: const Icon(Icons.inventory),
              tooltip: 'Gestionar inventario',
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFloatingActionButtons(BuildContext context) {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        if (state is ProductsLoaded) {
          switch (state.currentFilter) {
            case 'inventario':
              return FloatingActionButton(
                onPressed: () {
                  _showProductDialog(context);
                },
                child: const Icon(Icons.add),
              );

            case 'carrito':
              return FloatingActionButton.extended(
                onPressed: () => _showPaymentDialog(context),
                icon: const Icon(Icons.payment),
                label: const Text('Pagar'),
              );

            default:
              return const SizedBox.shrink();
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showPaymentDialog(BuildContext context) {
    context.read<CartBloc>().add(LoadCartWithStores());

    showDialog(
      context: context,
      builder: (context) => BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {
          if (state is PaymentProcessed) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );

            // Recargar productos para actualizar el inventario
            context.read<ProductsBloc>().add(LoadProducts());
          } else if (state is CartError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CartWithStoresLoaded) {
            return AlertDialog(
              title: const Text('Resumen de Compra'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del carrito
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total de items:'),
                              Text(
                                '${state.totalItems}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total a pagar:'),
                              Text(
                                '\$${state.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector de sucursal
                    const Text(
                      'Seleccionar Sucursal:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Store>(
                      initialValue: state.selectedStore,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      hint: const Text('Elija una sucursal'),
                      items: state.stores.map((store) {
                        return DropdownMenuItem(
                          value: store,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                store.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (store) {
                        if (store != null) {
                          context.read<CartBloc>().add(
                            SelectStoreForPurchase(store.id),
                          );
                        }
                      },
                    ),

                    // Validación de stock
                    if (state.selectedStore != null) ...[
                      const SizedBox(height: 16),
                      _buildStockValidation(state),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      state.selectedStore != null &&
                          (state.storeStockValidation[state
                                  .selectedStore!
                                  .id] ??
                              false)
                      ? () {
                          context.read<CartBloc>().add(
                            ProcessPaymentFromStore(state.selectedStore!.id),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        state.selectedStore != null &&
                            (state.storeStockValidation[state
                                    .selectedStore!
                                    .id] ??
                                false)
                        ? Colors.green
                        : Colors.grey,
                  ),
                  child: Text(
                    state.selectedStore == null
                        ? 'Seleccione Sucursal'
                        : (state.storeStockValidation[state
                                  .selectedStore!
                                  .id] ??
                              false)
                        ? 'Pagar'
                        : 'Stock Insuficiente',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          }

          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando información de tiendas...'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockValidation(CartWithStoresLoaded state) {
    final hasEnoughStock =
        state.storeStockValidation[state.selectedStore!.id] ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasEnoughStock ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasEnoughStock ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasEnoughStock ? Icons.check_circle : Icons.error,
                color: hasEnoughStock ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                hasEnoughStock ? 'Stock Disponible' : 'Stock Insuficiente',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: hasEnoughStock ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
          if (!hasEnoughStock && state.stockIssues.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Problemas de stock:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...state.stockIssues
                .map(
                  (issue) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      '• $issue',
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                )
                .toList(),
          ],
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, [Product? product]) {
    showDialog(
      context: context,
      builder: (context) => ProductDialog(product: product),
    );
  }

  void _showInventoryDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => InventoryDialog(product: product),
    );
  }
}
