import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/ticket/ticket_kit.dart';
import '../show_team_credit.dart';
import 'show_detail_data.dart';

/// Oyun biletinin hangi kompozisyonda basıldığı.
/// - [stacked]: mobil / dar web — dikey bilet, afiş biletin ÜSTÜNDE ayrı bir
///   bant olarak durur, birincil aksiyon alttaki yapışkan çubukta.
/// - [aside]: masaüstü — yapışkan yan panelde dikey bilet, afiş biletin
///   içinde, birincil aksiyon koçanda.
/// - [banner]: web tablet — yatay bilet (koçan sağda), afiş gövdenin solunda,
///   birincil aksiyon koçanda.
enum ShowTicketLayout { stacked, aside, banner }

/// Oyun biletinin gövdesi: marka şeridi + tür, (gerekirse) gerçek afiş,
/// oyun adı (perde açılışıyla), prodüksiyon ve bilet alanları (SÜRE /
/// YAŞ SINIRI / TÜR). Boş alan basılmaz.
class ShowTicketBody extends StatelessWidget {
  final ShowDetailData data;
  final ShowTicketLayout layout;
  final Animation<double> headlineReveal;
  final Animation<double> detailsFade;

  /// Sadece [ShowTicketLayout.aside] için afiş yüksekliği.
  final double posterHeight;

  const ShowTicketBody({
    super.key,
    required this.data,
    required this.layout,
    required this.headlineReveal,
    required this.detailsFade,
    this.posterHeight = 280,
  });

  @override
  Widget build(final BuildContext context) {
    final show = data.show;
    final bool hasPoster = show.imageUrl.trim().isNotEmpty;

    final double headlineSize = switch (layout) {
      ShowTicketLayout.stacked => 32.0,
      ShowTicketLayout.aside => 34.0,
      ShowTicketLayout.banner => 36.0,
    };

    final Widget headline = Semantics(
      header: true,
      child: AuthWipeReveal(
        reveal: headlineReveal,
        child: Text(show.name, style: TicketInk.headline(headlineSize)),
      ),
    );

    final Widget credit = FadeTransition(
      opacity: detailsFade,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ShowTeamCredit(teamId: show.teamId, onPaper: true),
      ),
    );

    final fields = <Widget>[
      if (show.duration.trim().isNotEmpty)
        TicketField(label: 'SÜRE', value: show.duration.trim()),
      if (show.ageLimit.trim().isNotEmpty)
        TicketField(label: 'YAŞ SINIRI', value: show.ageLimit.trim()),
      if (data.typeField.isNotEmpty)
        TicketField(label: 'TÜR', value: data.typeField),
    ];
    final Widget? fieldsRow = fields.isEmpty
        ? null
        : FadeTransition(
            opacity: detailsFade,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < fields.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.lg),
                  Expanded(child: fields[i]),
                ],
              ],
            ),
          );

    final Widget strip = TicketHeaderStrip(kind: data.kindLabel);

    switch (layout) {
      case ShowTicketLayout.stacked:
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              strip,
              const SizedBox(height: AppSpacing.xl),
              headline,
              const SizedBox(height: AppSpacing.md),
              credit,
              if (fieldsRow != null) ...[
                const SizedBox(height: AppSpacing.lg),
                fieldsRow,
              ],
            ],
          ),
        );

      case ShowTicketLayout.aside:
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              strip,
              if (hasPoster) ...[
                const SizedBox(height: AppSpacing.xl),
                _TicketPoster(
                    url: show.imageUrl, name: show.name, height: posterHeight),
              ],
              const SizedBox(height: AppSpacing.xl),
              headline,
              const SizedBox(height: AppSpacing.md),
              credit,
              if (fieldsRow != null) ...[
                const SizedBox(height: AppSpacing.lg),
                fieldsRow,
              ],
            ],
          ),
        );

      case ShowTicketLayout.banner:
        return ConstrainedBox(
          // Koçan gövdenin yüksekliğine uyar; afişsiz kısa bir gövdede
          // koçandaki aksiyon sıkışmasın.
          constraints: const BoxConstraints(minHeight: 300),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                strip,
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasPoster) ...[
                      SizedBox(
                        width: 150,
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: _TicketPoster(
                              url: show.imageUrl, name: show.name),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxl),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          headline,
                          const SizedBox(height: AppSpacing.md),
                          credit,
                          if (fieldsRow != null) ...[
                            const SizedBox(height: AppSpacing.xl),
                            fieldsRow,
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
    }
  }
}

/// Biletin içine basılı gerçek afiş (Firebase'den).
class _TicketPoster extends StatelessWidget {
  final String url;
  final String name;
  final double? height;

  const _TicketPoster({required this.url, required this.name, this.height});

  @override
  Widget build(final BuildContext context) => Semantics(
        image: true,
        label: '$name afişi',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: ColoredBox(
            color: TicketInk.inkSoft(0.08),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: OptimizedCachedImage(
                imageUrl: url,
                fit: BoxFit.cover,
                borderRadius: 0,
              ),
            ),
          ),
        ),
      );
}

/// Oyun biletinin koçanı: en yakın seans, fiyat, (masaüstü/tablet'te)
/// birincil aksiyon, barkod ve gösteri kimliğinden seri numarası.
class ShowTicketStub extends StatelessWidget {
  final ShowDetailData data;
  final ShowTicketLayout layout;

