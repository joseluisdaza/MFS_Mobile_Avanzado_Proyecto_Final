import 'package:equatable/equatable.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];

  // Helper methods para verificar roles
  bool get isAdmin => user.role == 'admin';
  bool get isManager => user.role == 'manager';
  bool get isSeller => user.role == 'seller';

  // Helper methods para permisos
  bool get canManageProducts => isAdmin;
  bool get canManageInventory => isAdmin || isManager;
  bool get canManageStores => isAdmin || isManager;
  bool get canManageUsers => isAdmin || isManager;
  bool get canAccessCart => true; // Todos pueden acceder al carrito
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
