import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ticketapp/core/common/base_state.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/util/role_manager.dart';

class LoginState extends BaseState {
  final User? user;
  final GoogleSignInAccount? googleUser;
  final String? verificationId;
  final String? phoneNumber;
  final bool isCodeSent;
  final bool isGuest;
  final bool isAccountDeleted;
  final bool isPersisted;
  final String? userRole;
  final int timerValue; // Kalan saniye
  final bool canResendCode; // Yeniden kod gönderilebilir mi?

  LoginState({
    this.user,
    this.googleUser,
    this.verificationId,
    this.phoneNumber,
    this.isCodeSent = false,
    this.isGuest = false,
    this.isAccountDeleted = false,
    this.userRole,
    this.isPersisted = false,
    this.timerValue = 180, // Varsayılan 3 dakika
    this.canResendCode = false,
    super.isLoading = true,
    super.errorMessage,
  });

  @override
  LoginState copyWith({
    final User? user,
    final GoogleSignInAccount? googleUser,
    final String? verificationId,
    final String? phoneNumber,
    final bool? isCodeSent,
    final bool? isGuest,
    final bool? isAccountDeleted,
    final String? userRole,
    final bool? isPersisted,
    final int? timerValue,
    final bool? canResendCode,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      LoginState(
        user: user ?? this.user,
        googleUser: googleUser ?? this.googleUser,
        verificationId: verificationId ?? this.verificationId,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        isCodeSent: isCodeSent ?? this.isCodeSent,
        isGuest: isGuest ?? this.isGuest,
        userRole: userRole ?? this.userRole,
        isAccountDeleted: isAccountDeleted ?? this.isAccountDeleted,
        isPersisted: isPersisted ?? this.isPersisted,
        timerValue: timerValue ?? this.timerValue,
        canResendCode: canResendCode ?? this.canResendCode,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  // --- GETTERLAR (Sınıf İçinde Olmalı) ---
  bool get isLoggedIn => user != null;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  // ✅ RoleManager ile rol kontrolleri
  bool get isAdmin => RoleManager.isAdmin(userRole);

  bool get isPremium => RoleManager.isPremium(userRole);

  bool get isRegularUser => RoleManager.isUser(userRole);

  bool get isGuestUser => RoleManager.isGuest(userRole);

  String get roleDisplayName => RoleManager.getRoleDisplayName(userRole);

  // Sayaç formatı (02:45)
  String get timerText {
    final minutes = (timerValue / 60).floor().toString().padLeft(2, '0');
    final seconds = (timerValue % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // --- FACTORY METODU (Sınıf İçinde Olmalı) ---
  factory LoginState.fromLocalStorage() {
    try {
      final isLoggedIn = LocalStorageService.isLoggedIn;
      if (!isLoggedIn) return LoginState(isLoading: false);

      return LoginState(
        isPersisted: true,
        isGuest: false,
        isLoading: false,
        userRole: LocalStorageService.userRole,
      );
    } catch (e) {
      return LoginState(isLoading: false);
    }
  }

  // ✅ DEBUG için toString
  @override
  String toString() => 'LoginState{'
      'user: ${user?.uid}, '
      'isCodeSent: $isCodeSent, '
      'timerValue: $timerValue, '
      'userRole: $userRole, '
      'isLoading: $isLoading'
      '}';
}
