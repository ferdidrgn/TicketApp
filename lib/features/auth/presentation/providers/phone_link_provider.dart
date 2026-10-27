import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/phone_link_service.dart';

// NOT: Bilerek `@riverpod` codegen KULLANILMAZ (build_runner yok); klasik
// Provider API'si.

/// Doğrulanmış telefon servisi (SMS bağlama + sunucu eşitleme). Testlerde
/// sahte bir uygulamayla override edilir.
final phoneLinkServiceProvider =
    Provider<PhoneLinkService>((final ref) => FirebasePhoneLinkService());
