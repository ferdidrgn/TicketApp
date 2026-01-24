import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart'; // getPlayerByIdUseCaseProvider için
import '../../../shows/data/datasources/show_remote_data_source_and_impl.dart';

part 'home_cast_provider.g.dart';

@riverpod
Future<List<Player>> homeCast(final Ref ref) async {
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;

  final showService =
      ShowRemoteDataSourceImpl(firestore: firestore, storage: storage);

  // Örnek oyun ID'si üzerinden oyuncuları çekiyoruz
  final shows = await showService.getShowsByIds(["XqKkUbIflyWxZbNLZvqV"]);

  if (shows.isNotEmpty && shows.first.nowPlayersId != null) {
    final playerIds = shows.first.nowPlayersId!.cast<String>();
    final getPlayerByIdUseCase = ref.read(getPlayerByIdUseCaseProvider);

    final result = await getPlayerByIdUseCase.call(playerIds);

    // Either yapısını çözüyoruz
    return result.fold(
      (final failure) => <Player>[],
      (final players) => players,
    );
  }

  return [];
}
