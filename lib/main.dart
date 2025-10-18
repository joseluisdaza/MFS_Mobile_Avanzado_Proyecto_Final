import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/cart/cart_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_event.dart';
import 'package:carro_2_fin_expo_sqlite/presentation/pages/home_page.dart';
import 'package:carro_2_fin_expo_sqlite/theme_provider.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MultiBlocProvider(
      providers: [
        // BLoC de productos
        BlocProvider<ProductsBloc>(
          create: (context) =>
              ProductsBloc(database: AppDatabase())..add(LoadProducts()),
        ),
        // BLoC del carrito
        BlocProvider<CartBloc>(
          create: (context) => CartBloc(database: AppDatabase()),
        ),
      ],
      child: MaterialApp(
        title: 'Carrito de Compras By Josh',
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: const HomePage(),
      ),
    );
  }
}
