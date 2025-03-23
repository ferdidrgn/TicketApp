// Base state class that can be extended by specific states
abstract class BaseState {
  final bool isLoading;
  final String? errorMessage;

  BaseState({
    this.isLoading = false,
    this.errorMessage,
  });

  BaseState copyWith({
    final bool? isLoading,
    final String? errorMessage,
  });
}
