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

  /// Dış çerçeve köşeleri — sade, mevcut `AppRadius` ölçeğinden. Posterin
  /// kendisi artık aşağıdaki `_VesicaClipper` ile "zeytin yaprağı/göz"
  /// (vesica piscis: üstte ve altta sivri, ortada geniş) şeklinde
  /// kırpılıyor, bu yüzden dış çerçevenin köşeleri artık sade tutuluyor —
  /// iki farklı "iddialı" köşe dili (eskiden hem dış çerçevede büyük tek
  /// köşe hem şimdi posterde göz şekli) üst üste binmesin diye.
  static const BorderRadius _cardRadius = BorderRadius.all(
    Radius.circular(AppRadius.md),
  );

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
            borderRadius: _cardRadius,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 DÜZELTME: Rozetler eskiden posterin üzerinde iki ayrı
              // köşede (sol-üst yığın + sağ-üst "YENİ") kayan/örtüşen
              // Positioned'lardı — dar (2 sütunlu mobil ızgara gibi)
              // kartlarda "BAŞKA PLATFORMDA" + "YENİ" aynı anda varken
              // metinler birbirine giriyordu. Artık TEK bir satırda,
              // posterin ÜSTÜNDE (kartın kendi koyu zemininde, görsele
              // binmeden) — hiçbir zaman çakışamaz, kart ne kadar dar
              // olursa olsun `Wrap` bir sonraki satıra sarar.
              if (badges.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: badges,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs),
                  child: ClipPath(
                    clipper: const _VesicaClipper(),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Ana poster (her zaman görünür taban katman).
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
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      show.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WebColors.whiteText,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 🔥 DÜZELTME: Ne `show.duration` ("2 perde / 145dk"
                    // gibi) ne de `show.ageLimit` metni hiçbir esnek/ellipsis
                    // koruması olmadan sabit bir Row'a yazılıyordu — kart dar
                    // ekranlarda (ör. ana sayfa mobil şeridi) bu iki metin
                    // birlikte sığmayınca "RenderFlex overflowed" hatasıyla
                    // sağdan taşıyordu. Süre metni (daha değişken/uzun
                    // olan) artık Flexible + ellipsis; yaş sınırı rozeti de
                    // aynı korumayla güvence altına alındı.
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: WebColors.textTertiary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            show.duration,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: WebColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (show.ageLimit.trim().isNotEmpty) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.shield_outlined,
                              size: 13, color: WebColors.textTertiary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              show.ageLimit,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: WebColors.textSecondary,
                                fontSize: 12,
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

/// 🫒 "Zeytin yaprağı / göz" kırpıcı (vesica piscis) — üstte ve altta tek
/// bir sivri uçta buluşan, dikey ortada en geniş noktasına ulaşan iki
/// kavisten oluşan klasik bir şekil. Kesin geometri (iki simetrik
/// kuadratik Bezier eğrisi, kontrol noktaları kutunun dışına taşacak
/// şekilde yerleştirilmiş — bkz. aşağıdaki matematik) — elle "çizilmiş"
/// belirsiz bir path DEĞİL, bu yüzden render önizlemesi olmadan da
/// güvenle uygulanabilir.
class _VesicaClipper extends CustomClipper<Path> {
  const _VesicaClipper();

  @override
  Path getClip(final Size size) {
    final w = size.width;
    final h = size.height;
    // Kontrol noktası w*1.4 / w*-0.4 iken kavisin orta noktası (t=0.5)
    // yaklaşık x = 0.25*(w/2) + 0.5*cx + 0.25*(w/2) formülüyle kutunun
    // sol/sağ kenarına çok yakın (~%95) oluyor — köşe boşluğu bırakmadan
    // ama kenardan taşırmadan.
    final path = Path()
      ..moveTo(w / 2, 0)
      ..quadraticBezierTo(w * 1.4, h / 2, w / 2, h)
      ..quadraticBezierTo(w * -0.4, h / 2, w / 2, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant final CustomClipper<Path> oldClipper) => false;
}
