import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/shows/domain/entities/show.dart';
import 'optimized_cached_image.dart';

/// Tek, paylaşılan "tiyatro gösterisi" poster kartı.
///
/// Hem web ana sayfasının "Sahnede Bu Sezon" ızgarasında hem de keşif
/// sayfasının kart ızgarasında kullanılan, iki ayrı-ama-neredeyse-aynı
/// kart uygulamasının yerine geçen TEK kaynak. Amaç: iki ızgara da aynı
/// görünüp aynı davransın.
///
/// Hover'da (masaüstü/fare) `show.photosShowId` doluysa, kart bağlanırken
/// bir kez rastgele seçilmiş (mount süresince sabit kalan — her hover'da
/// yeniden ZAR ATILMAZ) bir galeri fotoğrafını, `page_transitions.dart`
/// içindeki `curtainTransition`'ın aynı "perde açılışı" tekniğiyle
/// (`ClipRect` + ortadan büyüyen `Align(widthFactor: ...)`) posterin
/// üzerine açar. `photosShowId` boşsa sadece kaldırma/parlama/kenarlık
/// hover efektleri uygulanır, görsel değişmez — asla kırık/boş görsel
/// göstermez ya da uydurma bir yedek kullanmaz.
class TheatreShowCard extends StatefulWidget {
  final Show show;
  final VoidCallback onTap;

  const TheatreShowCard({
    super.key,
    required this.show,
    required this.onTap,
  });

  @override
  State<TheatreShowCard> createState() => _TheatreShowCardState();
}

class _TheatreShowCardState extends State<TheatreShowCard> {
  bool _hovered = false;

  /// Bu kart örneği bağlı kaldığı sürece sabit kalan, bir kez seçilmiş
  /// "sürpriz" galeri fotoğrafı. `photosShowId` boşsa null kalır.
  String? _revealImageUrl;

  @override
  void initState() {
    super.initState();
    final photos = widget.show.photosShowId;
    if (photos.isNotEmpty) {
      _revealImageUrl = photos[Random().nextInt(photos.length)];
    }
  }

