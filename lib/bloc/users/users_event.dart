import 'package:equatable/equatable.dart';

abstract class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsers extends UsersEvent {
  const LoadUsers();
}

class AddUser extends UsersEvent {
  final String username;
  final String password;
  final String fullName;
  final String role;

  const AddUser({
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
  });

  @override
  List<Object?> get props => [username, password, fullName, role];
}

class UpdateUser extends UsersEvent {
  final int userId;
  final String username;
  final String fullName;
  final String role;
  final String? newPassword;

  const UpdateUser({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.role,
    this.newPassword,
  });

  @override
  List<Object?> get props => [userId, username, fullName, role, newPassword];
}

class DeleteUser extends UsersEvent {
  final int userId;

  const DeleteUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SearchUsers extends UsersEvent {
  final String query;

  const SearchUsers(this.query);

  @override
  List<Object?> get props => [query];
}
