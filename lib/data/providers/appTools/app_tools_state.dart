import 'package:ticketapp/core/common/base_state.dart';

class AppToolsState extends BaseState{
  String? privacyPolicy;
  String? termsCondition;

  AppToolsState({
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
  }) {
    return AppToolsState(
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      termsCondition: termsCondition ?? this.termsCondition,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
