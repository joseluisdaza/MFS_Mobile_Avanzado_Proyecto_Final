import 'package:flutter/material.dart';

Future<bool> confirmDeleteDialog(
  BuildContext context, {
  required String titulo,
  required String mensaje,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true, // permite cerrar tocando fuera (si quieres)
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
