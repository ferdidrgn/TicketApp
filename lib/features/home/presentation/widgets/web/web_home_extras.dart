import 'package:flutter/material.dart';

import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/sahne/sahne_kit.dart';

/// Web ana sayfasının içerik bölümleri (mağaza sitesi yoğunluğu): kampanya
/// karoları, sayılar şeridi, nasıl çalışır, tiyatro rehberi, SSS. Tüm metinler
/// gerçek bilgi; sayılar gerçek veriden gelir, uydurma yorum/istatistik yok.

class _SectionHead extends StatelessWidget {
  final String title;
  final String? sub;
  const _SectionHead(this.title, [this.sub]);

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Sk.display(context, size: 30, height: 1.1)),
        if (sub != null) ...[
          const SizedBox(height: 6),
          Text(sub!,
              style: Sk.ui(context,
                  size: 14.5,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w500)),
        ],
      ],
    );
  }
}

/// Vitrinin altındaki üç büyük hızlı bağlantı karosu.
class WebPromoTiles extends StatelessWidget {
  final bool wide;
  const WebPromoTiles({super.key, required this.wide});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<(IconData, String, String, VoidCallback, Color, Color)> tiles = [
      (
        Icons.nights_stay_rounded,
        'Bu akşam ne izlesem?',
        'Bugün perdesi açılan oyunlar',
        () => NavigationHandler.goToDiscover(context),
        cs.primaryContainer,
        cs.onPrimaryContainer,
      ),
      (
        Icons.near_me_rounded,
        'Yakınımdaki sahneler',
        'Konumuna göre oyunları haritada gör',
        () => NavigationHandler.goToNearby(context),
        cs.secondaryContainer,
        cs.onSecondaryContainer,
      ),
      (
        Icons.local_offer_rounded,
        'Kampanyalar',
        'İndirimli seanslar ve fırsatlar',
        () => NavigationHandler.goToCampaigns(context),
        cs.tertiaryContainer,
        cs.onTertiaryContainer,
      ),
    ];
    Widget tile((IconData, String, String, VoidCallback, Color, Color) t) =>
        _Tile(
            icon: t.$1,
            title: t.$2,
            sub: t.$3,
            onTap: t.$4,
            bg: t.$5,
            fg: t.$6);
    return wide
        ? Row(children: [
            for (int i = 0; i < tiles.length; i++) ...[
              Expanded(child: tile(tiles[i])),
              if (i < tiles.length - 1) const SizedBox(width: 20),
            ],
          ])
        : Column(children: [
            for (final t in tiles) ...[tile(t), const SizedBox(height: 14)],
          ]);
  }
}

class _Tile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;
  const _Tile(
      {required this.icon,
      required this.title,
      required this.sub,
      required this.onTap,
      required this.bg,
      required this.fg});

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _hover = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: widget.bg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: _hover ? 0.3 : 0.12),
                    blurRadius: _hover ? 22 : 10,
                    offset: Offset(0, _hover ? 10 : 4)),
              ],
            ),
            child: Row(children: [
              Icon(widget.icon, size: 44, color: widget.fg),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: Sk.ui(context,
                              size: 18, color: widget.fg, weight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(widget.sub,
                          style: Sk.ui(context,
                              size: 13.5,
                              color: widget.fg.withValues(alpha: 0.8),
                              weight: FontWeight.w600)),
                    ]),
              ),
              Icon(Icons.arrow_forward_rounded, color: widget.fg),
            ]),
          ),
        ),
      );
}

