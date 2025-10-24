import 'package:ticketapp/core/common/base_state.dart';

/// Uygulama araçları (gizlilik politikası, şartlar) için state sınıfı
class AppToolsState extends BaseState {
  final String? privacyPolicy;
  final String? termsCondition;

  const AppToolsState({
    this.privacyPolicy,
    this.termsCondition,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  AppToolsState copyWith({
    final String? privacyPolicy,
    final String? termsCondition,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      AppToolsState(
        privacyPolicy: privacyPolicy ?? this.privacyPolicy,
        termsCondition: termsCondition ?? this.termsCondition,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}
