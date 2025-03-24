import 'package:ticketapp/core/common/base_notifier.dart';
import '../../../domain/useCase/appTools/get_privacy_policy_use_case_impl.dart';
import '../../../domain/useCase/appTools/get_terms_condition_use_case_impl.dart';
import 'app_tools_state.dart';

class AppToolsNotifier extends BaseNotifier<AppToolsState> {
  final GetPrivacyPolicyUseCase getPrivacyPolicyUseCase;
  final GetTermsConditionUseCase getTermsConditionUseCase;

  AppToolsNotifier(
    this.getPrivacyPolicyUseCase,
    this.getTermsConditionUseCase,
  ) : super(AppToolsState()) {
    fetchPrivacyPolicy();
    fetchTermsCondition();
  }

  Future<void> fetchPrivacyPolicy() async {
    await handleOperation(
      () => getPrivacyPolicyUseCase.call(),
      onSuccess: (final policy) =>
          state = state.copyWith(privacyPolicy: policy),
    );
  }

  Future<void> fetchTermsCondition() async {
    await handleOperation(() => getTermsConditionUseCase.call(),
        onSuccess: (final terms) =>
        state = state.copyWith(termsCondition: terms));
  }
}