/// Gerçek sayılar şeridi.
class WebStatsBand extends StatelessWidget {
  final int shows;
  final int stages;
  final int teams;
  final int players;
  final bool wide;
  const WebStatsBand(
      {super.key,
      required this.shows,
      required this.stages,
      required this.teams,
      required this.players,
      required this.wide});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<(int, String, IconData)> items = [
      (shows, 'Oyun', Icons.theater_comedy_rounded),
      (stages, 'Sahne', Icons.location_city_rounded),
      (teams, 'Topluluk', Icons.groups_rounded),
      (players, 'Oyuncu', Icons.person_rounded),
    ];
    final List<Widget> cells = [
      for (final i in items)
        if (i.$1 > 0)
          Column(children: [
            Icon(i.$3, color: cs.primary, size: 26),
            const SizedBox(height: 8),
            Text('${i.$1}', style: Sk.display(context, size: 40, height: 1.0)),
            const SizedBox(height: 4),
            Text(i.$2,
                style: Sk.ui(context,
                    size: 14,
                    color: cs.onSurfaceVariant,
                    weight: FontWeight.w700)),
          ]),
    ];
    if (cells.length < 2) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(vertical: wide ? 34 : 24, horizontal: 20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 40,
        runSpacing: 24,
        children: cells,
      ),
    );
  }
}

/// "Nasıl çalışır?" — 4 adım.
class WebHowItWorks extends StatelessWidget {
  final bool wide;
  const WebHowItWorks({super.key, required this.wide});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    const List<(IconData, String, String)> steps = [
      (Icons.search_rounded, 'Oyunu bul',
          'Tür, tarih ya da sahneye göre ara; puanlara ve yorumlara göz at.'),
      (Icons.event_rounded, 'Seansı seç',
          'Gün ve saati seç, mekânı haritada gör, takvimine ekle.'),
      (Icons.event_seat_rounded, 'Koltuğunu seç',
          'Salon planından istediğin koltuğu işaretle ve ödemeye geç.'),
      (Icons.confirmation_number_rounded, 'Biletin cebinde',
          'Dijital biletin hesabında; seans günü koltuğunu göster.'),
    ];
    final List<Widget> cells = [
      for (int i = 0; i < steps.length; i++)
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: cs.primaryContainer, shape: BoxShape.circle),
              child: Icon(steps[i].$1, color: cs.onPrimaryContainer, size: 28),
            ),
            const SizedBox(width: 12),
            Text('${i + 1}',
                style: Sk.display(context,
                    size: 34, height: 1, color: cs.outlineVariant)),
          ]),
          const SizedBox(height: 14),
          Text(steps[i].$2,
              style: Sk.ui(context, size: 17, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(steps[i].$3,
              style: Sk.ui(context,
                  size: 14,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w500,
                  height: 1.5)),
        ]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHead('Nasıl çalışır?', 'Dört adımda biletin hazır'),
        const SizedBox(height: 28),
        wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (int i = 0; i < cells.length; i++) ...[
                  Expanded(child: cells[i]),
                  if (i < cells.length - 1) const SizedBox(width: 28),
                ],
              ])
            : Column(children: [
                for (final c in cells) ...[c, const SizedBox(height: 26)],
              ]),
      ],
    );
  }
}

class _Article {
  final IconData icon;
  final String title;
  final String lead;
  final List<(String, String)> body;
  const _Article(this.icon, this.title, this.lead, this.body);
}

