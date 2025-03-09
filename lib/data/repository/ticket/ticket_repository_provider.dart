import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/internet_service_provider.dart';
import '../../../domain/repository/ticket_repository.dart';
import '../../datasources/ticket/ticket_remote_data_source_provider.dart';
import 'ticket_repository_impl.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((final ref) {
  final remoteDataSource = ref.watch(ticketRemoteDataSourceProvider);
  final internetService = ref.watch(internetServiceProvider);

  return TicketRepositoryImpl(
    remoteDataSource: remoteDataSource,
    internetService: internetService,
  );
});