  /// Koçana basılı birincil aksiyon (aside / banner). Mobilde null — orada
  /// aksiyon yapışkan alt çubukta.
  final Widget? action;

  const ShowTicketStub({
    super.key,
    required this.data,
    required this.layout,
    this.action,
  });

  @override
  Widget build(final BuildContext context) {
    final Widget serial = Text(
      data.serial,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: GoogleFonts.robotoMono(
        color: TicketInk.inkSoft(0.7),
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
    );
    final List<Widget> info = ShowStubInfo.fieldsOf(context, data);

    switch (layout) {
      case ShowTicketLayout.stacked:
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
          child: Row(
            children: [
              Expanded(child: ShowStubInfo(fields: info)),
              const SizedBox(width: AppSpacing.lg),
              SizedBox(
                width: 96,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TicketBarcode(seed: data.show.id, height: 40),
                    const SizedBox(height: AppSpacing.xs),
                    serial,
                  ],
                ),
              ),
            ],
          ),
        );

      case ShowTicketLayout.aside:
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxl, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShowStubInfo(fields: info),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.xl),
                action!,
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                      child: TicketBarcode(seed: data.show.id, height: 30)),
                  const SizedBox(width: AppSpacing.md),
                  serial,
                ],
              ),
            ],
          ),
        );

      case ShowTicketLayout.banner:
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < info.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                info[i],
              ],
              const Spacer(),
              if (action != null) ...[
                action!,
                const SizedBox(height: AppSpacing.lg),
              ],
              TicketBarcode(seed: data.show.id, height: 28),
              const SizedBox(height: AppSpacing.xs),
              serial,
            ],
          ),
        );
    }
  }
}

/// Koçan bilgileri: harici satışta açıklama; değilse en yakın seans + fiyat
/// (ya da "satışta seans yok").
class ShowStubInfo extends StatelessWidget {
  final List<Widget> fields;
  const ShowStubInfo({super.key, required this.fields});

  static List<Widget> fieldsOf(
      final BuildContext context, final ShowDetailData data) {
    if (data.isExternal) return [const ShowExternalNote()];
    final ShowSession? next = data.nextSession;
    final double? lowest = data.lowestPrice;
    final bool manyPrices = data.sessions
            .map((final s) => s.price)
            .whereType<double>()
            .toSet()
            .length >
        1;
    return [
      if (next != null)
        TicketField(label: 'EN YAKIN SEANS', value: next.shortLabel)
      else
        const TicketField(label: 'SEANS', value: 'Satışta seans yok'),
      if (lowest != null)
        TicketField(
          label: manyPrices ? 'EN UYGUN' : 'FİYAT',
          value: formatTicketPrice(lowest),
        ),
    ];
  }

  @override
  Widget build(final BuildContext context) {
    if (fields.length == 1) return fields.first;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: fields[0]),
        const SizedBox(width: AppSpacing.md),
        Expanded(flex: 2, child: fields[1]),
      ],
    );
  }
}

/// Biletleri başka bir platformda satılan oyunlar için kağıda basılı not.
class ShowExternalNote extends StatelessWidget {
  const ShowExternalNote({super.key});

  @override
  Widget build(final BuildContext context) {
    final Color accent = TicketInk.accentOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('SATIŞ', style: TicketInk.label()),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.open_in_new_rounded, size: 14, color: accent),
            ),
            const SizedBox(width: AppSpacing.xs + 2),
            Flexible(
              child: Text(
                'Biletler başka bir platformda satılıyor',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TicketInk.value(size: 13.5).copyWith(color: accent),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sayfanın TEK birincil aksiyonu, damga butonu olarak.
/// - Başka platformda satılan oyun → o platformun bilet sayfası.
/// - Satışta seans var → "Bilet al" (seanslara götürür).
/// - Seans yok → buton yerine açık bir not (sahte/ölü buton yok).
class ShowPrimaryStamp extends StatelessWidget {
  final ShowDetailData data;
  final VoidCallback onBuy;
  final VoidCallback onExternal;
  final bool busy;

  /// Dar koçanda (tablet) daha kısa etiket.
  final bool compact;

  const ShowPrimaryStamp({
    super.key,
    required this.data,
    required this.onBuy,
    required this.onExternal,
    this.busy = false,
    this.compact = false,
  });

  @override
  Widget build(final BuildContext context) {
    if (data.isExternal) {
      return TicketStampButton(
        label: compact ? 'Bilet sayfasına git' : 'Başka platformda bilet al',
        leading: const Icon(Icons.open_in_new_rounded),
        onTap: onExternal,
        loading: busy,
        loadingLabel: 'Açılıyor…',
      );
    }
    if (data.sessions.isEmpty) return const ShowNoSessionNote();
    return TicketStampButton(
      label: 'Bilet al',
      leading: const Icon(Icons.confirmation_number_outlined),
      onTap: onBuy,
    );
  }
}

/// Satışta seans olmadığında aksiyon yerine basılan not.
class ShowNoSessionNote extends StatelessWidget {
  const ShowNoSessionNote({super.key});

  @override
  Widget build(final BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(color: TicketInk.inkSoft(0.3), width: 1.2),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 18, color: TicketInk.inkSoft(0.6)),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Şu an satışta seans yok',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TicketInk.value(size: 13.5)
                    .copyWith(color: TicketInk.inkSoft(0.75)),
              ),
            ),
          ],
        ),
      );
}