const List<_Article> _articles = [
  _Article(
    Icons.lightbulb_outline_rounded,
    'İlk kez tiyatroya gidenler için 7 ipucu',
    'Perde açılmadan önce bilmen gerekenler.',
    [
      ('Erken gel',
          'Seanstan 20–30 dakika önce salonda ol. Koltuğunu bulmak, vestiyere uğramak ve sakinleşmek için zaman kalsın. Geç gelenler çoğu salonda perde arasına kadar içeri alınmayabilir.'),
      ('Koltuğunu önceden seç',
          'Aynı oyun için farklı koltukların manzarası çok değişir. Biletini alırken salon planına bak, görüş açını düşünerek seç.'),
      ('Telefonunu sessize al',
          'Ekran ışığı ve bildirim sesi hem oyunculara hem seyircilere zarar verir. Salona girmeden telefonunu kapat ya da uçak moduna al.'),
      ('Yaş sınırına bak',
          'Her oyunun bir yaş sınırı var. Çocukla gidecekseniz oyunun sayfasındaki yaş bilgisini ve süreyi kontrol et.'),
      ('Rahat giyin',
          'Tiyatro için sabit bir kıyafet kuralı yok. İki saate yakın oturacağın için rahat olmak yeterli; isteyenler şık giyinir.'),
      ('Fotoğraf ve video kuralı',
          'Birçok sahne oyun sırasında çekim yapmayı yasaklar. Selamlama ve foyer fotoğrafları için organizatörün kuralını sor.'),
      ('Süreyi ve arayı öğren',
          'Oyunun kaç dakika sürdüğü ve ara verilip verilmediği oyun sayfasında yazar; dönüş yolculuğunu buna göre planla.'),
    ],
  ),
  _Article(
    Icons.theater_comedy_outlined,
    'Tiyatro türleri nedir?',
    'Komediden müzikale, ne izleyeceğini seçmek için kısa rehber.',
    [
      ('Komedi',
          'Güldürürken düşündüren oyunlar. Günlük hayattan karakterler, hızlı diyaloglar ve sürprizli kurgular.'),
      ('Dram',
          'Ağır temalara ve güçlü karakterlere odaklanır. Oyunculuk performansının en çok öne çıktığı tür.'),
      ('Müzikal',
          'Şarkı, dans ve oyunculuğu birleştirir. İlk kez gideceklere genelde en eğlenceli seçenek.'),
      ('Çocuk oyunları',
          'Kısa süreli, renkli ve etkileşimli. Çocuklarla gidilecekse yaş aralığına bakmak önemli.'),
      ('Tek kişilik oyunlar',
          'Tek bir oyuncunun sahneyi taşıdığı, yakın ve samimi gösteriler.'),
    ],
  ),
  _Article(
    Icons.event_seat_outlined,
    'Koltuk seçerken nelere dikkat etmeli?',
    'Görüş açısı, ses ve rahatlık için pratik bilgiler.',
    [
      ('Orta bölüm, orta sıralar',
          'Çoğu salonda sahneyi en dengeli gören yer budur. Ses ve görüş açısı genelde en iyi buradadır.'),
      ('Ön sıralar',
          'Oyunculara çok yakınsındır, mimikleri net görürsün. Büyük dekorlarda sahnenin tamamını görmek için başını kaldırman gerekebilir.'),
      ('Yan koltuklar',
          'Sahnenin bir kenarı kısmen kapanabilir. Bilet fiyatı daha uygun olabilir; salon planında görüşe bak.'),
      ('Balkon ve arka sıralar',
          'Sahneyi bütünüyle ve yukarıdan görürsün; ayrıntıları seçmek zorlaşabilir. Müzikal ve kalabalık sahneler için iyi bir seçenektir.'),
      ('Koridor kenarı',
          'Perde arasında çıkmak ve girmek rahat olur; uzun bacaklılar için daha rahattır.'),
    ],
  ),
];

/// Tiyatro rehberi — okunabilir kısa yazılar (tıklayınca açılır).
class WebGuide extends StatelessWidget {
  final bool wide;
  const WebGuide({super.key, required this.wide});

  @override
  Widget build(final BuildContext context) {
    final List<Widget> cards = [
      for (final _Article a in _articles) _ArticleCard(article: a),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHead('Tiyatro rehberi', 'Tiyatroya gitmeden önce okunacak kısa yazılar'),
        const SizedBox(height: 26),
        wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (int i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i < cards.length - 1) const SizedBox(width: 22),
                ],
              ])
            : Column(children: [
                for (final c in cards) ...[c, const SizedBox(height: 16)],
              ]),
      ],
    );
  }
}

class _ArticleCard extends StatefulWidget {
  final _Article article;
  const _ArticleCard({required this.article});

  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  bool _hover = false;

