import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/stages/data/datasources/stage_remote_data_source_and_impl.dart';
import '../../../../core/services/firestore_provider.dart';

final stageRemoteDataSourceProvider =
    Provider<StageRemoteDataSource>((final ref) {
  final firestore = ref.watch(firestoreProvider);

  return StageRemoteDataSourceImpl(firestore: firestore);
});
