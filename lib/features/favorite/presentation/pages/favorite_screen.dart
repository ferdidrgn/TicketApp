import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/shared/widgets/top_normal_header.dart';
import '../../../../shared/widgets/background/custom_app_background.dart';
import '../../../players/presentation/pages/player_details.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../shows/presentation/widgets/mobile/show_card.dart';
import '../../../stages/presentation/pages/stage_details.dart';
import '../../../stages/presentation/widgets/mobile/custom_stage_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;

    return Scaffold(
      backgroundColor: themeColors.surface,
      body: CustomAppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Biletlerim sayfasıyla aynı sanatsal header
              const TopNormalHeader(
                title: 'Koleksiyonum',
                subtitle: 'Kalbinde yer eden tüm sahneler...',
                rightIcon: Icons.favorite_rounded,
              ),

              // 3'lü Tab Seçici
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _FavoriteTabSelector(controller: _tabController),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildShowGrid(context),
                    _buildStageGrid(context),
                    _buildPlayerGrid(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- OYUNLAR GRID ---
  Widget _buildShowGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: 6, // Geçici veri
      itemBuilder: (context, index) => ShowCard(
        imageUrl:
            'https://tiyatrolar.com.tr/files/activity/g/gozlerimi-kaparim-vazifemi-yaparim-4/gallery/24624/gozlerimi-kaparim-vazifemi-yaparim-4-24624.jpg',
        gameName: 'Favori Oyun $index',
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ShowDetailPage(showId: '0')));
        },
      ),
    );
  }

  // --- SAHNELER GRID ---
  Widget _buildStageGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: 4, // Geçici veri
      itemBuilder: (context, index) => CustomStageCard(
        text: 'Sahne $index',
        imageUrl:
            'https://enstitu.ibb.istanbul/files/ismekOrg/Image/img_brans/brans_yenisitegaleri/drama/1-600.jpg',
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const StageDetailPage(stageId: '0')));
        },
      ),
    );
  }

  // --- OYUNCULAR GRID ---
  Widget _buildPlayerGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: 5, // Geçici veri
      itemBuilder: (context, index) => CustomStageCard(
        text: 'Sanatçı $index',
        imageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT-cV2ZIk5Wi_uoyY1PdDVM2vFzuSMQATw7iw&s',
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PlayerDetailPage(playerId: "0")));
        },
      ),
    );
  }
}

// ============================================================
// FAVORITE TAB SELECTOR
// ============================================================
class _FavoriteTabSelector extends StatelessWidget {
  final TabController controller;

  const _FavoriteTabSelector({required this.controller});

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: themeColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: themeColors.outlineVariant.withOpacity(0.3)),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [themeColors.primary, themeColors.primaryContainer],
          ),
        ),
        labelColor: themeColors.onPrimary,
        unselectedLabelColor: themeColors.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "Oyunlar"),
          Tab(text: "Sahneler"),
          Tab(text: "Sanatçılar"),
        ],
      ),
    );
  }
}
