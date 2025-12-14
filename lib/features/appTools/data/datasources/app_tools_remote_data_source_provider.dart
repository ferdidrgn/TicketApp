import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_provider.dart';
import 'app_tools_remote_data_source_and_impl.dart';

final appToolsRemoteDataSourceProvider =
    Provider<AppToolsRemoteDataSource>((final ref) {
  final firestore = ref.watch(firestoreProvider);

  return AppToolsRemoteDataSourceImpl(firestore: firestore);
});
