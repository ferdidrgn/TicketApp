import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_provider.dart';
import 'event_remote_data_source_and_impl.dart';

final eventRemoteDataSourceProvider =
    Provider<EventRemoteDataSource>((final ref) {
  final firestore = ref.watch(firestoreProvider);

  return EventRemoteDataSourceImpl(firestore: firestore);
});
