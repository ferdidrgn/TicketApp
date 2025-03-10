import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/appTools/get_privacy_policy_use_case_impl.dart';
import '../../../domain/useCase/appTools/get_terms_condition_use_case_impl.dart';
import 'app_tools_state.dart';

class AppToolsNotifier extends StateNotifier<AppToolsState> {
  final GetPrivacyPolicyUseCase getPrivacyPolicyUseCase;
  final GetTermsConditionUseCase getTermsConditionUseCase;

  AppToolsNotifier(
    this.getPrivacyPolicyUseCase,
    this.getTermsConditionUseCase,
  ) : super(AppToolsState());

  Future<void> fetchPrivacyPolicy() async {
    state = state.copyWith(isLoading: true);
    final result = await getPrivacyPolicyUseCase.call();
    result.fold(
      (final failure) => state =
          state.copyWith(isLoading: false, errorMessage: failure.message),
      (final policy) =>
          state = state.copyWith(isLoading: false, privacyPolicy: policy),
    );
  }

  Future<void> fetchTermsCondition() async {
    state = state.copyWith(isLoading: true);
    final result = await getTermsConditionUseCase.call();
    result.fold(
      (final failure) => state =
          state.copyWith(isLoading: false, errorMessage: failure.message),
      (final terms) =>
          state = state.copyWith(isLoading: false, termsCondition: terms),
    );
  }
}
