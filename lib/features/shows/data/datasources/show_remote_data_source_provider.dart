import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/shows/data/datasources/show_remote_data_source_and_impl.dart';
import '../../../../core/services/firestore_provider.dart';
import '../../../auth/presentation/providers/storage_provider.dart';

final showRemoteDataSourceProvider =
    Provider<ShowRemoteDataSource>((final ref) {
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(storageProvider);

  return ShowRemoteDataSourceImpl(firestore: firestore, storage: storage);
});
