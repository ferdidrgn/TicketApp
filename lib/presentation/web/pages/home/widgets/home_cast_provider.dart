import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../data/datasources/show/show_remote_data_source_and_impl.dart';
import '../../../../../../data/providers/player/player_provider.dart';
import '../../../../../../domain/entities/player.dart';

final homeCastProvider = FutureProvider.autoDispose<List<Player>>((final ref) async {
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;

  final showService =
      ShowRemoteDataSourceImpl(firestore: firestore, storage: storage);

  // Home sayfasındaki spesifik oyunun ID'si
  final shows = await showService.getShowsByIds(["XqKkUbIflyWxZbNLZvqV"]);

  if (shows.isNotEmpty && shows.first.nowPlayersId != null) {
    final playerIds = shows.first.nowPlayersId!.cast<String>();

    final getPlayerByIdUseCase = ref.read(getPlayerByIdUseCaseProvider);

    // HATA DÜZELTMESİ BURADA:
    // Dönen veriyi açıkça 'List<Player>?' olarak cast ediyoruz.
    final players = await getPlayerByIdUseCase.call(playerIds) as List<Player>?;

    // Eğer null gelirse boş liste döndür
    return players ?? [];
  }

  return [];
});
