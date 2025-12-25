import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/login_repository_provider.dart';
import '../../domain/usecases/delete_account_use_case.dart';
import '../../domain/usecases/get_current_user_use_case_impl.dart';
import '../../domain/usecases/sign_in_anonymously_use_case.dart';
import '../../domain/usecases/sign_in_with_google_use_case_impl.dart';
import '../../domain/usecases/sign_out_use_case_impl.dart';
import '../../domain/usecases/verify_otp_use_case_impl.dart';
import '../../domain/usecases/verify_phone_use_case_impl.dart';
import 'login_notifier.dart';
import 'login_state.dart';

/// Ana Login Notifier Provider
final loginProvider =
    NotifierProvider.autoDispose<LoginNotifier, LoginState>(LoginNotifier.new);

// İşlem durumu için yeni provider
final loginProcessingProvider = StateProvider<bool>((final ref) => false);

/// Use case provider’ları
final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>(
  (final ref) =>
      SignInWithGoogleUseCaseImpl(ref.watch(loginRepositoryProvider)),
);

final signOutUseCaseProvider = Provider<SignOutUseCase>(
  (final ref) => SignOutUseCaseImpl(ref.watch(loginRepositoryProvider)),
);

final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>(
  (final ref) => DeleteAccountUseCaseImpl(ref.watch(loginRepositoryProvider)),
);

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>(
  (final ref) => GetCurrentUserUseCaseImpl(ref.watch(loginRepositoryProvider)),
);

final verifyPhoneUseCaseProvider = Provider<VerifyPhoneUseCase>(
  (final ref) => VerifyPhoneUseCaseImpl(ref.watch(loginRepositoryProvider)),
);

final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>(
  (final ref) => VerifyOtpUseCaseImpl(ref.watch(loginRepositoryProvider)),
);

// Yeni use case'ler ekleyin
final signInAnonymouslyUseCaseProvider = Provider<SignInAnonymouslyUseCase>(
  (final ref) =>
      SignInAnonymouslyUseCaseImpl(ref.watch(loginRepositoryProvider)),
);
