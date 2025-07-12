import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/internet_service_provider.dart';
import '../../../domain/useCase/login/get_current_user_use_case_impl.dart';
import '../../../domain/useCase/login/sign_in_with_google_use_case_impl.dart';
import '../../../domain/useCase/login/sign_out_use_case_impl.dart';
import '../../../domain/useCase/login/verify_otp_use_case_impl.dart';
import '../../../domain/useCase/login/verify_phone_use_case_impl.dart';
import '../../repository/login/login_repository_provider.dart';
import 'login_notifier.dart';
import 'login_state.dart';

final loginProvider =
    StateNotifierProvider<LoginNotifier, LoginState>((final ref) {
  return LoginNotifier(
    ref.read(internetServiceProvider),
    SignInWithGoogleUseCaseImpl(ref.watch(loginRepositoryProvider)),
    SignOutUseCaseImpl(ref.watch(loginRepositoryProvider)),
    GetCurrentUserUseCaseImpl(ref.watch(loginRepositoryProvider)),
    VerifyPhoneUseCaseImpl(ref.watch(loginRepositoryProvider)),
    VerifyOtpUseCaseImpl(ref.watch(loginRepositoryProvider)),
  );
});
