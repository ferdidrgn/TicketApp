import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/fcm_manager_service.dart';
import '../../../core/services/local_storage_service.dart';

/// Cloud Functions bölgesi (functions/src/config.js > REGION).
const String _kRegion = 'europe-west1';

/// "DOĞRULANMIŞ TELEFON" kuralı: bilet/rezervasyon telefon numarasına bağlıdır.
/// Telefonla girenler zaten doğrulanmıştır; Google/misafir hesaplar SMS ile
/// telefonu hesaba BAĞLAR (`linkWithCredential`; hesap değişmez).
///
/// KVKK: telefon numarası ve SMS kodu hiçbir yerde log'lanmaz, analytics
/// event'ine yazılmaz.
abstract class PhoneLinkService {
  /// Giriş yapmış Firebase kullanıcısının hesabına doğrulanmış telefon
  /// bağlı mı? (SMS ile girişte ya da `linkWithCredential` sonrası true.)
  bool get isVerified;

  /// Hesaba bağlı telefon (E.164) ya da null.
  String? get phoneNumber;

  /// Giriş yapmış bir Firebase kullanıcısı (misafir dahil) var mı?
  bool get hasSignedInUser;

  /// SMS gönderir. Kod gidince ya da (Android) otomatik doğrulanınca döner.
  Future<PhoneSendResult> sendCode(final String e164Phone,
      {final int? resendToken});

  /// SMS koduyla mevcut hesaba telefonu bağlar.
  Future<PhoneLinkOutcome> linkWithCode(
      final String verificationId, final String smsCode);

  /// Hazır bir kimlik bilgisiyle (otomatik doğrulama) bağlar.
  Future<PhoneLinkOutcome> linkWithCredential(
      final PhoneAuthCredential credential);

  /// "Bu telefon başka hesapta" durumunda, kullanıcı onaylarsa: mevcut
  /// oturum kapatılır ve o telefonla giriş yapılır. Başarısızsa null yerine
  /// hata metni döner.
  Future<String?> switchToPhoneAccount(final PhoneAuthCredential credential);

  /// ID token'ı zorla yeniler (`phone_number` claim'i gelsin) ve sunucuya
  /// `syncPhoneVerification` çağrısı yapar. Hata yutulur, ASLA engellemez.
  Future<void> refreshAndSync();
}

/// [PhoneLinkService.sendCode] sonucu.
class PhoneSendResult {
  final String? verificationId;
  final int? resendToken;

  /// Android anlık/otomatik doğrulama: kod elle girilmeden hazır kimlik bilgisi.
  final PhoneAuthCredential? autoCredential;

  const PhoneSendResult({this.verificationId, this.resendToken, this.autoCredential});
}

sealed class PhoneLinkOutcome {
  const PhoneLinkOutcome();
}

/// Telefon hesaba bağlandı (ya da zaten bağlıydı).
class PhoneLinked extends PhoneLinkOutcome {
  const PhoneLinked();
}

/// Telefon BAŞKA bir hesaba bağlı; [credential] ile o hesaba girilebilir.
class PhoneInUse extends PhoneLinkOutcome {
  final PhoneAuthCredential? credential;
  const PhoneInUse(this.credential);
}

class PhoneLinkError extends PhoneLinkOutcome {
  final String message;
  const PhoneLinkError(this.message);
}

/// Telefonu maskeler: `+905321234567` -> `+90 5** *** ** 67`. Numara
/// ekrana/log'a asla ham basılmaz.
String maskPhone(final String? e164) {
  final raw = (e164 ?? '').replaceAll(RegExp(r'\s'), '');
  if (raw.length < 6) {
    return '';
  }
  final digits = raw.startsWith('+') ? raw.substring(1) : raw;
  if (digits.startsWith('90') && digits.length == 12) {
    return '+90 ${digits[2]}** *** ** ${digits.substring(10)}';
  }
  return '+${digits.substring(0, 2)}${'*' * (digits.length - 4)}${digits.substring(digits.length - 2)}';
}

/// `FirebaseAuthException.code` -> kullanıcıya gösterilecek Türkçe metin.
String phoneAuthErrorMessage(final String code) {
  switch (code) {
    case 'invalid-phone-number':
      return 'Telefon numarası geçersiz. 10 haneli (5XX XXX XX XX) gir.';
    case 'invalid-verification-code':
      return 'SMS kodu hatalı. Kontrol edip tekrar dene.';
    case 'invalid-verification-id':
    case 'session-expired':
      return 'Kodun süresi doldu. Yeniden kod iste.';
    case 'too-many-requests':
      return 'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.';
    case 'quota-exceeded':
      return 'SMS gönderim sınırına ulaşıldı. Daha sonra tekrar dene.';
    case 'network-request-failed':
      return 'Bağlantı sorunu var. İnternetini kontrol edip tekrar dene.';
    case 'user-disabled':
      return 'Bu hesap devre dışı bırakılmış.';
    case 'captcha-check-failed':
    case 'app-not-authorized':
      return 'Güvenlik doğrulaması tamamlanamadı. Uygulamayı güncelleyip tekrar dene.';
    default:
      return 'Telefon doğrulanamadı. Lütfen tekrar dene.';
  }
}

