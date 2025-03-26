import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/data/datasources/show/show_remote_data_source_and_impl.dart';
import '../../../core/services/firestore_provider.dart';
import '../../../core/services/storage_provider.dart';

final showRemoteDataSourceProvider =
    Provider<ShowRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(storageProvider);

  return ShowRemoteDataSourceImpl(firestore: firestore, storage: storage);
});
