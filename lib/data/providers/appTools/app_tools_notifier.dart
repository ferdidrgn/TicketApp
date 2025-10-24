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

  Future<void> fetchPrivacyPolicy() async {
    await executeWithInternetCheck(
      () => ref.read(getPrivacyPolicyUseCaseProvider).call(),
      onSuccess: (final policy) {
        if (policy != state.privacyPolicy) {
          state = state.copyWith(privacyPolicy: policy);
        }
      },
    );
  }

  Future<void> fetchTermsCondition() async {
    await executeWithInternetCheck(
      () => ref.read(getTermsConditionUseCaseProvider).call(),
      onSuccess: (final terms) {
        if (terms != state.termsCondition) {
          state = state.copyWith(termsCondition: terms);
        }
      },
    );
  }
}

/// AppToolsState için yardımcı metodlar
extension AppToolsStateX on AppToolsState {
  // Condit,on, var mı diye kontrol eder.// null değilse ve boş değilse true döner.
  bool get hasPrivacy => privacyPolicy != null && privacyPolicy!.isNotEmpty;
  bool get hasTerms => termsCondition != null && termsCondition!.isNotEmpty;

  /// Hangi veri varsa döndüren genel helper
  String get privacyOrEmpty => privacyPolicy ?? '';
  String get termsOrEmpty => termsCondition ?? '';
}
