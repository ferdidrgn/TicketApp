import 'package:flutter/material.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bento/bento_primitives.dart';

const _kFaqItems = [
  (
    'Biletimi nasıl bulabilirim?',
    'Biletlerim sekmesinden geçmiş ve gelecek tüm biletlerine ulaşabilirsin.'
  ),
  (
    'Sanatçı profili nasıl açılır?',
    'Profil düzenleme ekranından yeteneklerini belirterek başlayabilirsin.'
  ),
  (
    'Ücretsiz bilet nasıl alırım?',
    'Ücretsiz olarak işaretlenmiş etkinliklerde koltuk seçimi sonrası "Ücretsiz '
        'Biletini Al" butonu çıkar — ödeme adımı olmadan biletin oluşur.'
  ),
  (
    'Ödeme yaparken sorun yaşıyorum, ne yapmalıyım?',
    'Kart bilgilerini kontrol et ve farklı bir ödeme yöntemi (iyzico/PayTR/'
        'Stripe) dene. Sorun devam ederse bir süre sonra tekrar dene.'
  ),
];

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  String _query = '';

  @override
  Widget build(final BuildContext context) {
    final bool isLargeScreen = context.isTablet || context.isDesktop;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _kFaqItems
        : _kFaqItems
            .where((final item) =>
                item.$1.toLowerCase().contains(q) ||
                item.$2.toLowerCase().contains(q))
            .toList();

    return BasePageWrapper(
      showBackButton: true,
      showFab: false,
      layoutConfig: const BasePageLayoutConfig(
        backgroundColor: BentoColors.canvas,
        safeAreaTop: true,
      ),
      title: 'DANIŞMA MASASI',
      subtitle: 'Serüveninde sana rehberlik edelim...',
      rightIcon: Icons.support_agent_rounded,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 800 : double.infinity,
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildSearchBox(context),
              const SizedBox(height: 32),
              const BentoSectionHeader(
                  title: 'Sıkça Sorulanlar',
                  icon: Icons.help_outline_rounded),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const BentoEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Sonuç bulunamadı',
                  message: 'Farklı bir kelimeyle tekrar dene.',
                )
              else
                for (final item in filtered)
                  _buildFaqItem(context, item.$1, item.$2),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Arama Kutusu — artık gerçekten SSS listesini filtreliyor.
  Widget _buildSearchBox(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: BentoColors.highlight,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: BentoColors.microBorder),
        ),
        child: TextField(
          onChanged: (final v) => setState(() => _query = v),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Sorunun cevabını burada ara...',
            hintStyle: TextStyle(color: Color(0xFF71717A)),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Color(0xFFA1A1AA)),
          ),
        ),
      );

  // Accordion (FAQ) Item
  Widget _buildFaqItem(final BuildContext context, final String question,
          final String answer) =>
      Theme(
        // FAQ çizgilerini temizlemek için
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          iconColor: BentoColors.indigoLight,
          collapsedIconColor: const Color(0xFFA1A1AA),
          title: Text(question,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          children: [
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(answer,
                    style: const TextStyle(
                        color: Color(0xFFA1A1AA), height: 1.5)))
          ],
        ),
      );
}
