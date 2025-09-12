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
                  title: ListTile(
                    leading: CircleAvatar(child: Text(item.id.toString())),
                    title: Text(
                      item.name.toString(),
                      style: TextStyle(fontSize: 25),
                    ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showItemDialog(context, ref);
        },
      ),
    );
  }
}
