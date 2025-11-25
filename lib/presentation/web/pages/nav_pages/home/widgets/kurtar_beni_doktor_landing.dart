import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';

/// Nirvana — modern / sanatsal bir landing tasarımı
/// - Mobil ve Desktop uyumlu
/// - Sabit 600px yükseklik *kullanılmaz*; yerine orantılı, esnek düzen kullanılır
/// - Şık ikonlar, glassmorphism kartlar, hover/press efektleri
/// - Renkleri `WebColors` içinde tanımlı değerlere bırakır (burada kullanılmıyor)

class KurtarBeniDoktorLanding extends StatelessWidget {
  const KurtarBeniDoktorLanding({super.key});

  static const _breakpoint = 768.0;

  @override
  Widget build(final BuildContext context) {
    return Container(
      color: WebColors.darkBlueBackground,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: LayoutBuilder(builder: (final context, final constraints) {
        final isMobile = constraints.maxWidth < _breakpoint;

        return Column(
          children: [
            _Header(isMobile: isMobile),
            const SizedBox(height: 24),
            // Orantılı yüksekliğe sahip ana bölüm: görsel + bilgiler
            ConstrainedBox(
              constraints: BoxConstraints(
                // Ekran yüksekliğinin %45'i veya min 320
                maxHeight: (MediaQuery.of(context).size.height * 0.55)
                    .clamp(320.0, 1200.0),
              ),
              child: isMobile
                  ? _buildMobileBody(context)
                  : _buildDesktopBody(context),
            ),
            const SizedBox(height: 28),
            _FooterActions(),
          ],
        );
      }),
    );
  }

  Widget _buildMobileBody(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 6, child: _HeroImage()),
        const SizedBox(height: 16),
        Expanded(flex: 5, child: _InfoAndCast()),
      ],
    );
  }

  Widget _buildDesktopBody(final BuildContext context) {
    return Row(
      children: [
        // Görsel sol tarafta geniş yer kaplar
        Expanded(flex: 6, child: _HeroImage()),
        const SizedBox(width: 24),
        // Sağ taraf bilgi kartları
        Expanded(flex: 4, child: _InfoAndCast()),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final bool isMobile;

  const _Header({super.key, required this.isMobile});

  @override
  Widget build(final BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: isMobile ? 22 : 34,
      fontWeight: FontWeight.w900,
      letterSpacing: 3,
      color: WebColors.darkBlueBackground,
    );

    final subtitleStyle = TextStyle(
      fontSize: isMobile ? 12 : 16,
      fontStyle: FontStyle.italic,
      color: WebColors.darkBlueBackground.withOpacity(0.85),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        color: WebColors.primaryGold,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Text('KURTAR BENİ DOKTOR',
              style: titleStyle, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text("Anton Çehov'dan",
              style: subtitleStyle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({super.key});

  @override
  Widget build(final BuildContext context) {
    // Görselin responsive davranışı için BoxConstraints kullanıyoruz
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan görseli
          const _ResponsiveNetworkImage(
            imageUrl:
                'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2FkurtarBeniDoktor%2F21903122132.png?alt=media&token=21913d43-e257-45fb-8d2e-4d1065b0be8b',
            fit: BoxFit.cover,
          ),

          // Hafif renkli overlay ile sanatsal efekt
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  WebColors.darkBlueSurface.withOpacity(0.15),
                  WebColors.primaryGold.withOpacity(0.06),
                ],
              ),
            ),
          ),

          // Sol alt köşede küçük glass-card ile öne çıkan not
          Positioned(
            left: 18,
            bottom: 18,
            child: _GlassNote(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.theater_comedy, size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Yeni Sezon'),
                      Text('Biletler yayında'),
                    ],
                  )
                ],
              ),
            ),
          ),

          // Sağ üstte küçük etiketler
          Positioned(
            right: 18,
            top: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                _PillTag(text: 'Drama'),
                SizedBox(height: 8),
                _PillTag(text: '90 dk'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const _ResponsiveNetworkImage(
      {super.key, required this.imageUrl, this.fit = BoxFit.cover});

  @override
  Widget build(final BuildContext context) {
    // FadeInImage ile yükleme esnasında placeholder
    return FadeInImage.assetNetwork(
      placeholder: 'assets/images/placeholder_blur.png',
      image: imageUrl,
      fit: fit,
      imageErrorBuilder: (final context, final error, final stack) {
        return Container(
          color: WebColors.darkBlueSurface,
          child: const Center(child: Icon(Icons.broken_image, size: 48)),
        );
      },
    );
  }
}

class _GlassNote extends StatelessWidget {
  final Widget child;

  const _GlassNote({super.key, required this.child});

  @override
  Widget build(final BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: DefaultTextStyle(
            style: TextStyle(color: WebColors.primaryGoldLight, fontSize: 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final String text;

  const _PillTag({super.key, required this.text});

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.32),
        borderRadius: BorderRadius.circular(20),
      ),
      child:
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
    );
  }
}

