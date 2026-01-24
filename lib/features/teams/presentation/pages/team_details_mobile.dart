import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/custom_description_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/widgets/mobile/show_card.dart';
import '../providers/team_provider.dart';

class TeamDetailsPage extends ConsumerWidget {
  final String teamId;

  const TeamDetailsPage({super.key, required this.teamId});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final teamDetailAsync = ref.watch(teamDetailProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: teamDetailAsync.when(
          data: (final state) => Text(state.team.name),
          loading: () => const Text('Yükleniyor...'),
          error: (final _, final __) => const Text('Hata'),
        ),
        centerTitle: true,
      ),
      body: teamDetailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final err, final stack) => Center(child: Text('Hata: $err')),
        data: (final state) => _buildTeamDetails(context, state),
      ),
    );
  }

  Widget _buildTeamDetails(
      final BuildContext context, final TeamDetailState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildTeamImage(state.team.imageUrl),
          ),
          const SizedBox(height: 16),
          SectionHeader(title: state.team.name, fontSize: 28),
          const SizedBox(height: 16),
          CustomDescriptionCard(
            description: state.team.description.replaceAll('\\n', '\n'),
          ),
          const SizedBox(height: 16),
          if (state.shows.isNotEmpty) ...[
            const SectionHeader(title: 'Gösteriler', fontSize: 20),
            _buildShowList(state.shows),
            const SizedBox(height: 16),
          ],
          if (state.team.photosId.isNotEmpty) ...[
            const SectionHeader(title: 'Takım Fotoğrafları', fontSize: 20),
            _buildPhotosSection(state.team.photosId),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamImage(final String imageUrl) => AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (final context, final url) => const ShimmerLoading(),
            errorWidget: (final context, final url, final error) =>
                const Icon(Icons.error),
          ),
        ),
      );

  Widget _buildShowList(final List<Show> shows) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: shows.length,
        itemBuilder: (final context, final index) =>
            _buildEventCard(context, shows[index]),
      ),
    );
  }

  Widget _buildEventCard(final BuildContext context, final Show show) =>
      GestureDetector(
        child: ShowCard(
          imageUrl: show.imageUrl,
          gameName: show.name,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (final context) => ShowDetailPage(showId: show.id),
              ),
            );
          },
        ),
      );

  Widget _buildPhotosSection(final List<String> photoIds) => SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: photoIds.length,
          itemBuilder: (final context, final index) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CachedNetworkImage(
              imageUrl: photoIds[index],
              placeholder: (final context, final url) => const ShimmerLoading(),
              errorWidget: (final context, final url, final error) =>
                  const Icon(Icons.error),
            ),
          ),
        ),
      );
}