class FirebasePhoneLinkService implements PhoneLinkService {
  final FirebaseAuth? _authOverride;
  final FirebaseFunctions? _functionsOverride;

  FirebasePhoneLinkService({final FirebaseAuth? auth, final FirebaseFunctions? functions})
      : _authOverride = auth,
        _functionsOverride = functions;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instanceFor(region: _kRegion);

  @override
  bool get hasSignedInUser => _auth.currentUser != null;

  @override
  String? get phoneNumber {
    final u = _auth.currentUser;
    if (u == null) {
      return null;
    }
    final p = u.phoneNumber;
    if (p != null && p.isNotEmpty) {
      return p;
    }
    for (final info in u.providerData) {
      if (info.providerId == 'phone' && (info.phoneNumber ?? '').isNotEmpty) {
        return info.phoneNumber;
      }
    }
    return null;
  }

  @override
  bool get isVerified => phoneNumber != null;

  @override
  Future<PhoneSendResult> sendCode(final String e164Phone,
      {final int? resendToken}) {
    final completer = Completer<PhoneSendResult>();
    unawaited(_auth.verifyPhoneNumber(
      phoneNumber: e164Phone,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (final credential) {
        if (!completer.isCompleted) {
          completer.complete(PhoneSendResult(autoCredential: credential));
        }
      },
      verificationFailed: (final e) {
        if (!completer.isCompleted) {
          completer.completeError(PhoneLinkException(phoneAuthErrorMessage(e.code)));
        }
      },
      codeSent: (final id, final token) {
        if (!completer.isCompleted) {
          completer.complete(PhoneSendResult(verificationId: id, resendToken: token));
        }
      },
      codeAutoRetrievalTimeout: (final _) {},
    ).catchError((final Object e) {
      if (!completer.isCompleted) {
        completer.completeError(PhoneLinkException(
            e is FirebaseAuthException
                ? phoneAuthErrorMessage(e.code)
                : phoneAuthErrorMessage('')));
      }
    }));
    return completer.future;
  }

  @override
  Future<PhoneLinkOutcome> linkWithCode(
      final String verificationId, final String smsCode) {
    final credential = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
    return linkWithCredential(credential);
  }

  @override
  Future<PhoneLinkOutcome> linkWithCredential(
      final PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const PhoneLinkError('Önce giriş yapmalısın.');
    }
    try {
      // Hesap DEĞİŞMEZ: misafir verisi / Google hesabı korunur.
      await user.linkWithCredential(credential);
      await user.reload();
      await refreshAndSync();
      return const PhoneLinked();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'provider-already-linked':
          // Bu hesapta zaten bir telefon var: doğrulanmış say, sunucuyu eşitle.
          await refreshAndSync();
          return const PhoneLinked();
        case 'credential-already-in-use':
        case 'account-exists-with-different-credential':
          final c = e.credential;
          return PhoneInUse(c is PhoneAuthCredential ? c : null);
        default:
          return PhoneLinkError(phoneAuthErrorMessage(e.code));
      }
    } catch (_) {
      return PhoneLinkError(phoneAuthErrorMessage(''));
    }
  }

  @override
  Future<String?> switchToPhoneAccount(
      final PhoneAuthCredential credential) async {
    try {
      // Çıkıştan ÖNCE: eski hesabın push token'ı yeni hesaba sızmasın.
      try {
        await FCMManager.instance.detachFromUser();
      } catch (_) {}
      await _auth.signOut();
      await LocalStorageService.clearAllUserData();
      await _auth.signInWithCredential(credential);
      await refreshAndSync();
      return null;
    } on FirebaseAuthException catch (e) {
      return phoneAuthErrorMessage(e.code);
    } catch (_) {
      return phoneAuthErrorMessage('');
    }
  }

  @override
  Future<void> refreshAndSync() async {
    try {
      await _auth.currentUser?.getIdToken(true);
      await _functions.httpsCallable('syncPhoneVerification').call<Object?>();
      // Sunucu claim'i/belgeyi yazdıktan sonra token'ı bir kez daha yenile.
      await _auth.currentUser?.getIdToken(true);
    } catch (e) {
      // Engellemez. Telefon/token içeriği log'lanmaz.
      debugPrint('syncPhoneVerification atlandı: ${e.runtimeType}');
    }
  }
}

class PhoneLinkException implements Exception {
  final String message;
  const PhoneLinkException(this.message);

  @override
  String toString() => message;
}
