import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_provider.dart';
import 'campaign_remote_data_source_and_impl.dart';

final campaignRemoteDataSourceProvider =
    Provider<CampaignRemoteDataSource>((final ref) {
  final firestore = ref.watch(firestoreProvider);

  return CampaignRemoteDataSourceImpl(firestore: firestore);
});
