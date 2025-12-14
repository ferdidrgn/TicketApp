import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/seat/data/repositories/seat_repository_impl.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../domain/repositories/seat_repository.dart';
import '../datasources/seat_remote_data_source_provider.dart';

final seatRepositoryProvider = Provider<SeatRepository>((final ref) {
  final remoteDataSource = ref.watch(seatRemoteDataSourceProvider);
  //final internetService = ref.watch(internetServiceProvider);

  return SeatRepositoryImpl(
    remoteDataSource: remoteDataSource,
    //internetService: internetService,
  );
});
