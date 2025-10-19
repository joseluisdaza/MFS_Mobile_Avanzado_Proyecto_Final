import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:carro_2_fin_expo_sqlite/database/database.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/stores/stores_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/stores/stores_state.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_event.dart';

class InventoryDialog extends StatefulWidget {
  final Product product;

  const InventoryDialog({super.key, required this.product});

  @override
  State<InventoryDialog> createState() => _InventoryDialogState();
}

class _InventoryDialogState extends State<InventoryDialog> {
  final _quantityController = TextEditingController();
  Store? _selectedStore;
  int _currentQuantity = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Inventario - ${widget.product.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Información del producto
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Precio: \$${widget.product.price.toStringAsFixed(2)}',
                    ),
                    Text('Categoría: ${widget.product.category}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selector de sucursal
            BlocBuilder<StoresBloc, StoresState>(
              builder: (context, state) {
                if (state is StoresLoaded) {
                  return DropdownButtonFormField<Store>(
                    value: _selectedStore,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Sucursal',
                      border: OutlineInputBorder(),
                    ),
                    items: state.stores.map((store) {
                      return DropdownMenuItem<Store>(
                        value: store,
                        child: Text(store.name),
                      );
                    }).toList(),
                    onChanged: (Store? newValue) {
                      if (newValue != null) {
                        _loadInventoryForStore(newValue);
                      }
                    },
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
            const SizedBox(height: 16),

            // Cantidad actual y campo de edición
            if (_selectedStore != null) ...[
              Card(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock actual en ${_selectedStore!.name}:',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_currentQuantity unidades',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _currentQuantity > 0
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Nueva cantidad',
                  border: OutlineInputBorder(),
                  helperText: 'Ingrese la cantidad actualizada de inventario',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (_selectedStore != null)
          ElevatedButton(
            onPressed: _updateInventory,
            child: const Text('Actualizar'),
          ),
      ],
    );
  }

  void _loadInventoryForStore(Store store) async {
    setState(() {
      _selectedStore = store;
    });

    final database = provider_pkg.Provider.of<AppDatabase>(
      context,
      listen: false,
    );
    final inventory = await database.getProductInventoryInStore(
      widget.product.id,
      store.id,
    );

    setState(() {
      _currentQuantity = inventory?.availableQuantity ?? 0;
      _quantityController.text = _currentQuantity.toString();
    });
  }

  void _updateInventory() async {
    if (_selectedStore == null) return;

    final newQuantity = int.tryParse(_quantityController.text);
    if (newQuantity == null || newQuantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese una cantidad válida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final database = provider_pkg.Provider.of<AppDatabase>(
        context,
        listen: false,
      );
      await database.updateInventoryQuantity(
        _selectedStore!.id,
        widget.product.id,
        newQuantity,
      );

      // Recargar productos para reflejar cambios
      if (context.mounted) {
        context.read<ProductsBloc>().add(LoadProducts());
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Inventario actualizado: ${_selectedStore!.name} - $newQuantity unidades',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar inventario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
}
