import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/navigation/widgets/web_account_shell.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// SSS kaydı: tür, soru, cevap. Her cevap uygulamanın GERÇEK davranışını
/// anlatır; olmayan bir özellik vaat edilmez.
class _Faq {
  final String group;
  final String q;
  final String a;
  const _Faq(this.group, this.q, this.a);
}

const List<_Faq> _kFaq = [
  _Faq(
      'Biletler',
      'Biletimi nasıl bulabilirim?',
      'Biletlerim sayfasında yaklaşan ve geçmiş tüm biletlerin listelenir. '
          'Her biletin üzerinde girişte göstereceğin QR kod bulunur; "Bileti '
          'aç" ile büyütebilirsin.'),
  _Faq(
      'Biletler',
      'Bileti nasıl alırım?',
      'Oyunun sayfasından bir seans seçersin, koltuk planında yerini '
          'belirlersin ve ödemeyi tamamlarsın. Biletin hemen Biletlerim '
          'sayfana eklenir.'),
  _Faq(
      'Biletler',
      'Biletimi takvime ekleyebilir miyim?',
      'Evet. Yaklaşan bir biletin üzerindeki "Takvime ekle" bağlantısı Google, '
          'Apple, Outlook, Yahoo ya da .ics dosyası olarak seansı takvimine '
          'ekler.'),
  _Faq(
      'Biletler',
      'Salona nasıl giderim?',
      'Biletindeki "Yol tarifi" bağlantısı sahnenin adresini harita '
          'uygulamasında açar.'),
  _Faq(
      'Biletler',
      'Bazı oyunlarda neden başka bir siteye yönlendiriliyorum?',
      'O oyunların biletleri resmi satış platformunda satılıyor. TiyatRol '
          'seni doğrudan o oyunun satış sayfasına götürür.'),
  _Faq(
      'Hesap',
      'Favorilerimi nerede görürüm?',
      'Giriş yaptıktan sonra Favorilerim sayfasında; oyunlar, sahneler ve '
          'sanatçılar ayrı sekmelerde toplanır. Kalbe tekrar dokunarak '
          'favoriden çıkarabilirsin.'),
  _Faq(
      'Hesap',
      'Bildirimlerimi nereden görürüm?',
      'Giriş yaptıysan sayfanın üstündeki zil simgesinden. Okunmamış '
          'bildirim sayısı simgenin üstünde görünür.'),
  _Faq(
      'Hesap',
      'Uygulamanın görünümünü nasıl değiştiririm?',
      'Profil sayfasından Ayarlar\'a gir; Tema bölümünden Gündüz, Gece, Oto '
          '(cihazına göre), Doğa, Ahenk ya da Özel seçebilirsin. Özel temada '
          'vurgu rengini de orada belirlersin.'),
  _Faq(
      'Destek',
      'İade ya da iptal için ne yapmalıyım?',
      'Bize e-posta ile yaz; yazına biletindeki "No." satırındaki numarayı '
          'eklersen sorununu çok daha hızlı çözeriz.'),
  _Faq(
      'Destek',
      'Hata gördüm ya da öneri iletmek istiyorum.',
      'Destek biletindeki e-posta bağlantısından bize yaz. Ne yaparken '
          'karşılaştığını kısaca anlatman yeterli.'),
];

/// YARDIM VE DESTEK — WEB. Hesap kabuğu içinde: üstte aramalı başlık,
/// hızlı bağlantı kutuları, tür çipleriyle süzülen SSS, sağda yapışkan
/// "destek bileti" (gerçek e-posta ve sosyal hesaplar). Mobil
/// `HelpSupportPage`'den AYRIDIR.
class HelpSupportPageWeb extends ConsumerStatefulWidget {
  const HelpSupportPageWeb({super.key});

  @override
  ConsumerState<HelpSupportPageWeb> createState() => _HelpSupportPageWebState();
}

class _HelpSupportPageWebState extends ConsumerState<HelpSupportPageWeb> {
  final TextEditingController _search = TextEditingController();
  String? _group;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String _fold(final String s) => s
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String q = _fold(_search.text.trim());
    final List<String> groups = [
      for (final _Faq f in _kFaq)
        if (!_kFaq.takeWhile((final x) => x != f).any((final x) => x.group == f.group))
          f.group,
    ];
    final List<_Faq> items = _kFaq.where((final f) {
      if (_group != null && f.group != _group) return false;
      if (q.isEmpty) return true;
      return _fold(f.q).contains(q) || _fold(f.a).contains(q);
    }).toList();

    final bool loggedIn = ref.watch(isLoggedInProvider);
    final String uid = ref.watch(currentUserIdProvider) ?? '';

