import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../domain/repository/campaign_repository.dart';
import '../../datasources/campaign/campaign_remote_data_source_provider.dart';
import 'campaign_repository_impl.dart';

final campaignRepositoryProvider = Provider<CampaignRepository>((final ref) {
  final remoteDataSource = ref.watch(campaignRemoteDataSourceProvider);
  //final internetService = ref.watch(internetServiceProvider);

  return CampaignRepositoryImpl(
    remoteDataSource: remoteDataSource,
    //internetService: internetService,
  );
});
