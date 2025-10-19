import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AppDatabase database;

  AuthBloc({required this.database}) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Asegurar que los datos iniciales estén disponibles
      await database.initializeDefaultData();

      // Debug: Verificar usuarios existentes
      final allUsers = await database.getAllUsers();
      print('DEBUG: Usuarios encontrados: ${allUsers.length}');
      for (final user in allUsers) {
        print('Usuario: ${user.username} - ${user.fullName}');
      }

      // Buscar usuario en la base de datos
      final user = await database.getUserByCredentials(
        event.username,
        event.password,
      );

      if (user != null) {
        print('DEBUG: Login exitoso para ${user.username}');
        emit(AuthAuthenticated(user: user));
      } else {
        print(
          'DEBUG: Login falló para username: ${event.username}, password: ${event.password}',
        );
        emit(const AuthError(message: 'Usuario o contraseña incorrectos'));
      }
    } catch (e) {
      print('DEBUG: Error de autenticación: $e');
      emit(AuthError(message: 'Error de autenticación: $e'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthUnauthenticated());
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Asegurar que los datos iniciales estén disponibles al iniciar
      await database.initializeDefaultData();
    } catch (e) {
      // Si hay un error inicializando, aún así continúa
      print('Error inicializando datos: $e');
    }

    // En una implementación real, aquí verificarías el token guardado
    // Por ahora, siempre empezamos desautenticados
    emit(AuthUnauthenticated());
  }
}