    return WebAccountShell(
      current: WebAccountSection.help,
      title: 'Yardım ve destek',
      subtitle: 'Sorunu yaz, sıkça sorulanlarda cevabı bul; bulamazsan bize yaz.',
      headerTrailing: SizedBox(
        width: 360,
        child: TextField(
          controller: _search,
          onChanged: (final _) => setState(() {}),
          textInputAction: TextInputAction.search,
          style: Sk.ui(context, size: 14.5, weight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Sorunu yaz: bilet, favori, tema…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Aramayı temizle',
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => setState(_search.clear),
                  ),
            filled: true,
            fillColor: cs.surfaceContainerHigh,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      aside: const _SupportTicket(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (q.isEmpty && _group == null) ...[
            _QuickLinks(
              onTickets: () => loggedIn && uid.isNotEmpty
                  ? NavigationHandler.goToMyTickets(context, uid)
                  : NavigationHandler.goToLogin(context),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
          Semantics(
            header: true,
            child: Text('Sıkça sorulanlar',
                style: Sk.display(context, size: 26)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SkChip(
                label: 'Tümü',
                count: _kFaq.length,
                selected: _group == null,
                onTap: () => setState(() => _group = null),
              ),
              for (final String g in groups)
                SkChip(
                  label: g,
                  count: _kFaq.where((final f) => f.group == g).length,
                  selected: _group == g,
                  onTap: () => setState(() => _group = g),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (items.isEmpty)
            WebStatePanel(
              icon: Icons.search_off_rounded,
              title: 'Bu aramaya uyan soru yok',
              message: 'Başka bir kelime dene ya da doğrudan bize yaz; '
                  'cevaplayalım.',
              actionLabel: 'E-posta gönder',
              onAction: () => TiyatrolCommunicationActions.sendEmail(),
              secondaryLabel: 'Aramayı temizle',
              onSecondary: () => setState(() {
                _search.clear();
                _group = null;
              }),
            )
          else
            WebPanel(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++)
                    _FaqRow(
                      key: ValueKey('faq-${items[i].q}'),
                      faq: items[i],
                      last: i == items.length - 1,
                      showGroup: _group == null,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  final VoidCallback onTickets;
  const _QuickLinks({required this.onTickets});

  @override
  Widget build(final BuildContext context) {
    final List<(IconData, String, String, VoidCallback)> tiles = [
      (
        Icons.confirmation_number_outlined,
        'Biletlerim',
        'QR kodların ve seansların',
        onTickets
      ),
      (
        Icons.favorite_border_rounded,
        'Favorilerim',
        'Kenara ayırdıkların',
        () => NavigationHandler.goToFavorites(context)
      ),
      (
        Icons.local_offer_outlined,
        'Kampanyalar',
        'Geçerli fırsatlar',
        () => NavigationHandler.goToCampaigns(context)
      ),
      (
        Icons.description_outlined,
        'Yasal bilgiler',
        'Gizlilik ve şartlar',
        () => NavigationHandler.goToContracts(context)
      ),
    ];
    return LayoutBuilder(builder: (final context, final box) {
      final int cols = box.maxWidth >= 640 ? 4 : 2;
      final double w =
          (box.maxWidth - (cols - 1) * AppSpacing.md) / cols;
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (final t in tiles)
            SizedBox(width: w, child: _Tile(icon: t.$1, title: t.$2, sub: t.$3, onTap: t.$4)),
        ],
      );
    });
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _Tile(
      {required this.icon,
      required this.title,
      required this.sub,
      required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return PressScale(
      onTap: onTap,
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary, size: 24),
            const SizedBox(height: AppSpacing.md),
            Text(title,
                style: Sk.ui(context, size: 14.5, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Sk.ui(context,
                    size: 12.5,
                    color: cs.onSurfaceVariant,
                    weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _FaqRow extends StatelessWidget {
  final _Faq faq;
  final bool last;
  final bool showGroup;
  const _FaqRow(
      {super.key,
      required this.faq,
      required this.last,
      required this.showGroup});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ShapeBorder line = Border(
        bottom: last
            ? BorderSide.none
            : BorderSide(color: cs.outlineVariant));
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, 0, AppSpacing.xxl, AppSpacing.lg),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      shape: line,
      collapsedShape: line,
      iconColor: cs.primary,
      collapsedIconColor: cs.onSurfaceVariant,
      textColor: cs.onSurface,
      collapsedTextColor: cs.onSurface,
      title: Text(faq.q,
          style: Sk.ui(context, size: 15.5, weight: FontWeight.w700)),
      subtitle: showGroup
          ? Text(faq.group,
              style: Sk.ui(context,
                  size: 12,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w600))
          : null,
      children: [
        Text(faq.a,
            style: Sk.ui(context,
                size: 15,
                color: cs.onSurfaceVariant,
                weight: FontWeight.w500,
                height: 1.6)),
      ],
    );
  }
}

/// Destek bileti: gövdede tek birincil eylem (E-posta); koçanda sosyal
/// hesaplar. Hepsi gerçek `TiyatrolCommunicationActions`.
class _SupportTicket extends StatelessWidget {
  const _SupportTicket();

  @override
  Widget build(final BuildContext context) => AdmitTicket(
        direction: Axis.vertical,
        shadows: AppShadows.level2(TicketInk.ink),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TicketHeaderStrip(kind: 'DESTEK'),
              const SizedBox(height: AppSpacing.xl),
              Text('Cevabını bulamadın mı?', style: TicketInk.headline(22)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Bize yaz, sorunu birlikte çözelim.',
                style: TextStyle(
                  color: TicketInk.inkSoft(0.72),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TicketStampButton(
                label: 'E-posta gönder',
                leading: const Icon(Icons.mail_outline_rounded),
                onTap: () => TiyatrolCommunicationActions.sendEmail(),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('iletisim@tiyatrol.com',
                  textAlign: TextAlign.center,
                  style: TicketInk.value(size: 13)),
            ],
          ),
        ),
        stub: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BİZİ TAKİP ET', style: TicketInk.label()),
              const Wrap(
                children: [
                  TicketTextLink(
                    label: 'Instagram',
                    onTap: TiyatrolCommunicationActions.openInstagram,
                  ),
                  TicketTextLink(
                    label: 'Facebook',
                    onTap: TiyatrolCommunicationActions.openFacebook,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
