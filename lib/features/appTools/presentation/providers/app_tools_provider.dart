import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/app_tools_repository_provider.dart';
import '../../domain/usecases/get_privacy_policy_use_case_impl.dart';
import '../../domain/usecases/get_terms_condition_use_case_impl.dart';

part 'app_tools_provider.g.dart';

// --- UseCase Provider'ları ---

@riverpod
GetPrivacyPolicyUseCase getPrivacyPolicyUseCase(final Ref ref) =>
    GetPrivacyPolicyUseCaseImpl(ref.watch(appToolsRepositoryProvider));

@riverpod
GetTermsConditionUseCase getTermsConditionUseCase(final Ref ref) =>
    GetTermsConditionUseCaseImpl(ref.watch(appToolsRepositoryProvider));

// --- Ana Veri Kaynakları (Doğrudan Veri Çekimi) ---

@riverpod
Future<String?> privacyPolicy(final Ref ref) =>
    ref.watch(getPrivacyPolicyUseCaseProvider).call().getOrThrow();

@riverpod
Future<String?> termsCondition(final Ref ref) =>
    ref.watch(getTermsConditionUseCaseProvider).call().getOrThrow();