class _InfoAndCast extends StatelessWidget {
  const _InfoAndCast({super.key});

  @override
  Widget build(final BuildContext context) {
    // İçerik: başlık, açıklama, ikonlu bilgileri ve cast listesi
    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Oyunun Özeti',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: WebColors.primaryGold)),
          const SizedBox(height: 8),
          Text(
            'Kısa, çarpıcı ve sanatsal bir özet metni buraya gelecek. Okuyucuyu meraklandıracak, atmosferi taşıyacak bir cümle ile başlanır.',
            style: TextStyle(color: WebColors.primaryGoldLight, height: 1.45),
          ),
          const SizedBox(height: 12),

          // ikonlu bilgi satırı
          Row(
            children: const [
              _InfoChip(icon: Icons.calendar_today, label: '12 Ara 2025'),
              SizedBox(width: 8),
              _InfoChip(icon: Icons.location_on, label: 'Küçük Sahne'),
              SizedBox(width: 8),
              _InfoChip(icon: Icons.timer, label: '90 dk'),
            ],
          ),

          const SizedBox(height: 18),

          // Glassmorphism cast list — kaydırılabilir
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('OYUN EKİBİ',
                      style: TextStyle(
                          color: WebColors.primaryGold,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _CastCard(name: 'UĞUR KILIÇ', role: 'Yönetmen'),
                  const SizedBox(height: 8),
                  _CastCard(name: 'EBRU AKKÜN', role: 'Yönetmen'),
                  const SizedBox(height: 8),
                  _CastCard(name: 'DIALRA SEKMEN', role: 'Makyaj'),
                  const SizedBox(height: 8),
                  _CastCard(name: 'DERYA DİNÇER', role: 'Kostüm'),
                  const SizedBox(height: 8),
                  _CastCard(name: 'SEYİT ÇOLAK', role: 'Işık'),
                  const SizedBox(height: 8),
                  _CastCard(name: 'DUYGU ŞAHİN', role: 'Asistan'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(final BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white.withOpacity(0.95)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _CastCard extends StatefulWidget {
  final String name;
  final String role;

  const _CastCard({super.key, required this.name, this.role = ''});

  @override
  State<_CastCard> createState() => _CastCardState();
}

class _CastCardState extends State<_CastCard> {
  bool _hover = false;

  @override
  Widget build(final BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(_hover ? 0.28 : 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          // Küçük ikon yerine avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: WebColors.primaryGold.withOpacity(0.18),
            child: Text(widget.name.characters.first,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                if (widget.role.isNotEmpty)
                  Text(widget.role,
                      style: TextStyle(
                          color: WebColors.primaryGoldLight, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chevron_right),
            color: Colors.white.withOpacity(0.85),
            tooltip: 'Detay',
          )
        ],
      ),
    );

    // Desktop hover desteği
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return MouseRegion(
        onEnter: (final _) => setState(() => _hover = true),
        onExit: (final _) => setState(() => _hover = false),
        child: AnimatedScale(
            scale: _hover ? 1.01 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: content),
      );
    }

    return GestureDetector(
        onTapDown: (final _) => setState(() => _hover = true),
        onTapUp: (final _) => setState(() => _hover = false),
        onTapCancel: () => setState(() => _hover = false),
        child: content);
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({super.key});

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.event_available),
          label: const Text('Bilet Al'),
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 6),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.info_outline),
          label: const Text('Detaylı Bilgi'),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
        ),
      ],
    );
  }
}