  void _open(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final _Article a = widget.article;
    showDialog<void>(
      context: context,
      builder: (final ctx) => Dialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(a.title,
                        style: Sk.display(ctx, size: 28, height: 1.1)),
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(a.lead,
                    style: Sk.ui(ctx,
                        size: 15,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w600)),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectionArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < a.body.length; i++) ...[
                            Text('${i + 1}. ${a.body[i].$1}',
                                style: Sk.ui(ctx,
                                    size: 16, weight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(a.body[i].$2,
                                style: Sk.ui(ctx,
                                    size: 15,
                                    weight: FontWeight.w500,
                                    height: 1.65,
                                    color: cs.onSurface.withValues(alpha: 0.9))),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final _Article a = widget.article;
    // Kart/ikon kabı yok: başlık, giriş cümlesi ve bağlantı — düz metin sütunu.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.title,
                style: Sk.display(context,
                    size: 24,
                    height: 1.15,
                    color: _hover ? cs.primary : cs.onSurface)),
            const SizedBox(height: 10),
            Text(a.lead,
                style: Sk.ui(context,
                    size: 15,
                    color: cs.onSurfaceVariant,
                    weight: FontWeight.w500,
                    height: 1.55)),
            const SizedBox(height: 12),
            Text('${a.body.length} madde — oku',
                style: Sk.ui(context,
                    size: 14,
                    color: cs.primary,
                    weight: FontWeight.w800,
                    height: 1.2)),
          ],
        ),
      ),
    );
  }
}

/// Sıkça sorulan sorular (gerçek, genel bilgiler).
class WebFaq extends StatelessWidget {
  const WebFaq({super.key});

  static const List<(String, String)> _items = [
    ('Bilet nasıl alırım?',
        'Bir oyun seç, seans günü ve saatini işaretle, salon planından koltuğunu seç ve ödemeye geç. Biletin hesabındaki "Biletlerim" bölümünde görünür.'),
    ('Başka platformda satılan oyunlar nedir?',
        'Bazı oyunların biletleri organizatörün ya da iş ortağının sitesinde satılır. Böyle oyunlarda "Biletini bul" düğmesi seni o sayfaya yönlendirir; tarih, saat ve mekân bilgisi TiyatRol\'de yine görünür.'),
    ('Seansa kaç dakika önce gitmeliyim?',
        'Genel olarak seanstan 20–30 dakika önce salonda olmak iyi bir alışkanlıktır. Geç gelenlerin salona alınıp alınmayacağı sahneye göre değişir.'),
    ('Yaş sınırı nerede yazıyor?',
        'Her oyunun sayfasında süre, yaş sınırı ve tür bilgisi yer alır.'),
    ('İptal ve iade nasıl işler?',
        'İptal ve iade koşulları organizatöre ve oyunun türüne göre değişir. Ayrıntılar Kullanım Şartları sayfasında ve bilet işleminde belirtilir; sorun yaşarsan bize yazabilirsin.'),
    ('Yorum ve puan verebilir miyim?',
        'Evet. Bir oyunun biletini aldıysan ve seans tarihi geçtiyse, o oyuna yıldız ve yorum bırakabilirsin.'),
    ('Hesabımı nasıl silerim?',
        'Profil bölümünden hesabını silebilirsin. Ayrıntılar Gizlilik Politikası\'nda yazıyor.'),
  ];

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHead('Sıkça sorulan sorular'),
        const SizedBox(height: 22),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(children: [
            for (int i = 0; i < _items.length; i++) ...[
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  childrenPadding:
                      const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  expandedAlignment: Alignment.centerLeft,
                  title: Text(_items[i].$1,
                      style: Sk.ui(context, size: 16, weight: FontWeight.w800)),
                  children: [
                    Text(_items[i].$2,
                        style: Sk.ui(context,
                            size: 14.5,
                            color: cs.onSurface.withValues(alpha: 0.85),
                            weight: FontWeight.w500,
                            height: 1.65)),
                  ],
                ),
              ),
              if (i < _items.length - 1)
                Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.35)),
            ],
          ]),
        ),
      ],
    );
  }
}
