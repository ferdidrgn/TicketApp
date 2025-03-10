class AppToolsState {
  final String? privacyPolicy;
  final String? termsCondition;
  final bool isLoading;
  final String? errorMessage;

  AppToolsState({
    this.privacyPolicy,
    this.termsCondition,
    this.isLoading = false,
    this.errorMessage,
  });

  AppToolsState copyWith({
    final String? privacyPolicy,
    final String? termsCondition,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return AppToolsState(
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      termsCondition: termsCondition ?? this.termsCondition,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
