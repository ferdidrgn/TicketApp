import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/util/responsive_utils.dart'; // Core Utils Dosyanız

/// Modern Kurtar Beni Doktor Landing Page
/// - Responsive Utils entegrasyonu tamamlandı
/// - Manuel media query'ler kaldırıldı, merkezi yapıya geçildi

class KurtarBeniDoktorLanding extends StatelessWidget {
  const KurtarBeniDoktorLanding({super.key});

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: double.infinity,
      color: WebColors.darkBlueBackground,
      // Paddingler ResponsiveUtils'den geliyor
      padding: EdgeInsets.symmetric(
        horizontal:
            context.responsive(mobile: 16.0, tablet: 32.0, desktop: 48.0),
        vertical: context.responsive(mobile: 24.0, desktop: 32.0),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              // Header (Parametreye gerek kalmadı, context'ten okuyor)
              const _CompactHeader(),

              SizedBox(height: context.responsive(mobile: 20.0, desktop: 28.0)),

              // Layout Yönetimi: ResponsiveUtils.adaptive kullanımı
              ResponsiveUtils.adaptive(
                context,
                mobile: const _MobileLayout(),
                tablet: const _TabletLayout(),
                desktop: const _DesktopLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader();

  @override
  Widget build(final BuildContext context) {
    // Responsive değerler
    final double radius = context.borderRadius(context.isMobile ? 1.0 : 1.25);
    final double padding = context.responsive(mobile: 18.0, desktop: 24.0);
    final double iconSize = context.iconMedium;
    final double titleSize = context.responsive(mobile: 20.0, desktop: 35.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: WebColors.primaryGold.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: WebColors.primaryGold.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.theater_comedy,
                    color: WebColors.primaryGold,
                    size: iconSize,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: ShaderMask(
                      shaderCallback: (final bounds) => const LinearGradient(
                        colors: [
                          WebColors.primaryGoldLight,
                          WebColors.primaryGold,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'KURTAR BENİ DOKTOR',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.theater_comedy,
                    color: WebColors.primaryGold,
                    size: iconSize,
                  ),
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
                    color: WebColors.primaryGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  "Anton Çehov'dan",
                  style: TextStyle(
                    fontSize: context.responsive(mobile: 12.0, desktop: 15.0),
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
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(final BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Image - 70%
        Expanded(
          flex: 70,
          child: _HeroImageCard(),
        ),
        SizedBox(width: 28),
        // Info Section - 30%
        Expanded(
          flex: 30,
          child: _InfoSection(),
        ),
      ],
    );
  }
}

class _TabletLayout extends StatelessWidget {
  const _TabletLayout();

  @override
  Widget build(final BuildContext context) {
    return const Column(
      children: [
        _HeroImageCard(),
        SizedBox(height: 20),
        _InfoSection(),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(final BuildContext context) {
    return const Column(
      children: [
        _HeroImageCard(),
        SizedBox(height: 20),
        _InfoSection(),
      ],
    );
  }
}

class _HeroImageCard extends StatefulWidget {
  const _HeroImageCard();

  @override
  State<_HeroImageCard> createState() => _HeroImageCardState();
}

class _HeroImageCardState extends State<_HeroImageCard> {
  bool _isHovered = false;

  @override
  Widget build(final BuildContext context) {
    // Yükseklik ayarını responsive utils ile yapıyoruz
    final double height = context.responsive(mobile: 350.0, desktop: 500.0);
    final double radius = context.borderRadius(1.25); // ~20px

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
                // Background Image
                Image.network(
                  'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FkurtarBeniDoktor%2F21903122132.png?alt=media&token=21913d43-e257-45fb-8d2e-4d1065b0be8b',
                  fit: BoxFit.fitHeight,
                  errorBuilder: (final _, final __, final ___) => Container(
                    color: WebColors.darkBlueSurface,
                    child: const Icon(Icons.broken_image, size: 64),
                  ),
                ),

                // Subtle Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),

                // Top Tags
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

                // Bottom Quote Card
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
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(final BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote,
                color: WebColors.primaryGoldLight,
                size: 24,
              ),
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
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '— Anton Çehov',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class _InfoSection extends StatelessWidget {
  const _InfoSection();

  @override
  Widget build(final BuildContext context) {
    // Responsive padding ve fontlar
    final double padding = context.responsive(mobile: 18.0, desktop: 24.0);
    final double titleSize = context.responsive(mobile: 18.0, desktop: 20.0);
    final double bodySize = context.bodySize;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(context.borderRadius(1.25)),
        border: Border.all(
          color: WebColors.primaryGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              const Icon(
                Icons.article_outlined,
                color: WebColors.primaryGold,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Oyunun Özeti',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: WebColors.primaryGold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Description
          Text(
            'Anton Çehov\'un ünlü oyunundan uyarlanan bu etkileyici yapım, insan doğasının karmaşık duygularını ve toplumsal baskıları benzersiz bir sanatsal yaklaşımla sahneye taşıyor. Güçlü performanslar ve çarpıcı sahneleme ile unutulmaz bir deneyim.',
            style: TextStyle(
              fontSize: bodySize, // Utils'den geliyor (14 or 16)
              height: 1.6,
              color: WebColors.lightWhite.withOpacity(0.9),
            ),
          ),

          const SizedBox(height: 16),

          // Info Chips
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
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Cast Section
          Row(
            children: [
              const Icon(
                Icons.people,
                color: WebColors.primaryGold,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'OYUN EKİBİ',
                style: TextStyle(
                  fontSize: context.responsive(mobile: 15.0, desktop: 16.0),
                  fontWeight: FontWeight.bold,
                  color: WebColors.primaryGold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Cast Members
          const _CastGrid(),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: WebColors.primaryGold.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: WebColors.primaryGoldLight),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CastGrid extends StatelessWidget {
  const _CastGrid();

  @override
  Widget build(final BuildContext context) {
    // Data listesi
    final castMembers = [
      {'name': 'İSKEDNER ATİLLA ATASOY', 'role': 'Uyarlayan ve Yöneten'},
      {'name': 'UĞUR KILIÇ', 'role': 'Yönetmen Yard.'},
      {'name': 'EBRU AKKÜN', 'role': 'Yönetmen Yard.'},
      {'name': 'DİLARA SEKMEN', 'role': 'Makyaj'},
      {'name': 'DERYA DİNÇER', 'role': 'Kostüm'},
      {'name': 'SEYİT ÇOLAK', 'role': 'Işık'},
      {'name': 'DUYGU ŞAHİN', 'role': 'Asistan'},
    ];

    return Column(
      children: castMembers.map((final member) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _CastCard(
            name: member['name'] as String,
            role: member['role'] as String,
          ),
        );
      }).toList(),
    );
  }
}

class _CastCard extends StatelessWidget {
  final String name;
  final String role;

  const _CastCard({
    required this.name,
    required this.role,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
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
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(
                    color: WebColors.primaryGoldLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