  @override
  Widget build(final BuildContext context) {
    final show = widget.show;
    final hasReveal =
        _revealImageUrl != null && _revealImageUrl != show.imageUrl;
    final badges = _buildBadgeChips(show);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
          decoration: BoxDecoration(
            color: WebColors.darkBlueSurface,
            borderRadius: AppRadius.asymLg,
            border: Border.all(
              color: _hovered
                  ? WebColors.primaryGold.withOpacity(0.45)
                  : WebColors.darkBlueAccent,
              width: 1.2,
            ),
            boxShadow: _hovered
                ? AppShadows.level3(WebColors.primaryGold)
                : AppShadows.level2(WebColors.primaryGold),
          ),
          // 🔥 DÜZELTME: vesica (zeytin yaprağı/göz) şekli — hem sadece
          // posterde hem sonra tüm kartta denendi — dar kartlarda rozet
          // satırını (özellikle "BAŞKA PLATFORMDA" gibi uzun etiketleri)
          // sığdıracak yer bırakmıyordu ve gerçek bir RenderFlex overflow
          // hatasına yol açtı (kullanıcı ekran görüntüsüyle bildirdi).
          // Şekil tamamen kaldırıldı — yerine uygulamanın zaten ~10 dosyada
          // tutarlı kullandığı imza asimetrik köşe (`AppRadius.asymLg`,
          // bkz. `app_radius.dart`) geldi: aynı "sıradan dikdörtgen değil"
          // hissini, poster/rozet/başlık TAM kart genişliğini kullanarak
          // (asla dar bir banda sıkışmadan) veriyor.
          child: ClipRRect(
            borderRadius: AppRadius.asymLg,
            child: LayoutBuilder(
              builder: (final context, final constraints) {
                final cardH = constraints.maxHeight;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Ana poster — tüm kartı uçtan uca dolduran taban
                    // katman.
                    OptimizedCachedImage(
                      imageUrl: show.imageUrl,
                      fit: BoxFit.cover,
                      borderRadius: 0,
                    ),

                    // 2. Hover'da "perde açılışı" ile beliren galeri
                    // fotoğrafı — sadece gerçek galeri verisi varsa.
                    if (hasReveal)
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: _hovered ? 1.0 : 0.0,
                        ),
                        duration: AppMotion.normal,
                        curve: AppMotion.dramatic,
                        builder: (final context, final t, final child) {
                          if (t <= 0) return const SizedBox.shrink();
                          return ClipRect(
                            child: Align(
                              alignment: Alignment.center,
                              widthFactor: t,
                              child: child,
                            ),
                          );
                        },
                        child: SizedBox.expand(
                          child: OptimizedCachedImage(
                            imageUrl: _revealImageUrl!,
                            fit: BoxFit.cover,
                            borderRadius: 0,
                          ),
                        ),
                      ),

                    // 3. Üst hafif vinyet — rozetlerin her fotoğrafın
                    // üzerinde okunur kalması için.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: cardH * 0.32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.45),
                              Colors.black.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 4. Alt karartma — başlık/süre metninin her
                    // fotoğrafın üzerinde okunur kalması için.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: cardH * 0.46,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0),
                              Colors.black.withOpacity(0.9),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 5. Rozetler — kartın TAM genişliğinde, sol hizalı
                    // (dar kartlarda `Wrap` bir alt satıra sarar, asla
                    // çakışmaz/taşmaz).
                    if (badges.isNotEmpty)
                      Positioned(
                        top: AppSpacing.sm,
                        left: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: badges,
                        ),
                      ),

                    // 6. Başlık + süre/yaş sınırı — kartın TAM genişliğinde,
                    // sol hizalı.
                    Positioned(
                      left: AppSpacing.sm,
                      right: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            show.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: WebColors.whiteText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 12, color: WebColors.textTertiary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  show.duration,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: WebColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              if (show.ageLimit.trim().isNotEmpty) ...[
                                const SizedBox(width: 10),
                                const Icon(Icons.shield_outlined,
                                    size: 12, color: WebColors.textTertiary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    show.ageLimit,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: WebColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Rozetleri (harici bilet / yeni / kategori) tek bir listeye toplar —
  /// hiçbiri yoksa boş liste döner ve rozet şeridi hiç render edilmez.
  List<Widget> _buildBadgeChips(final Show show) => [
        // 🔗 Biletleri başka bir platformda satılan "konuk" oyunlar için
        // ayırt edici rozet (mavi).
        if (show.hasExternalTicketing)
          _Chip(
            icon: Icons.open_in_new_rounded,
            label: 'BAŞKA PLATFORMDA',
            background: WebColors.info.withOpacity(0.85),
            border: WebColors.info,
            foreground: Colors.white,
          ),
        // ✨ Son eklenen (son 21 gün) oyunlar için — `show.isRecentlyAdded`
        // gerçek `createdAt`'tan türetilir, uydurma bir "trend" bayrağı
        // yok.
        if (show.isRecentlyAdded)
          _Chip(
            icon: Icons.bolt_rounded,
            label: 'YENİ',
            gradient: const LinearGradient(
                colors: [WebColors.warning, WebColors.primaryGoldLight]),
            foreground: WebColors.veryDarkBlue,
          ),
        if (show.category.isNotEmpty)
          _Chip(
            label: show.category.toUpperCase(),
            background: WebColors.veryDarkBlue.withOpacity(0.72),
            border: WebColors.primaryGold.withOpacity(0.5),
            foreground: WebColors.primaryGoldLight,
          ),
      ];
}

/// Küçük, tek satırlık rozet — ikon opsiyonel, ya düz renk ya gradyan
/// zemin alabilir. `TheatreShowCard`'ın rozet şeridindeki 3 rozet türü
/// (harici bilet/yeni/kategori) bunu paylaşır.
class _Chip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? background;
  final LinearGradient? gradient;
  final Color? border;
  final Color foreground;

  const _Chip({
    this.icon,
    required this.label,
    this.background,
    this.gradient,
    this.border,
    required this.foreground,
  });

  @override
  Widget build(final BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          gradient: gradient,
          borderRadius: AppRadius.asymSm,
          border: border != null ? Border.all(color: border!) : null,
          boxShadow: gradient != null
              ? AppShadows.level1(gradient!.colors.first)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: foreground),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
}

