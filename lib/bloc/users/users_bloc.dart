import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';
import 'package:drift/drift.dart';
import 'users_event.dart';
import 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final AppDatabase database;

  UsersBloc({required this.database}) : super(const UsersInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<AddUser>(_onAddUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
    on<SearchUsers>(_onSearchUsers);
  }

  Future<void> _onLoadUsers(LoadUsers event, Emitter<UsersState> emit) async {
    emit(const UsersLoading());
    try {
      final users = await database.getAllUsers();
      emit(UsersLoaded(users: users, filteredUsers: users, searchQuery: ''));
    } catch (e) {
      emit(UsersError('Error al cargar usuarios: $e'));
    }
  }

  Future<void> _onAddUser(AddUser event, Emitter<UsersState> emit) async {
    try {
      // Verificar si el username ya existe
      final existingUser = await database.getUserByUsername(event.username);
      if (existingUser != null) {
        emit(const UsersError('El nombre de usuario ya existe'));
        return;
      }

      await database.insertUser(
        UsersCompanion.insert(
          username: event.username,
          password: event.password,
          fullName: event.fullName,
          role: Value(event.role),
        ),
      );

      emit(const UserAdded('Usuario agregado exitosamente'));

      // Recargar la lista de usuarios
      add(const LoadUsers());
    } catch (e) {
      emit(UsersError('Error al agregar usuario: $e'));
    }
  }

  Future<void> _onUpdateUser(UpdateUser event, Emitter<UsersState> emit) async {
    try {
      // Verificar si el username ya existe (solo si cambió)
      final currentUser = await database.getAllUsers().then(
        (users) => users.firstWhere((u) => u.id == event.userId),
      );

      if (currentUser.username != event.username) {
        final existingUser = await database.getUserByUsername(event.username);
        if (existingUser != null) {
          emit(const UsersError('El nombre de usuario ya existe'));
          return;
        }
      }

      // Crear el companion para actualizar
      final userToUpdate = User(
        id: event.userId,
        username: event.username,
        password: event.newPassword ?? currentUser.password,
        fullName: event.fullName,
        role: event.role,
        createdAt: currentUser.createdAt,
      );

      await database.updateUser(userToUpdate);

      emit(const UserUpdated('Usuario actualizado exitosamente'));

      // Recargar la lista de usuarios
      add(const LoadUsers());
    } catch (e) {
      emit(UsersError('Error al actualizar usuario: $e'));
    }
  }

  Future<void> _onDeleteUser(DeleteUser event, Emitter<UsersState> emit) async {
    try {
      await database.deleteUser(event.userId);
      emit(const UserDeleted('Usuario eliminado exitosamente'));

      // Recargar la lista de usuarios
      add(const LoadUsers());
    } catch (e) {
      emit(UsersError('Error al eliminar usuario: $e'));
    }
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<UsersState> emit,
  ) async {
    if (state is UsersLoaded) {
      final currentState = state as UsersLoaded;

      if (event.query.isEmpty) {
        emit(
          currentState.copyWith(
            filteredUsers: currentState.users,
            searchQuery: '',
          ),
        );
      } else {
        final filteredUsers = currentState.users.where((user) {
          final query = event.query.toLowerCase();
          return user.username.toLowerCase().contains(query) ||
              user.fullName.toLowerCase().contains(query) ||
              user.role.toLowerCase().contains(query);
        }).toList();

        emit(
          currentState.copyWith(
            filteredUsers: filteredUsers,
            searchQuery: event.query,
          ),
        );
      }
    }
  }
}
