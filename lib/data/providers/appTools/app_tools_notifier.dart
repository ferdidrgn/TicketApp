import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'app_tools_provider.dart';
import 'app_tools_state.dart';

class AppToolsNotifier extends BaseNotifierWithNetworkChecker<AppToolsState> {
  @override
  AppToolsState initialState() => const AppToolsState();

  @override
  void reloadData() {
    fetchPrivacyPolicy();
    fetchTermsCondition();
  }

  Future<void> fetchPrivacyPolicy() => executeWithInternetCheck(
        () => ref.read(getPrivacyPolicyUseCaseProvider).call(),
        onSuccess: (final policy) {
          if (policy != state.privacyPolicy)
            state = state.copyWith(privacyPolicy: policy);
        },
      );

  Future<void> fetchTermsCondition() => executeWithInternetCheck(
        () => ref.read(getTermsConditionUseCaseProvider).call(),
        onSuccess: (final terms) {
          if (terms != state.termsCondition)
            state = state.copyWith(termsCondition: terms);
        },
      );
}

extension AppToolsStateX on AppToolsState {
  bool get hasPrivacy => privacyPolicy != null;

  bool get hasTerms => termsCondition != null;

  String get lastUpdatedFormatted => lastUpdated != null
      ? '${lastUpdated!.year}-${lastUpdated!.month}-${lastUpdated!.day}'
      : '';
}
