part of 'home_page_web.dart';

// Yabancı tiyatro sitelerinden (ATG Tickets, TodayTix, London Theatre,
// Broadway.com) ödünç alınan bölüm kalıpları — hepsi gerçek veriden:
// tarih seçici şerit, sıralı Top 10, haftanın oyunu vitrini, son çağrı,
// bütçeye göre raf, kaydırırken beliren animasyon, sayaçlı sayılar.

// ═════════════════════════════════════════════════════════════════════════════
// KAYDIRINCA BELİREN BÖLÜM
// ═════════════════════════════════════════════════════════════════════════════

class _Reveal extends StatefulWidget {
  final Widget child;
  const _Reveal({required this.child});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  final Key _key = UniqueKey();
  bool _shown = false;

  @override
  Widget build(final BuildContext context) {
    final bool reduce = Sk.reduceMotion(context);
    if (reduce) return widget.child;
    return VisibilityDetector(
      key: _key,
      onVisibilityChanged: (final info) {
        if (!_shown && info.visibleFraction > 0.08 && mounted) {
          setState(() => _shown = true);
        }
      },
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: _shown ? Offset.zero : const Offset(0, 0.06),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TARİH SEÇİCİ ŞERİT ("Tarih seç")
// ═════════════════════════════════════════════════════════════════════════════

class _DateStrip extends StatefulWidget {
  final List<HomeSession> sessions;
  final void Function(Show) onOpen;
  const _DateStrip({required this.sessions, required this.onOpen});

  @override
  State<_DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<_DateStrip> {
  int _sel = 0;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DateTime today = DateTime.now();
    final DateTime start = DateTime(today.year, today.month, today.day);
    final List<DateTime> days = [
      for (int i = 0; i < 14; i++) start.add(Duration(days: i)),
    ];
    int countOn(final DateTime d) => widget.sessions
        .where((final s) => s.day == d)
        .length;
    final DateTime selected = days[_sel];
    final List<HomeSession> list = [
      for (final HomeSession s in widget.sessions)
        if (s.day == selected) s,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title(title: 'Tarih seç', subtitle: 'Önümüzdeki 14 gün'),
        const SizedBox(height: 20),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (final context, final i) {
              final DateTime d = days[i];
              final int n = countOn(d);
              final bool sel = i == _sel;
              return _Hoverable(
                label: '${d.day} ${kMonthsTr[d.month - 1]}, $n seans',
                onTap: () => setState(() => _sel = i),
                builder: (final hover) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 78,
                  decoration: BoxDecoration(
                    color: sel
                        ? cs.primary
                        : (hover
                            ? cs.surfaceContainerHighest
                            : cs.surfaceContainerHigh),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: n > 0 && !sel
                            ? cs.primary.withValues(alpha: 0.6)
                            : Colors.transparent,
                        width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(i == 0 ? 'Bugün' : kDaysShortTr[d.weekday - 1],
                          style: Sk.ui(context,
                              size: 12,
                              color: (sel ? cs.onPrimary : cs.onSurface)
                                  .withValues(alpha: 0.8),
                              weight: FontWeight.w700)),
                      Text('${d.day}',
                          style: Sk.display(context,
                              size: 28,
                              height: 1.1,
                              color: sel ? cs.onPrimary : cs.onSurface)),
                      Text(
                          n == 0 ? '—' : '$n seans',
                          style: Sk.ui(context,
                              size: 11.5,
                              color: (sel ? cs.onPrimary : cs.primary)
                                  .withValues(alpha: n == 0 ? 0.4 : 1),
                              weight: FontWeight.w800)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (final child, final anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.04), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: list.isEmpty
              ? Container(
                  key: ValueKey<int>(_sel),
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                      'Bu tarihte seans yok. Başka bir gün seç.',
                      style: Sk.ui(context,
                          size: 14.5,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w600)),
                )
              : Wrap(
                  key: ValueKey<int>(_sel),
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    for (final HomeSession s in list.take(8))
                      _DaySessionCard(
                          session: s, onOpen: () => widget.onOpen(s.show)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DaySessionCard extends StatelessWidget {
  final HomeSession session;
  final VoidCallback onOpen;
  const _DaySessionCard({required this.session, required this.onOpen});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String venue = (session.stage?.name ?? '').trim();
    return _Hoverable(
      label: '${session.show.name}, ${skClock(session.date)}',
      onTap: onOpen,
      builder: (final hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 380,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hover ? cs.primary.withValues(alpha: 0.08) : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: hover ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 62,
              height: 90,
              child: SkImage(
                  url: session.show.imageUrl, alignment: Alignment.topCenter),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(skClock(session.date),
                      style: Sk.display(context,
                          size: 26, height: 1, color: cs.primary)),
                  const SizedBox(height: 4),
                  Text(session.show.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 15, weight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 3),
                  Text(
                      [
                        if (venue.isNotEmpty) venue,
                        if (session.priceLabel != null) session.priceLabel!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 12.5,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w600)),
                ]),
          ),
          Icon(Icons.arrow_forward_rounded, color: cs.primary),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TOP 10 (dev rakamlı sıralı raf)
// ═════════════════════════════════════════════════════════════════════════════

class _TopTen extends StatelessWidget {
  final List<Show> shows;
  final Map<String, HomeSession> nextByShow;
  final void Function(Show) onOpen;
  const _TopTen(
      {required this.shows, required this.nextByShow, required this.onOpen});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Show> list = shows.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title(
            title: 'Bu hafta en çok bakılanlar',
            subtitle: 'Puan, yorum ve yaklaşan seanslara göre sıralı'),
        const SizedBox(height: 22),
        _ScrollRow(
          height: 330,
          itemWidth: 300,
          gap: 8,
          children: [
            for (int i = 0; i < list.length; i++)
              _Hoverable(
                label: '${i + 1}. ${list[i].name}',
                onTap: () => onOpen(list[i]),
                builder: (final hover) => SizedBox(
                  width: 300,
                  height: 320,
                  child: Stack(children: [
                    Positioned(
                      left: 0,
                      bottom: -22,
                      child: Text('${i + 1}',
                          style: Sk.display(context,
                                  size: 210,
                                  height: 1,
                                  color: Colors.transparent)
                              .copyWith(
                            shadows: const [],
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 3
                              ..color = hover
                                  ? cs.primary
                                  : cs.onSurface.withValues(alpha: 0.45),
                          )),
                    ),
                    Positioned(
                      left: i >= 9 ? 150 : 108,
                      top: 0,
                      bottom: 0,
                      width: 190,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform:
                            Matrix4.translationValues(0, hover ? -6 : 0, 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: hover ? 0.45 : 0.25),
                                blurRadius: hover ? 24 : 12,
                                offset: Offset(0, hover ? 12 : 6)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(fit: StackFit.expand, children: [
                            SkImage(
                                url: list[i].imageUrl,
                                alignment: Alignment.topCenter),
                            Positioned(
                                right: 8,
                                top: 8,
                                child: RatingChip(showId: list[i].id)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HAFTANIN OYUNU (büyük vitrin)
// ═════════════════════════════════════════════════════════════════════════════

class _WeekSpotlight extends StatelessWidget {
  final Show show;
  final List<HomeSession> sessions;
  final bool wide;
  final VoidCallback onOpen;
  const _WeekSpotlight(
      {required this.show,
      required this.sessions,
      required this.wide,
      required this.onOpen});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String desc = show.description.replaceAll('\\n', ' ').trim();
    final Widget poster = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: SkImage(url: show.imageUrl, alignment: Alignment.topCenter),
      ),
    );
    final Widget info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SkBadge(label: 'Haftanın oyunu', accent: true),
        const SizedBox(height: 16),
        Text(show.name, style: Sk.display(context, size: 44, height: 1.06)),
        const SizedBox(height: 14),
        Wrap(spacing: 18, runSpacing: 8, children: [
          if (show.category.trim().isNotEmpty)
            _Fact(Icons.category_outlined, show.category.trim()),
          if (show.duration.trim().isNotEmpty)
            _Fact(Icons.schedule_rounded, show.duration.trim()),
          if (show.ageLimit.trim().isNotEmpty)
            _Fact(Icons.shield_outlined, show.ageLimit.trim()),
        ]),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(desc.length > 260 ? '${desc.substring(0, 260)}…' : desc,
              style: Sk.ui(context,
                  size: 15,
                  color: cs.onSurface.withValues(alpha: 0.85),
                  weight: FontWeight.w500,
                  height: 1.65)),
        ],
        if (sessions.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Yaklaşan seanslar',
              style: Sk.ui(context, size: 14, weight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final HomeSession s in sessions.take(4))
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text('${skDayPhrase(s.date)} · ${skClock(s.date)}',
                    style: Sk.ui(context, size: 13, weight: FontWeight.w800)),
              ),
          ]),
        ],
        const SizedBox(height: 26),
        FilledButton(
          onPressed: onOpen,
          style: FilledButton.styleFrom(
              minimumSize: const Size(0, 54),
              padding: const EdgeInsets.symmetric(horizontal: 34),
              shape: const StadiumBorder()),
          child: Text(show.hasExternalTicketing ? 'Biletini bul' : 'Bilet al',
              style: Sk.ui(context,
                  size: 16, color: cs.onPrimary, weight: FontWeight.w800)),
        ),
      ],
    );
    return Container(
      padding: EdgeInsets.all(wide ? 40 : 22),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(width: 280, child: poster),
              const SizedBox(width: 48),
              Expanded(child: info),
            ])
          : Column(children: [
              SizedBox(width: 240, child: poster),
              const SizedBox(height: 24),
              info,
            ]),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Fact(this.icon, this.text);

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 18, color: cs.primary),
      const SizedBox(width: 6),
      Text(text, style: Sk.ui(context, size: 14, weight: FontWeight.w700)),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SON ÇAĞRI + BÜTÇEYE GÖRE
// ═════════════════════════════════════════════════════════════════════════════

class _BudgetRail extends StatefulWidget {
  final List<HomeSession> sessions;
  final double width;
  final void Function(Show) onOpen;
  const _BudgetRail(
      {required this.sessions, required this.width, required this.onOpen});

  @override
  State<_BudgetRail> createState() => _BudgetRailState();
}

class _BudgetRailState extends State<_BudgetRail> {
  double? _max = 250;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Map<String, HomeSession> cheapestByShow = {};
    for (final HomeSession s in widget.sessions) {
      if (s.priceLabel == null) continue;
      final HomeSession? cur = cheapestByShow[s.show.id];
      if (cur == null || _priceOf(s) < _priceOf(cur)) {
        cheapestByShow[s.show.id] = s;
      }
    }
    final List<HomeSession> list = [
      for (final HomeSession s in cheapestByShow.values)
        if (_max == null || _priceOf(s) <= _max!) s,
    ]..sort((a, b) => _priceOf(a).compareTo(_priceOf(b)));
    if (cheapestByShow.isEmpty) return const SizedBox.shrink();

    Widget tab(final String label, final double? v) {
      final bool sel = _max == v;
      return _Hoverable(
        label: label,
        onTap: () => setState(() => _max = v),
        builder: (final hover) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: sel
                ? cs.primary
                : (hover ? cs.surfaceContainerHighest : cs.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(label,
              style: Sk.ui(context,
                  size: 14,
                  color: sel ? cs.onPrimary : cs.onSurface,
                  weight: FontWeight.w800)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Text('Bütçene göre',
              style: Sk.display(context, size: 30, height: 1.1)),
          const SizedBox(width: 24),
          Wrap(spacing: 10, children: [
            tab('250 ₺ altı', 250),
            tab('500 ₺ altı', 500),
            tab('Tümü', null),
          ]),
        ]),
        const SizedBox(height: 22),
        if (list.isEmpty)
          Text('Bu bütçede seans yok.',
              style: Sk.ui(context,
                  size: 14.5,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w600))
        else
          _ScrollRow(
            height: 232 * 1.5 + 128,
            itemWidth: 232,
            gap: 24,
            children: [
              for (final HomeSession s in list.take(14))
                SizedBox(
                  width: 232,
                  child: _ShowCard(
                      show: s.show, next: s, onOpen: () => widget.onOpen(s.show)),
                ),
            ],
          ),
      ],
    );
  }
}

/// Seansı yakında bitecek oyunlar ("Son çağrı").
class _ClosingRail extends StatelessWidget {
  final List<(Show, HomeSession, int)> items; // oyun, ilk seans, kalan gün
  final void Function(Show) onOpen;
  const _ClosingRail({required this.items, required this.onOpen});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title(
            title: 'Son çağrı', subtitle: 'Perdesi yakında inecek oyunlar'),
        const SizedBox(height: 22),
        _ScrollRow(
          height: 232 * 1.5 + 128,
          itemWidth: 232,
          gap: 24,
          children: [
            for (final (Show, HomeSession, int) it in items)
              SizedBox(
                width: 232,
                child: Stack(children: [
                  _ShowCard(show: it.$1, next: it.$2, onOpen: () => onOpen(it.$1)),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cs.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                          it.$3 <= 1 ? 'Son gün' : 'Son ${it.$3} gün',
                          style: Sk.ui(context,
                              size: 12,
                              color: cs.onError,
                              weight: FontWeight.w800)),
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SAYAÇLI SAYILAR ŞERİDİ
// ═════════════════════════════════════════════════════════════════════════════

class _CountStats extends StatefulWidget {
  final List<(int, String, IconData)> items;
  const _CountStats({required this.items});

  @override
  State<_CountStats> createState() => _CountStatsState();
}

class _CountStatsState extends State<_CountStats> {
  final Key _key = UniqueKey();
  bool _go = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<(int, String, IconData)> items = [
      for (final i in widget.items)
        if (i.$1 > 0) i,
    ];
    if (items.length < 2) return const SizedBox.shrink();
    return VisibilityDetector(
      key: _key,
      onVisibilityChanged: (final i) {
        if (!_go && i.visibleFraction > 0.3 && mounted) {
          setState(() => _go = true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 48,
          runSpacing: 24,
          children: [
            for (final (int, String, IconData) it in items)
              Column(children: [
                Icon(it.$3, color: cs.primary, size: 26),
                const SizedBox(height: 8),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: _go ? it.$1 : 0),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutCubic,
                  builder: (_, final v, __) => Text('$v',
                      style: Sk.display(context, size: 42, height: 1.0)),
                ),
                const SizedBox(height: 4),
                Text(it.$2,
                    style: Sk.ui(context,
                        size: 14,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w700)),
              ]),
          ],
        ),
      ),
    );
  }
}
