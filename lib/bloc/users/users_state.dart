import 'package:equatable/equatable.dart';
import 'package:carro_2_fin_expo_sqlite/database/database.dart';

abstract class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object?> get props => [];
}

class UsersInitial extends UsersState {
  const UsersInitial();
}

class UsersLoading extends UsersState {
  const UsersLoading();
}

class UsersLoaded extends UsersState {
  final List<User> users;
  final List<User> filteredUsers;
  final String searchQuery;

  const UsersLoaded({
    required this.users,
    required this.filteredUsers,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [users, filteredUsers, searchQuery];

  UsersLoaded copyWith({
    List<User>? users,
    List<User>? filteredUsers,
    String? searchQuery,
  }) {
    return UsersLoaded(
      users: users ?? this.users,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class UsersError extends UsersState {
  final String message;

  const UsersError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserAdded extends UsersState {
  final String message;

  const UserAdded(this.message);

  @override
  List<Object?> get props => [message];
}

class UserUpdated extends UsersState {
  final String message;

  const UserUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

class UserDeleted extends UsersState {
  final String message;

  const UserDeleted(this.message);

  @override
  List<Object?> get props => [message];
}
