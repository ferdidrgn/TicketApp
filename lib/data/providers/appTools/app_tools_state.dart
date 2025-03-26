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
    String? privacyPolicy,
    String? termsCondition,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AppToolsState(
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      termsCondition: termsCondition ?? this.termsCondition,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
