import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/tickets/data/datasources/ticket_remote_data_source_and_impl.dart';
import '../../../../core/services/firestore_provider.dart';

final ticketRemoteDataSourceProvider =
Provider<TicketRemoteDataSource>((final ref) {
  final firestore = ref.watch(firestoreProvider);

  return TicketRemoteDataSourceImpl(firestore: firestore);
});
