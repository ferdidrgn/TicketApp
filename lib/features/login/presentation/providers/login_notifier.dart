import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ticketapp/core/common/base_notifier.dart';
import 'package:ticketapp/core/services/local_storage_service.dart';
import 'package:ticketapp/core/util/role_manager.dart';
import 'login_provider.dart';
import 'login_state.dart';

class LoginNotifier extends BaseNotifier<LoginState> {
  StreamSubscription<User?>? _authStateSubscription;

  @override
  LoginState build() {
    // 1. Başlangıçta Loading durumunda başla
    state = LoginState(isLoading: true);

    // 2. Başlatma işlemini tetikle
    Future.microtask(() => initialize());

    return state;
  }

  // BaseNotifier zorunluluğu
  @override
  LoginState initialState() => LoginState(isLoading: true);

  Future<void> initialize() async {
    await LocalStorageService.init();

    // 🔥 KESİN ÇÖZÜM: Firebase'i Canlı Dinle
    // Manuel kontrol yerine Firebase'e "Durum değişince haber ver" diyoruz.
    _authStateSubscription?.cancel();
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (final User? firebaseUser) async {
        if (firebaseUser != null) {
          // ✅ KULLANICI BULUNDU (Anonymous veya Normal)
          // LocalStorage'daki rol bilgisini al veya varsayılan ata
          String userRole = LocalStorageService.userRole ?? 'user';

          // Eğer anonymous ise ve rol atanmamışsa guest yap
          if (firebaseUser.isAnonymous) {
            userRole = RoleManager.getDefaultRoleForLoginMethod('anonymous');
          }

          // State'i güncelle ve içeri al
          state = state.copyWith(
            user: firebaseUser,
            isLoading: false,
            // Yükleme bitti
            isGuest: firebaseUser.isAnonymous,
            userRole: userRole,
            errorMessage: null,
          );

          // Bilgileri tazele
          await LocalStorageService.saveEssentialUserData(
            uid: firebaseUser.uid,
            displayName: firebaseUser.displayName,
            role: userRole,
          );
        } else {
          // ❌ KULLANICI YOK (Çıkış Yapılmış)
          // Yüklemeyi bitir ki Router 'Login' sayfasına yönlendirebilsin
          state = state.copyWith(user: null, isLoading: false, isGuest: false);
        }
      },
      onError: (error) {
        // Hata olsa bile loading'i kapat ki sonsuz döngü olmasın
        state =
            state.copyWith(isLoading: false, errorMessage: error.toString());
      },
    );

    // ⚠️ EMNİYET SÜBAPI: Eğer Firebase çok geç cevap verirse (internet yoksa)
    // 4 saniye sonra hala loading ise manuel kapat.
    Future.delayed(const Duration(seconds: 4), () {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    });
  }

  // --- DİĞER METODLAR (Senin Kodların) ---

  Future<void> signInWithGoogle() => execute(
        () => ref.read(signInWithGoogleUseCaseProvider).call(),
        onSuccess: (final googleUser) => _handleGoogleSignInSuccess(googleUser),
      );

  Future<void> _handleGoogleSignInSuccess(
      final GoogleSignInAccount? googleUser) async {
    // Not: Google girişi başarılı olunca yukarıdaki 'authStateChanges' tetiklenecek
    // ve state'i otomatik güncelleyecek. Biz sadece ekstra işlemleri yapalım.
    state = state.copyWith(googleUser: googleUser);

    // Auth state listener zaten yakalayacak ama biz süreci hızlandırmak için tetikleyebiliriz
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userRole = RoleManager.getDefaultRoleForLoginMethod('google');
      await LocalStorageService.saveEssentialUserData(
          uid: currentUser.uid,
          displayName: currentUser.displayName,
          role: userRole);
    }
  }

  Future<void> signInAnonymously() => execute(
        () => ref.read(signInAnonymouslyUseCaseProvider).call(),
        onSuccess: (final user) {
          // Auth Listener bunu yakalayacak, burası boş kalabilir veya log atabilirsin
        },
      );

  Future<void> verifyPhone({
    required final String phoneNumber,
    required final Function(PhoneAuthCredential) onVerificationCompleted,
    required final Function(String, int?) onCodeSent,
    required final Function(String) onAutoRetrievalTimeout,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await ref.read(verifyPhoneUseCaseProvider).call(
          phoneNumber: phoneNumber,
          onVerificationCompleted: onVerificationCompleted,
          onCodeSent: onCodeSent,
          onAutoRetrievalTimeout: onAutoRetrievalTimeout,
        );
    result.fold(
      (final failure) => state =
          state.copyWith(isLoading: false, errorMessage: failure.message),
      (final verificationId) => state = state.copyWith(
        isLoading: false,
        verificationId: verificationId,
        isCodeSent: true,
        errorMessage: null,
      ),
    );
  }

  Future<void> verifyOtp(final String otp) => execute(
        () {
          if (state.verificationId == null)
            throw Exception('Verification ID not found');
          return ref
              .read(verifyOtpUseCaseProvider)
              .call(state.verificationId!, otp);
        },
        onSuccess: (final success) {
          if (!success) state = state.copyWith(errorMessage: "Invalid OTP");
          // Başarılıysa Auth Listener yakalar
        },
      );

  Future<void> updateUserRole(final String newRole) async {
    if (state.user != null) {
      await LocalStorageService.saveEssentialUserData(
        uid: state.user!.uid,
        displayName: state.user!.displayName,
        role: newRole,
      );
      state = state.copyWith(userRole: newRole);
    }
  }

  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true); // Çıkarken loading göster
      await ref.read(signOutUseCaseProvider).call();
      // Auth Listener null user'ı yakalayacak ve state'i sıfırlayacak
    } catch (e) {
      state =
          state.copyWith(isLoading: false, errorMessage: 'Çıkış hatası: $e');
    }
  }

  Future<void> deleteAccount() => execute(
        () async {
          if (state.user == null) throw Exception('User ID not found');
          return await ref.read(deleteAccountUseCaseProvider).call();
        },
        onSuccess: (final success) async {
          await LocalStorageService.clearAllUserData();
          // Auth Listener yakalar
        },
      );

  void clearLoginState() {
    // State'i tamamen sıfırla ve loading'i kapat
    state = LoginState(
      user: null,
      isLoading: false, // Sonsuz loading'i kırmak için false yapıyoruz
      isGuest: false,
      errorMessage: null,
      // Diğer alanlar zaten varsayılan null gelir
    );
  }
}
