import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/domain/entities/show.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/hero_video_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/theatre_game_slider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../data/providers/show/show_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  final VoidCallback onDiscoverPlays;

  const HomePage({super.key, required this.onDiscoverPlays});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _loadAllData();
    });
  }

  void _loadAllData() => ref.read(showProvider.notifier).loadShows(true);

  @override
  Widget build(final BuildContext context) {
    final showState = ref.watch(showProvider);

    if (showState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (showState.hasError) {
      return Center(
        child: Text(
          showState.errorMessage ?? 'Bir hata oluştu',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          HeroVideoSection(),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Hikayelerimizle kalplere dokunuyor, sanatla hayata anlam katıyoruz',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: AppWebLightColors.whiteText.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: widget.onDiscoverPlays,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppWebLightColors.primaryGold,
              foregroundColor: AppWebLightColors.darkBlueBackground,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 10,
            ),
            child: const Text(
              'OYUNLARIMIZI KEŞFEDİN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 40),
          TheaterGamesSlider(shows: showState.dataList!.cast<Show>()),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
