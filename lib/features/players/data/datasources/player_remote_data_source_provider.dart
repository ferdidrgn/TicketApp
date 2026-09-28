import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/players/data/datasources/player_remote_data_source_and_impl.dart';
import '../../../../core/services/firestore_provider.dart';
import '../../../../core/services/storage_provider.dart';

final playerRemoteDataSourceProvider =
    Provider<PlayerRemoteDataSource>((final ref) {
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(storageProvider);

  return PlayerRemoteDataSourceImpl(firestore: firestore, storage: storage);
});
