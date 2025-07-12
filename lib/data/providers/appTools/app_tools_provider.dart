import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/internet_service_provider.dart';
import '../../../domain/useCase/appTools/get_privacy_policy_use_case_impl.dart';
import '../../../domain/useCase/appTools/get_terms_condition_use_case_impl.dart';
import '../../repository/appTools/app_tools_provider.dart';
import 'app_tools_notifier.dart';
import 'app_tools_state.dart';

final appToolsProvider =
    StateNotifierProvider<AppToolsNotifier, AppToolsState>((final ref) {
  return AppToolsNotifier(
    ref.read(internetServiceProvider),
    GetPrivacyPolicyUseCaseImpl(ref.watch(appToolsRepositoryProvider)),
    GetTermsConditionUseCaseImpl(ref.watch(appToolsRepositoryProvider)),
  );
});
