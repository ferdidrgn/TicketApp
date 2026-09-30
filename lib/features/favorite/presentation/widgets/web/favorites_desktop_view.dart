import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../discovery/presentation/widgets/browse_controls.dart';
import '../../../../settings/presentation/widgets/preference_widgets.dart';
import '../../../../users/domain/entities/user.dart' as entity;
import '../../../../users/presentation/providers/user_provider.dart';
import '../favorite_collections.dart';

// =============================================================================
// MASAÜSTÜ (WEB) FAVORİLER
// =============================================================================
//
// Yapı: "kenar çubuğu + sütun" (Keşfet ile aynı aile). Solda sayfa başlığı,
// gerçek sayılarla özet ve tür seçici (Oyunlar / Sahneler / Sanatçılar);
// sağda seçili türün içeriği kendi içinde kayar. Sabit görüntü alanlı bir
// sayfa — Footer yok (bkz. CLAUDE.md).
//
// `BasePageWrapper` kullanılmıyor ve rota bir kabuğun içinde değil → sayfa
// kendi `Scaffold`'unu kurar ve kendi geri butonunu taşır. (Önceki hâlinde
// ikisi de yoktu: metinler Material atası olmadan çiziliyor, kullanıcı
// sayfadan geri dönemiyordu.)
//
// Veri mobille birebir aynı: `userProfileProvider` → `User.favorite*`.
class FavoritesDesktopPage extends ConsumerStatefulWidget {
  const FavoritesDesktopPage({super.key});

  @override
  ConsumerState<FavoritesDesktopPage> createState() =>
      _FavoritesDesktopPageState();
}

class _FavoritesDesktopPageState extends ConsumerState<FavoritesDesktopPage> {
  /// Kullanıcı seçene kadar null → ilk dolu tür gösterilir.
  FavoriteKind? _selected;

  List<String> _ids(final entity.User user, final FavoriteKind kind) =>
      switch (kind) {
        FavoriteKind.shows => user.favoriteShows,
        FavoriteKind.stages => user.favoriteStages,
        FavoriteKind.players => user.favoritePlayers,
      };

  FavoriteKind _effective(final entity.User? user) {
    if (_selected != null) return _selected!;
    if (user == null) return FavoriteKind.shows;
    return FavoriteKind.values.firstWhere(
      (final k) => _ids(user, k).isNotEmpty,
      orElse: () => FavoriteKind.shows,
    );
  }

  String? _lede(final entity.User? user) {
    if (user == null) return null;
    final int shows = user.favoriteShows.length;
    final int stages = user.favoriteStages.length;
    final int players = user.favoritePlayers.length;
    if (shows + stages + players == 0) {
      return 'Kalbe dokunduğun oyun, sahne ve sanatçılar burada toplanır.';
    }
    final List<String> parts = [
      if (shows > 0) '$shows oyun',
      if (stages > 0) '$stages sahne',
      if (players > 0) '$players sanatçı',
    ];
    return 'Kenara ayırdıkların: ${parts.join(', ')}.';
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final userAsync = ref.watch(userProfileProvider);
    final entity.User? user = userAsync.value;
    final bool loading = userAsync.isLoading && !userAsync.hasValue;
    final bool failed = !loading && userAsync.hasError && !userAsync.hasValue;
    final FavoriteKind kind = _effective(user);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl,
                  AppSpacing.xxxl, AppSpacing.xxxl, AppSpacing.xxl),
              child: PreferencePageHeading(
                title: 'Favorilerim',
                lede: _lede(user),
                onBack: () => NavigationHandler.smartGoBack(context),
              ),
            ),
            Divider(height: 1, thickness: 1, color: cs.outlineVariant),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 260,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                          AppSpacing.massive, AppSpacing.lg, AppSpacing.xxxl),
                      children: [
                        if (user != null) ...[
                          const BrowseSideLabel('Koleksiyon'),
                          for (final k in FavoriteKind.values)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: BrowseSideOption(
                                label: k.label,
                                icon: k.icon,
                                count: _ids(user, k).length,
                                selected: k == kind,
                                onTap: () => setState(() => _selected = k),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  VerticalDivider(width: 1, thickness: 1, color: cs.outlineVariant),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (final context, final constraints) {
                        // İçerik ~1080px'te sınırlanır; kaydırma çubuğu gerçek sağ
                        // kenarda kalır.
                        final double gutter = math.max(
                            AppSpacing.huge, (constraints.maxWidth - 1080) / 2);
                        final EdgeInsets padding = EdgeInsets.fromLTRB(
                            gutter, AppSpacing.massive, gutter, AppSpacing.section);

                        if (loading) {
                          return FavoriteSkeletonView(
                              layout: FavoriteLayout.desktop, padding: padding);
                        }
                        if (failed || user == null) {
                          return SingleChildScrollView(
                            padding: padding,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: failed
                                  ? FavoriteErrorNotice(
                                      onRetry: () =>
                                          ref.invalidate(userProfileProvider),
                                    )
                                  : const FavoriteSignInNotice(),
                            ),
                          );
                        }
                        return FavoriteKindView(
                          key: ValueKey(kind),
                          kind: kind,
                          ids: _ids(user, kind),
                          layout: FavoriteLayout.desktop,
                          padding: padding,
                          header: BrowseSectionTitle(
                            title: kind.label,
                            count: _ids(user, kind).isEmpty
                                ? null
                                : _ids(user, kind).length,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
