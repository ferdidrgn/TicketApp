import 'package:freezed_annotation/freezed_annotation.dart';

@immutable
abstract class BaseState {
  final bool isLoading;
  final String? errorMessage;

  const BaseState({
    this.isLoading = false,
    this.errorMessage,
  });

  BaseState copyWith({
    final bool? isLoading,
    final String? errorMessage,
  });
}
