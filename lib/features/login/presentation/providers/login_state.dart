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
    super.isLoading = false,
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
    final String? loginMethod,
    final String? userRole,
    final bool? isPersisted,
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
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  bool get isLoggedIn => user != null;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  // ✅ RoleManager ile rol kontrolleri
  bool get isAdmin => RoleManager.isAdmin(userRole);

  bool get isPremium => RoleManager.isPremium(userRole);

  bool get isRegularUser => RoleManager.isUser(userRole);

  bool get isGuestUser => RoleManager.isGuest(userRole);

  String get roleDisplayName => RoleManager.getRoleDisplayName(userRole);

  // ✅ BASİTLEŞTİRİLMİŞ fromLocalStorage - YENİ LOCALSTORAGE'A GÖRE
  factory LoginState.fromLocalStorage() {
    try {
      final isLoggedIn = LocalStorageService.isLoggedIn;
      if (!isLoggedIn) return LoginState();

      return LoginState(
        isPersisted: true,
        isGuest: false,
        userRole: LocalStorageService.userRole, // ✅ Direkt getter kullan
      );
    } catch (e) {
      // Eğer LocalStorageService initialize edilmemişse boş state döndür
      return LoginState();
    }
  }

  // ✅ DEBUG için toString
  @override
  String toString() => 'LoginState{'
      'users: ${user?.uid}, '
      'isGuest: $isGuest, '
      'userRole: $userRole, '
      'isPersisted: $isPersisted, '
      'isLoading: $isLoading, '
      'errorMessage: $errorMessage'
      '}';
}
