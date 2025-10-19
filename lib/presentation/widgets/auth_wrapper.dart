import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/auth/auth_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/bloc/auth/auth_state.dart';
import 'package:carro_2_fin_expo_sqlite/presentation/pages/login_page.dart';
import 'package:carro_2_fin_expo_sqlite/presentation/pages/home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return HomePage(user: state.user);
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
