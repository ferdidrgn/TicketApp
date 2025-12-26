import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/common/base_state.dart';
import '../../../../core/util/role_manager.dart';

class LoginState extends BaseState {
  final User? user;

  // User Info
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String? phoneNumber;
  final String userRole;

  // Phone Verification
  final String? verificationId;
  final bool isCodeSent;
  final int timerValue;
  final bool canResendCode;

  // Flags
  final bool isGuest;
  final bool isAccountDeleted;

  const LoginState({
    this.user,
    super.isLoading = false,
    super.errorMessage,
    this.displayName,
    this.email,
    this.photoUrl,
    this.phoneNumber,
    this.userRole = 'user',
    this.verificationId,
    this.isCodeSent = false,
    this.timerValue = 180,
    this.canResendCode = false,
    this.isGuest = false,
    this.isAccountDeleted = false,
  });

  // ========================================
  // GETTERS
  // ========================================

  /// Is user logged in
  bool get isLoggedIn => user != null;

  /// Has error
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  /// Is admin
  bool get isAdmin => RoleManager.isAdmin(userRole);

  /// Is premium
  bool get isPremium => RoleManager.isPremium(userRole);

  /// Is regular user
  bool get isRegularUser => RoleManager.isUser(userRole);

  /// Is guest user
  bool get isGuestUser => RoleManager.isGuest(userRole);

  /// Role display name
  String get roleDisplayName => RoleManager.getRoleDisplayName(userRole);

  /// Timer text (MM:SS format)
  String get timerText {
    final minutes = (timerValue / 60).floor().toString().padLeft(2, '0');
    final seconds = (timerValue % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// User ID
  String? get userId => user?.uid;

  /// Is phone verified
  bool get isPhoneVerified => user?.phoneNumber != null;

  /// Login method
  String get loginMethod {
    if (user == null) return 'none';
    if (user!.isAnonymous) return 'anonymous';

    for (var provider in user!.providerData) {
      if (provider.providerId == 'google.com') return 'google';
      if (provider.providerId == 'phone') return 'phone';
    }

    return 'unknown';
  }

  // ========================================
  // COPY WITH
  // ========================================

  @override
  LoginState copyWith({
    final User? user,
    final bool? isLoading,
    final String? errorMessage,
    final String? displayName,
    final String? email,
    final String? photoUrl,
    final String? phoneNumber,
    final String? userRole,
    final String? verificationId,
    final bool? isCodeSent,
    final int? timerValue,
    final bool? canResendCode,
    final bool? isGuest,
    final bool? isAccountDeleted,
  }) =>
      LoginState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        userRole: userRole ?? this.userRole,
        verificationId: verificationId ?? this.verificationId,
        isCodeSent: isCodeSent ?? this.isCodeSent,
        timerValue: timerValue ?? this.timerValue,
        canResendCode: canResendCode ?? this.canResendCode,
        isGuest: isGuest ?? this.isGuest,
        isAccountDeleted: isAccountDeleted ?? this.isAccountDeleted,
      );

  // ========================================
  // FACTORY
  // ========================================

  /// Create initial loading state
  factory LoginState.loading() => const LoginState(isLoading: true);

  /// Create logged out state
  factory LoginState.loggedOut() {
    return const LoginState(isLoading: false);
  }

  /// Create from Firebase User
  factory LoginState.fromUser(final User user, final String role) => LoginState(
        user: user,
        isLoading: false,
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoURL,
        phoneNumber: user.phoneNumber,
        userRole: role,
        isGuest: user.isAnonymous,
      );

  // ========================================
  // TO STRING
  // ========================================

  @override
  String toString() => 'LoginState{'
      'userId: ${user?.uid}, '
      'isLoggedIn: $isLoggedIn, '
      'isGuest: $isGuest, '
      'userRole: $userRole, '
      'isLoading: $isLoading, '
      'hasError: $hasError'
      '}';

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is LoginState &&
        other.user?.uid == user?.uid &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.userRole == userRole &&
        other.isGuest == isGuest;
  }

  @override
  int get hashCode => Object.hash(
        user?.uid,
        isLoading,
        errorMessage,
        userRole,
        isGuest,
      );
}
