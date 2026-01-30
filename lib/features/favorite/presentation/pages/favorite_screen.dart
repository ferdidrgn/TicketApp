import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ticketapp/core/base/base_page_wrapper.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return DefaultTabController(
      length: 3,
      child: BasePageWrapper(
        title: 'KOLEKSİYONUM',
        subtitle: 'Kalbinde yer eden tüm sahneler...',
        showBackButton: true,
        rightIcon: Icons.favorite_rounded,
        layoutConfig: BasePageLayoutConfig(
          backgroundColor: context.colors.surface,
          safeAreaTop: true,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: isLargeScreen ? 1200 : double.infinity),
            child: Column(
              children: [
                // 1. MODERNIZE EDILMIŞ TAB SEÇİCİ
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: _FavoriteTabSelector(controller: _tabController),
                ),

                // 2. RESPONSIVE GRID ALANI
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildResponsiveGrid(context, type: 'shows'),
                      _buildResponsiveGrid(context, type: 'stages'),
                      _buildResponsiveGrid(context, type: 'players'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MERKEZİ RESPONSIVE GRID YÖNETİMİ ---
  Widget _buildResponsiveGrid(final BuildContext context,
      {required final String type}) {
    // 💡 Ekran genişliğine göre sütun sayısı: Mobil 2, Tablet 3, Web 4-5
    final int crossAxisCount =
        context.responsive(mobile: 2, tablet: 3, desktop: 4);
    final double aspectRatio = type == 'shows' ? 0.75 : 1.1;

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: aspectRatio,
      ),
      itemCount: 8,
      // Dinamik veri gelecek
      itemBuilder: (final context, final index) {
        if (type == 'shows') return _buildShowItem(context, index);
        if (type == 'stages') return _buildStageItem(context, index);
        return _buildPlayerItem(context, index);
      },
    );
  }

  Widget _buildShowItem(final BuildContext context, final int index) =>
      ShowCard(
        imageUrl:
            'https://tiyatrolar.com.tr/files/activity/g/gozlerimi-kaparim-vazifemi-yaparim-4/gallery/24624/gozlerimi-kaparim-vazifemi-yaparim-4-24624.jpg',
        gameName: 'Favori Oyun $index',
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (final _) => const ShowDetailPage(showId: '0')));
        },
      );

  Widget _buildStageItem(final BuildContext context, final int index) =>
      CustomStageCard(
        text: 'Sahne $index',
        imageUrl:
            'https://enstitu.ibb.istanbul/files/ismekOrg/Image/img_brans/brans_yenisitegaleri/drama/1-600.jpg',
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (final _) => const StageDetailPage(stageId: '0')));
        },
      );

  Widget _buildPlayerItem(final BuildContext context, final int index) =>
      CustomStageCard(
        text: 'Sanatçı $index',
        imageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT-cV2ZIk5Wi_uoyY1PdDVM2vFzuSMQATw7iw&s',
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (final _) => const PlayerDetailPage(playerId: "0")));
        },
      );
}

// --- TAB SEÇİCİ BİLEŞENİ ---
class _FavoriteTabSelector extends StatelessWidget {
  final TabController controller;

  const _FavoriteTabSelector({required this.controller});

  @override
  Widget build(final BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: context.colors.outlineVariant.withOpacity(0.5)),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              context.colors.primary,
              context.colors.primary.withOpacity(0.8)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: context.colors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        labelColor: context.colors.onPrimary,
        unselectedLabelColor: context.colors.onSurfaceVariant,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: "Oyunlar"),
          Tab(text: "Sahneler"),
          Tab(text: "Sanatçılar"),
        ],
      ),
    );
  }
}
