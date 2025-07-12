import '../../../core/common/base_notifier_with_network_checker.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/useCase/appTools/get_privacy_policy_use_case_impl.dart';
import '../../../domain/useCase/appTools/get_terms_condition_use_case_impl.dart';
import 'app_tools_state.dart';

class AppToolsNotifier extends BaseNotifierWithNetworkChecker<AppToolsState> {
  final GetPrivacyPolicyUseCase _getPrivacyPolicyUseCase;
  final GetTermsConditionUseCase _getTermsConditionUseCase;

  AppToolsNotifier(
    final InternetService internetService,
    this._getPrivacyPolicyUseCase,
    this._getTermsConditionUseCase,
  ) : super(internetService, AppToolsState());

  @override
  void reloadData() {
    _fetchPrivacyPolicy();
    _fetchTermsCondition();
  }

  Future<void> _fetchPrivacyPolicy() => executeWithInternetCheck(
        () => _getPrivacyPolicyUseCase.call(),
        onSuccess: (final policy) {
          if (policy != state.privacyPolicy)
            state = state.copyWith(privacyPolicy: policy, errorMessage: null);
        },
      );

  Future<void> _fetchTermsCondition() => executeWithInternetCheck(
        () => _getTermsConditionUseCase.call(),
        onSuccess: (final terms) {
          if (terms != state.termsCondition)
            state = state.copyWith(termsCondition: terms, errorMessage: null);
        },
      );
}
