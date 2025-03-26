import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/data/datasources/player/player_remote_data_source_and_impl.dart';
import '../../../core/services/firestore_provider.dart';

final playerRemoteDataSourceProvider =
    Provider<PlayerRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return PlayerRemoteDataSourceImpl(firestore: firestore);
});
