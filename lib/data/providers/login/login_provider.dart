import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/login/get_current_user_use_case_impl.dart';
import '../../../domain/useCase/login/sign_in_anonymously_use_case.dart';
import '../../../domain/useCase/login/sign_in_with_google_use_case_impl.dart';
import '../../../domain/useCase/login/sign_out_use_case_impl.dart';
import '../../../domain/useCase/login/verify_otp_use_case_impl.dart';
import '../../../domain/useCase/login/verify_phone_use_case_impl.dart';
import '../../repository/login/login_repository_provider.dart';
import 'login_notifier.dart';
import 'login_state.dart';

/// Ana Login Notifier Provider
final loginProvider = NotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);

/// Use case provider’ları
final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>(
  (final ref) =>
      SignInWithGoogleUseCaseImpl(ref.watch(loginRepositoryProvider)),
);

final signOutUseCaseProvider = Provider<SignOutUseCase>(
  (final ref) => SignOutUseCaseImpl(ref.watch(loginRepositoryProvider)),
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
