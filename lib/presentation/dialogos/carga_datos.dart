import 'package:carro_2_fin_expo_sqlite/application/manager_state.dart';

import 'package:carro_2_fin_expo_sqlite/models/modelo_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showItemDialog(
  BuildContext context,
  WidgetRef ref, {
  ModeloItem? initial, // pásalo si quieres editar
}) async {
  final idCtrl = TextEditingController(text: initial?.id.toString() ?? '');
  final nombreCtrl = TextEditingController(text: initial?.name ?? '');
  final quantityCtrl = TextEditingController(
    text: initial?.quantity.toString() ?? '0',
  );
  final priceCtrl = TextEditingController(
    text: initial?.price.toString() ?? '0.0',
  );

  final formKey = GlobalKey<FormState>();

  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(initial == null ? 'Agregar ítem' : 'Editar ítem'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: idCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'ID'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingrese un ID' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingrese un nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: quantityCtrl,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'La cantidad no puede ser vacia';
                }
                final n = int.tryParse(v);
                if (n == null || n < 0) {
                  return 'La Cantidad no puede ser negativa';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'El precio no puede ser vacio';
                }
                final n = double.tryParse(v);
                if (n == null || n < 0) {
                  return 'El precio no puede ser negativo';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              final added = ref
                  .read(managerProvider.notifier)
                  .addOrUpdateWith(
                    ModeloItem(
                      id: int.parse(idCtrl.text),
                      name: nombreCtrl.text,
                      inCart: false,
                      quantity: initial?.quantity ?? 0,
                      price: initial?.price ?? 0.0,
                    ),
                  );

              Navigator.pop(ctx, added);
            }
          },
          child: Text(initial == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    ),
  );

  if (ok == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          initial == null
              ? 'Ítem agregado correctamente  '
              : 'Ítem actualizado  ',
        ),
      ),
    );
  }
}
