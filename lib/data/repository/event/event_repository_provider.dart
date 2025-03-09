import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/domain/repository/event_repository.dart';
import '../../../core/network/internet_service_provider.dart';
import '../../datasources/event/event_remote_data_source_provider.dart';
import 'event_repository_impl.dart';

final eventRepositoryProvider = Provider<EventRepository>((final ref) {
  final remoteDataSource = ref.watch(eventRemoteDataSourceProvider);
  final internetService = ref.watch(internetServiceProvider);

  return EventRepositoryImpl(
    remoteDataSource: remoteDataSource,
    internetService: internetService,
  );
});
