import 'package:carro_2_fin_expo_sqlite/application/manager_state.dart';
import 'package:carro_2_fin_expo_sqlite/models/modelo_item.dart';
import 'package:carro_2_fin_expo_sqlite/presentation/dialogos/carga_datos.dart';
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
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: Card(
                elevation: 10,
                child: CheckboxListTile(
                  title: Row(
                    children: [
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
                              item.price.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Builder(
                              builder: (context) {
                                final selectedMenu = ref.watch(menuProvider);
                                if (selectedMenu == filtroInventario) {
                                  return Text(
                                    '${item.quantity} item(s)',
                                    style: const TextStyle(fontSize: 16),
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  value: item.inCart,
                  onChanged: (value) => ref
                      .read(managerProvider.notifier)
                      .toggleSelectedById(item.id),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: ref.watch(menuProvider) == filtroInventario
          ? FloatingActionButton(
              onPressed: () {
                showItemDialog(context, ref);
              },
            )
          : null,
    );
  }
}
