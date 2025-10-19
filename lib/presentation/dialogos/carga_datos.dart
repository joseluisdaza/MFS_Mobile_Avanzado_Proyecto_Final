import 'package:carro_2_fin_expo_sqlite/bloc/products/products_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_event.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showItemDialog(
  BuildContext context, {
  Product? initial, // pásalo si quieres editar
}) async {
  final idCtrl = TextEditingController(text: initial?.id.toString() ?? '');
  final nombreCtrl = TextEditingController(text: initial?.name ?? '');
  final quantityCtrl = TextEditingController(
    text: initial?.quantity.toString() ?? '0',
  );
  final priceCtrl = TextEditingController(
    text: initial?.price.toString() ?? '0.0',
  );
  final descripcionCtrl = TextEditingController(
    text: initial?.description ?? '',
  );
  final categoryCtrl = TextEditingController(text: initial?.category ?? '');
  final imageCtrl = TextEditingController(
    text:
        initial?.image ??
        'https://cdn.awardcenter.com/images/Release/Hinda_HiRes/',
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
              autofocus: initial == null, // Solo autofocus en modo agregar
              readOnly: initial != null, // Solo lectura en modo editar
              decoration: InputDecoration(
                labelText: 'ID',
                suffixIcon: initial != null
                    ? const Icon(Icons.lock_outline, size: 16)
                    : null,
              ),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: descripcionCtrl,
              decoration: const InputDecoration(labelText: 'Descripcion'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingrese una descripcion'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: categoryCtrl,
              decoration: const InputDecoration(labelText: 'Categoria'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingrese una categoria'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: imageCtrl,
              decoration: const InputDecoration(
                labelText: 'Imagen (URL)',
                hintText: 'Ej: 103016.jpg',
                helperText:
                    'Solo ingrese el nombre del archivo (ej: 103016.jpg)',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingrese una URL de imagen'
                  : null,
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
              debugPrint('JOSH: Agregando/Guardando ítem...');
              debugPrint(
                'JOSH: id: ${idCtrl.text}, nombre: ${nombreCtrl.text}',
              );
              debugPrint(
                'JOSH: quantity: ${quantityCtrl.text}, price: ${priceCtrl.text}',
              );

              // Construir URL completa de imagen si es necesario
              String imageUrl = imageCtrl.text.trim();
              const baseUrl =
                  'https://cdn.awardcenter.com/images/Release/Hinda_HiRes/';

              // Si no es una URL completa (no empieza con http) y no está vacía
              if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                // Si no empieza con la URL base, agregarla
                if (!imageUrl.startsWith(baseUrl)) {
                  imageUrl = baseUrl + imageUrl;
                }
              }

              final product = Product(
                id: int.parse(idCtrl.text),
                name: nombreCtrl.text,
                quantity: int.parse(quantityCtrl.text),
                price: double.parse(priceCtrl.text),
                description: descripcionCtrl.text,
                category: categoryCtrl.text,
                image: imageUrl,
                inCart: initial?.inCart ?? false,
                shoppingCartQuantity: initial?.shoppingCartQuantity ?? 0,
              );

              if (initial == null) {
                // Adding new product
                context.read<ProductsBloc>().add(AddProduct(product));
              } else {
                // Updating existing product
                context.read<ProductsBloc>().add(UpdateProduct(product));
              }

              Navigator.pop(ctx, true);
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
