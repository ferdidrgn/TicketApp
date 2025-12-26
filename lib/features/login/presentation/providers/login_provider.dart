import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_notifier.dart';
import 'login_state.dart';

/// 🔐 Main Login Provider
///
/// Riverpod 3+ ile NotifierProvider kullanır
/// Auth state her zaman aktif olmalı, bu yüzden autoDispose KULLANMIYORUZ
final loginProvider =
    NotifierProvider.autoDispose<LoginNotifier, LoginState>(LoginNotifier.new);

/// 📊 Derived Providers for Convenience

/// Is user logged in
final isLoggedInProvider = Provider<bool>((final ref) {
  return ref.watch(loginProvider.select((final state) => state.isLoggedIn));
});

/// Is user guest
final isGuestProvider = Provider<bool>((final ref) {
  return ref.watch(loginProvider.select((final state) => state.isGuest));
});

/// User ID
final userIdProvider = Provider<String?>((final ref) {
  return ref.watch(loginProvider.select((final state) => state.userId));
});

/// User role
final userRoleProvider = Provider<String>((final ref) {
  return ref.watch(loginProvider.select((final state) => state.userRole));
});

/// Is admin
final isAdminProvider = Provider<bool>((final ref) {
  return ref.watch(loginProvider.select((final state) => state.isAdmin));
});

/// Is loading
final isAuthLoadingProvider = Provider<bool>((final ref) {
  return ref.watch(loginProvider.select((final state) => state.isLoading));
});

/// Has error
final hasAuthErrorProvider = Provider<bool>((final ref) {
  return ref.watch(loginProvider.select((final state) => state.hasError));
});

/// Error message
final authErrorMessageProvider = Provider<String?>((final ref) {
  return ref.watch(loginProvider.select((final state) => state.errorMessage));
});

/// Login method
final loginMethodProvider = Provider<String>((final ref) {
  return ref.watch(loginProvider.select((final state) => state.loginMethod));
});

/// Display name
final displayNameProvider = Provider<String?>((final ref) {
  return ref.watch(loginProvider.select((final state) => state.displayName));
});

/// Email
final emailProvider = Provider<String?>((final ref) {
  return ref.watch(loginProvider.select((final state) => state.email));
});

/// Photo URL
final photoUrlProvider = Provider<String?>((final ref) {
  return ref.watch(loginProvider.select((final state) => state.photoUrl));
});
