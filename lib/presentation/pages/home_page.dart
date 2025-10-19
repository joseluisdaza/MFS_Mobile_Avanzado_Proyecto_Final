import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_event.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_state.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/cart/cart_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/cart/cart_event.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/cart/cart_state.dart';
import 'package:carro_2_fin_expo_sqlite/presentation/dialogos/carga_datos.dart';
import 'package:carro_2_fin_expo_sqlite/presentation/pages/stores_page.dart';

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
                  ? () => showItemDialog(context, initial: product)
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
                        product.image ?? 'https://via.placeholder.com/60',
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
                            product.name ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('\$${product.price.toStringAsFixed(2)}'),
                          if (state.currentFilter == 'inventario')
                            Text('Saldo: ${product.quantity}'),
                          if (product.description?.isNotEmpty == true)
                            Text(
                              product.description!,
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
        return IconButton(
          onPressed: () {
            showItemDialog(context, initial: product);
          },
          icon: const Icon(Icons.edit),
          tooltip: 'Editar producto',
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
                  showItemDialog(context);
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
    context.read<CartBloc>().add(LoadCart());

    showDialog(
      context: context,
      builder: (context) => BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {
          if (state is PaymentProcessed) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));

            // Recargar productos para actualizar el inventario
            context.read<ProductsBloc>().add(LoadProducts());
          }
        },
        builder: (context, state) {
          if (state is CartLoaded) {
            return AlertDialog(
              title: const Text('Resumen de Compra'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total de items: ${state.totalItems}'),
                  Text('Total a pagar: \$${state.total.toStringAsFixed(2)}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<CartBloc>().add(ProcessPayment());
                  },
                  child: const Text('Pagar'),
                ),
              ],
            );
          }

          return const AlertDialog(content: CircularProgressIndicator());
        },
      ),
    );
  }
}
