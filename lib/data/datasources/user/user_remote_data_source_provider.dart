import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/data/datasources/user/user_remote_data_source_and_impl.dart';
import '../../../core/services/firestore_provider.dart';

final userRemoteDataSourceProvider =
    Provider<UserRemoteDataSource>((final ref) {
  final firestore = ref.watch(firestoreProvider);

  return UserRemoteDataSourceImpl(firestore: firestore);
});
