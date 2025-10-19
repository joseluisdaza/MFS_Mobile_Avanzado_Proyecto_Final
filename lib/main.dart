import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:carro_2_fin_expo_sqlite/database/database.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/cart/cart_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/stores/stores_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/users/users_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/products/products_event.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/stores/stores_event.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/users/users_event.dart';
import 'package:carro_2_fin_expo_sqlite/presentation/pages/home_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider_pkg.MultiProvider(
      providers: [
        // Única instancia de la base de datos compartida
        provider_pkg.Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, database) => database.close(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // BLoC de productos
          BlocProvider<ProductsBloc>(
            create: (context) => ProductsBloc(
              database: provider_pkg.Provider.of<AppDatabase>(
                context,
                listen: false,
              ),
            )..add(LoadProducts()),
          ),
          // BLoC del carrito
          BlocProvider<CartBloc>(
            create: (context) => CartBloc(
              database: provider_pkg.Provider.of<AppDatabase>(
                context,
                listen: false,
              ),
            ),
          ),
          // BLoC de tiendas
          BlocProvider<StoresBloc>(
            create: (context) => StoresBloc(
              database: provider_pkg.Provider.of<AppDatabase>(
                context,
                listen: false,
              ),
            )..add(LoadStores()),
          ),
          // BLoC de usuarios
          BlocProvider<UsersBloc>(
            create: (context) => UsersBloc(
              database: provider_pkg.Provider.of<AppDatabase>(
                context,
                listen: false,
              ),
            )..add(const LoadUsers()),
          ),
        ],
        child: MaterialApp(
          title: 'Carrito de Compras By Josh',
          themeMode: ThemeMode.system, // Usa el tema del sistema por defecto
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: const HomePage(),
        ),
      ),
    );
  }
}
