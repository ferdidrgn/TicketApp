import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/players/data/datasources/player_remote_data_source_and_impl.dart';
import '../../../../core/services/firestore_provider.dart';

final playerRemoteDataSourceProvider =
    Provider<PlayerRemoteDataSource>((final ref) {
  final firestore = ref.watch(firestoreProvider);

  return PlayerRemoteDataSourceImpl(firestore: firestore);
});
