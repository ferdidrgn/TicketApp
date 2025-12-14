import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/teams/data/datasources/team_remote_data_source_and_impl.dart';
import '../../../../core/services/firestore_provider.dart';

final teamRemoteDataSourceProvider =
Provider<TeamRemoteDataSource>((final ref) {
  final firestore = ref.watch(firestoreProvider);

  return TeamRemoteDataSourceImpl(firestore: firestore);
});
