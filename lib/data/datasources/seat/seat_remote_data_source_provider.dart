import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/data/datasources/seat/seat_remote_data_source_and_impl.dart';
import '../../../core/services/firestore_provider.dart';

final seatRemoteDataSourceProvider =
    Provider<SeatRemoteDataSource>((final ref) {
  final firestore = ref.watch(firestoreProvider);

  return SeatRemoteDataSourceImpl(firestore: firestore);
});
