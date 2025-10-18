import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {}

class ProcessPayment extends CartEvent {}

class ClearCart extends CartEvent {}

class CalculateTotal extends CartEvent {}
