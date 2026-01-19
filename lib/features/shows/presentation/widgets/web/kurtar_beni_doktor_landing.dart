import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';

class KurtarBeniDoktorLanding extends StatelessWidget {
  const KurtarBeniDoktorLanding({super.key});

  // Veri Listesi (Tüm kadro geri getirildi)
  static const List<Map<String, String>> _castMembers = [
    {'name': 'İSKENDER ATİLLA ATASOY', 'role': 'Uyarlayan ve Yöneten'},
    {'name': 'UĞUR KILIÇ', 'role': 'Yönetmen Yard.'},
    {'name': 'EBRU AKKÜN', 'role': 'Yönetmen Yard.'},
    {'name': 'DİLARA SEKMEN', 'role': 'Makyaj'},
    {'name': 'DERYA DİNÇER', 'role': 'Kostüm'},
    {'name': 'SEYİT ÇOLAK', 'role': 'Işık'},
    {'name': 'DUYGU ŞAHİN', 'role': 'Asistan'},
  ];

  @override
  Widget build(final BuildContext context) => Container(
        width: double.infinity,
        color: WebColors.darkBlueBackground,
        // Responsive Utils kullanımı
        padding: context.responsive(
          mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          desktop: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              children: [
                _buildCompactHeader(context),

                SizedBox(
                    height: context.responsive(mobile: 20.0, desktop: 28.0)),

                // Footer mantığıyla layout seçimi
                context.isDesktop
                    ? _buildDesktopLayout(context)
                    : _buildMobileLayout(context),
              ],
            ),
          ),
        ),
      );

  // ─── LAYOUT SEÇENEKLERİ ───

  Widget _buildDesktopLayout(final BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sol taraf: Görsel (Flex 70)
          const Expanded(flex: 70, child: _HeroImageCard()),
          const SizedBox(width: 28),
          // Sağ taraf: Bilgi (Flex 30)
          Expanded(flex: 30, child: _buildInfoSection(context)),
        ],
      );

  Widget _buildMobileLayout(final BuildContext context) => Column(
        children: [
          const _HeroImageCard(),
          const SizedBox(height: 20),
          _buildInfoSection(context),
        ],
      );

  // ─── HEADER BÖLÜMÜ ───

  Widget _buildCompactHeader(final BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(context.borderRadius(1.25)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: context.paddingAll,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(context.borderRadius(1.25)),
              border: Border.all(
                  color: WebColors.primaryGold.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: WebColors.primaryGold.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.theater_comedy,
                        color: WebColors.primaryGold, size: context.iconMedium),
                    const SizedBox(width: 12),
                    Flexible(
                      child: ShaderMask(
                        shaderCallback: (final bounds) => const LinearGradient(
                          colors: [
                            WebColors.primaryGoldLight,
                            WebColors.primaryGold
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'KURTAR BENİ DOKTOR',
                          style: TextStyle(
                            fontSize:
                                context.responsive(mobile: 20.0, desktop: 35.0),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.theater_comedy,
                        color: WebColors.primaryGold, size: context.iconMedium),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: WebColors.primaryGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: WebColors.primaryGold.withOpacity(0.3)),
                  ),
                  child: Text(
                    "Anton Çehov'dan",
                    style: TextStyle(
                      fontSize: context.captionSize,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: WebColors.primaryGoldLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  // ─── BİLGİ VE KADRO BÖLÜMÜ ───

  Widget _buildInfoSection(final BuildContext context) => Container(
        padding: context.paddingAll,
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(context.borderRadius(1.25)),
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                const Icon(Icons.article_outlined,
                    color: WebColors.primaryGold, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Oyunun Özeti',
                  style: TextStyle(
                    fontSize: context.subtitleSize,
                    fontWeight: FontWeight.bold,
                    color: WebColors.primaryGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Açıklama
            Text(
              'Anton Çehov\'un ünlü oyunundan uyarlanan bu etkileyici yapım, insan doğasının karmaşık duygularını ve toplumsal baskıları benzersiz bir sanatsal yaklaşımla sahneye taşıyor. Güçlü performanslar ve çarpıcı sahneleme ile unutulmaz bir deneyim.',
              style: TextStyle(
                fontSize: context.bodySize,
                height: 1.6,
                color: WebColors.lightWhite.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),
            // Çipler
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(icon: Icons.calendar_today, label: '12 Ara 2025'),
                _InfoChip(icon: Icons.location_on, label: 'Küçük Sahne'),
                _InfoChip(icon: Icons.schedule, label: '90 dakika'),
              ],
            ),
            const SizedBox(height: 18),
            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    WebColors.primaryGold.withOpacity(0.3),
                    Colors.transparent
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Kadro Başlığı
            Text(
              'OYUN EKİBİ',
              style: TextStyle(
                fontSize: context.bodySize + 2,
                fontWeight: FontWeight.bold,
                color: WebColors.primaryGold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 14),
            // Kadro Listesi (Map kullanımı)
            ..._castMembers.map((final member) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child:
                      _buildCastCard(context, member['name']!, member['role']!),
                )),
          ],
        ),
      );

  // Cast Card Helper (Widget yerine Metot extraction - daha performanslı ve temiz)
  Widget _buildCastCard(
          final BuildContext context, final String name, final String role) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: WebColors.primaryGold.withOpacity(0.2),
              child: Text(
                name.characters.first,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(role,
                      style: const TextStyle(
                          color: WebColors.primaryGoldLight, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─── YARDIMCI WIDGETLAR (Sabit Tasarım Öğeleri) ───

// Hover durumunu yönettiği için Stateful kalması mantıklı
class _HeroImageCard extends StatefulWidget {
  const _HeroImageCard();

  @override
  State<_HeroImageCard> createState() => _HeroImageCardState();
}

class _HeroImageCardState extends State<_HeroImageCard> {
  bool _isHovered = false;

  @override
  Widget build(final BuildContext context) {
    final double height = context.responsive(mobile: 350.0, desktop: 500.0);
    final double radius = context.borderRadius(1.25);

    return MouseRegion(
      onEnter: (final _) => setState(() => _isHovered = true),
      onExit: (final _) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color:
                    WebColors.primaryGold.withOpacity(_isHovered ? 0.25 : 0.1),
                blurRadius: _isHovered ? 32 : 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                OptimizedCachedImage(
                  imageUrl:
                      'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FkurtarBeniDoktor%2F21903122132.png?alt=media&token=21913d43-e257-45fb-8d2e-4d1065b0be8b',
                  fit: BoxFit.fitHeight,
                  width:
                      context.screenWidth > 1400 ? 1400 : context.screenWidth,
                ),
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5)
                      ],
                    ),
                  ),
                ),
                // Etiketler (Orijinal tasarımdaki gibi)
                const Positioned(
                  top: 14,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _PillTag(text: 'Drama'),
                      SizedBox(height: 8),
                      _PillTag(text: '90 dk'),
                    ],
                  ),
                ),
                // Alıntı Kartı (Orijinal tasarımdaki gibi)
                const Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: _QuoteCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final String text;

  const _PillTag({required this.text});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white)),
      );
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(final BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote,
                    color: WebColors.primaryGoldLight, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"İnsan mutlu olmak için değil, özgür olmak için yaratılmıştır."',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            height: 1.4),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '— Anton Çehov',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: WebColors.primaryGoldLight),
            const SizedBox(width: 7),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
