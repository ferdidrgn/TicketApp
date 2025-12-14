import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../shows/data/datasources/show_remote_data_source_and_impl.dart';

final homeCastProvider =
    FutureProvider.autoDispose<List<Player>>((final ref) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    // 1. Show Servisi (Oyun bilgilerini çekmek için)
    final showService =
        ShowRemoteDataSourceImpl(firestore: firestore, storage: storage);

    // 2. İlgili Oyunun ID'si ile veriyi çek
    final shows = await showService.getShowsByIds(["XqKkUbIflyWxZbNLZvqV"]);

    if (shows.isNotEmpty && shows.first.nowPlayersId != null) {
      // Oyuncu ID'lerini listeye çevir
      final playerIds = shows.first!.nowPlayersId!.cast<String>();

      // UseCase'i çağır
      final getPlayerByIdUseCase = ref.read(getPlayerByIdUseCaseProvider);

      // UseCase bize 'Either' (Kutu) döndürür
      final result = await getPlayerByIdUseCase.call(playerIds);

      // ✅ DÜZELTME BURADA:
      // Either yapısını .fold() ile açıyoruz.
      // Sol taraf (Left) -> Hata durumu
      // Sağ taraf (Right) -> Başarılı veri
      return result.fold(
        (final failure) {
          debugPrint("❌ OYUNCU YÜKLEME HATASI (Failure): $failure");
          return <Player>[]; // Hata varsa boş liste dön
        },
        (final players) {
          return players; // Başarı varsa oyuncu listesini dön
        },
      );
    }

    return [];
  } catch (e, stackTrace) {
    debugPrint("❌ BEKLENMEYEN HATA: $e");
    debugPrint(stackTrace.toString());
    return [];
  }
});
