import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/data/repository/seat/seat_repository_impl.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../domain/repository/seat_repository.dart';
import '../../datasources/seat/seat_remote_data_source_provider.dart';

final seatRepositoryProvider = Provider<SeatRepository>((final ref) {
  final remoteDataSource = ref.watch(seatRemoteDataSourceProvider);
  //final internetService = ref.watch(internetServiceProvider);

  return SeatRepositoryImpl(
    remoteDataSource: remoteDataSource,
    //internetService: internetService,
  );
});
