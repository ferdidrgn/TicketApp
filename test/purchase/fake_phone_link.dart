import 'package:firebase_auth/firebase_auth.dart' show PhoneAuthCredential;
import 'package:ticketapp/features/auth/data/phone_link_service.dart';

/// Sahte telefon servisi: doğrulama durumu ve eşitleme çağrıları sayılır.
class FakePhoneLink implements PhoneLinkService {
  FakePhoneLink({this.verified = true});

  bool verified;

  /// `refreshAndSync` çağrı sayısı.
  int syncCalls = 0;

  /// `refreshAndSync` içinde çalışır (ör. token "yenilendi", sunucu artık
  /// kabul eder).
  void Function()? onSync;

  @override
  bool get isVerified => verified;

  @override
  String? get phoneNumber => verified ? '+905321234567' : null;

  @override
  bool get hasSignedInUser => true;

  @override
  Future<void> refreshAndSync() async {
    syncCalls++;
    onSync?.call();
  }

  @override
  Future<PhoneSendResult> sendCode(final String e164Phone,
          {final int? resendToken}) =>
      throw UnimplementedError();

  @override
  Future<PhoneLinkOutcome> linkWithCode(
          final String verificationId, final String smsCode) =>
      throw UnimplementedError();

  @override
  Future<PhoneLinkOutcome> linkWithCredential(
          final PhoneAuthCredential credential) =>
      throw UnimplementedError();

  @override
  Future<String?> switchToPhoneAccount(final PhoneAuthCredential credential) =>
      throw UnimplementedError();
}
