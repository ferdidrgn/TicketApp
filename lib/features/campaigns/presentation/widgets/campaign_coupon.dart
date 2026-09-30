import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../domain/entities/campaign.dart';

/// KAMPANYA = KUPON. Bir kampanya fiziksel bir kupondur: gövdesinde gerçek
/// görsel + başlık, delik çizgisinin ardındaki koçanda geçerlilik tarihleri
/// ve barkod. Sadece `Campaign`'in gerçek alanları basılır (başlık, görsel,
/// başlangıç/bitiş, link); açıklama/indirim oranı gibi olmayan bir alan
/// uydurulmaz.

// ─────────────────────────────────────────────────────────────────────────
// Gerçek veriden türetilen bilgiler
// ─────────────────────────────────────────────────────────────────────────

/// "2026-10-15", "2026-10-15T00:00:00Z", "15.10.2026" gibi biçimleri anlar;
/// anlayamazsa `null` (metin olduğu gibi basılır, tarih uydurulmaz).
DateTime? _parseCampaignDate(final String raw) {
  final String t = raw.trim();
  if (t.isEmpty) return null;
  final DateTime? iso = DateTime.tryParse(t);
  if (iso != null) return iso.toLocal();
  final RegExpMatch? m =
      RegExp(r'^(\d{1,2})[./-](\d{1,2})[./-](\d{4})').firstMatch(t);
  if (m == null) return null;
  return DateTime(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
}

/// Kuponun geçerlilik bilgisi.
class CampaignValidity {
  final String? from;
  final String? until;

  /// Bitiş tarihi okunabildiyse ve geçmişse.
  final bool expired;

  /// Bitişe kalan gün (bugün = 0); okunamadıysa null.
  final int? daysLeft;

  const CampaignValidity({
    this.from,
    this.until,
    this.expired = false,
    this.daysLeft,
  });

  factory CampaignValidity.of(final Campaign c) {
    final DateTime? start = _parseCampaignDate(c.startDate);
    final DateTime? end = _parseCampaignDate(c.endDate);
    final String? from = c.startDate.trim().isEmpty
        ? null
        : (start == null ? c.startDate.trim() : ticketDate(start));
    final String? until = c.endDate.trim().isEmpty
        ? null
        : (end == null ? c.endDate.trim() : ticketDate(end));
    if (end == null) return CampaignValidity(from: from, until: until);
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int days =
        DateTime(end.year, end.month, end.day).difference(today).inDays;
    return CampaignValidity(
      from: from,
      until: until,
      expired: days < 0,
      daysLeft: days < 0 ? null : days,
    );
  }

  bool get hasDates => from != null || until != null;

  /// Kısa durum cümlesi — sadece gerçekten söylenecek bir şey varsa.
  String? get status {
    if (expired) return 'Süresi doldu';
    if (daysLeft == null) return null;
    if (daysLeft == 0) return 'Bugün son gün';
    if (daysLeft! <= 7) return 'Son $daysLeft gün';
    return null;
  }
}

/// Kampanyanın linki: uygulama içi yol (`/show/...`) → router; tam adres
/// (`https://...`) → tarayıcı. Boşsa null (buton pasif görünür).
VoidCallback? campaignOpenAction(final Campaign campaign) {
  final String url = campaign.url.trim();
  if (url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return null;
    return () => launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  final String path = url.startsWith('/') ? url : '/$url';
  return () => NavigationHandler.globalGoTo(path);
}

/// Kampanyayı paylaşır. Önceden `shareShow(id: campaign.id)` çağrılıyordu:
/// kampanya kimliğiyle bir OYUN linki (`/show/<başlık>-<kampanyaId>`) ve
/// "oyununu kaçırma" metni üretiyordu — açılınca bulunamayan bir oyun
/// sayfasıydı. Artık kampanyanın kendi hedefi paylaşılır.
Future<void> shareCampaign(final Campaign campaign) async {
  const String base = 'https://tiyatrol.web.app';
  final String url = campaign.url.trim();
  final String link = url.startsWith('http')
      ? url
      : (url.isEmpty
          ? '$base/campaign-details'
          : '$base${url.startsWith('/') ? url : '/$url'}');
  await Share.share('TiyatRol kampanyası: ${campaign.title}\n$link');
}

// ─────────────────────────────────────────────────────────────────────────
// Koçan içeriği (dikey ve yatay kuponda ortak)
// ─────────────────────────────────────────────────────────────────────────

class _ValidityFields extends StatelessWidget {
  final CampaignValidity validity;
  final Axis direction;

  const _ValidityFields({required this.validity, required this.direction});

  @override
  Widget build(final BuildContext context) {
    final List<Widget> fields = [
      if (validity.from != null && validity.until != null) ...[
        TicketField(label: 'BAŞLANGIÇ', value: validity.from!),
        TicketField(label: 'SON GÜN', value: validity.until!),
      ] else if (validity.until != null)
        TicketField(label: 'SON GÜN', value: validity.until!)
      else if (validity.from != null)
        TicketField(label: 'BAŞLANGIÇ', value: validity.from!),
    ];
    final String? status = validity.status;
    final Widget statusText = Text(
      status ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TicketInk.label(
        color: validity.expired
            ? TicketInk.inkSoft(0.5)
            : TicketInk.accentOf(context),
      ).copyWith(letterSpacing: 1.2),
    );

    if (direction == Axis.horizontal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (int i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.lg),
                Flexible(child: fields[i]),
              ],
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: AppSpacing.xs),
            statusText,
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          fields[i],
        ],
        if (status != null) ...[
          const SizedBox(height: AppSpacing.md),
          statusText,
        ],
      ],
    );
  }
}

Widget _couponImage(final Campaign campaign) => ColoredBox(
      color: TicketInk.inkSoft(0.08),
      child: OptimizedCachedImage(
        imageUrl: campaign.imageUrl,
        fit: BoxFit.cover,
        borderRadius: 0,
      ),
    );

// ─────────────────────────────────────────────────────────────────────────
// Dikey kupon (mobil kaydırıcı): gövde üstte, koçan altta
// ─────────────────────────────────────────────────────────────────────────

/// Verilen yüksekliği dolduran dikey kupon. Aksiyon kuponun DIŞINDA
/// (sayfanın alt çubuğunda) durur — kaydırıcıda her kupona buton basılmaz.
class CampaignCoupon extends StatelessWidget {
  final Campaign campaign;
  final List<BoxShadow>? shadows;

  const CampaignCoupon({super.key, required this.campaign, this.shadows});

  static const double _stubHeight = 108;

  @override
  Widget build(final BuildContext context) {
    final CampaignValidity validity = CampaignValidity.of(campaign);
    final List<BoxShadow> s = shadows ?? AppShadows.level2(TicketInk.ink);

    return Semantics(
      container: true,
      label: [
        'Kampanya: ${campaign.title}',
        if (validity.until != null) 'son gün ${validity.until}',
        if (validity.status != null) validity.status!,
      ].join(', '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TicketPiece(
              perforated: TicketEdge.bottom,
              shadows: s,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _couponImage(campaign)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
                    child: Text(
                      campaign.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TicketInk.headline(22).copyWith(height: 1.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: _stubHeight,
                child: TicketPiece(
                  perforated: TicketEdge.top,
                  shadows: s,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: validity.hasDates || validity.status != null
                              ? _ValidityFields(
                                  validity: validity,
                                  direction: Axis.horizontal)
                              : Text('TİYATROL KAMPANYASI',
                                  style: TicketInk.label()),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        SizedBox(
                          width: 72,
                          child: TicketBarcode(seed: campaign.id, height: 40),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: -1,
                left: 0,
                right: 0,
                height: 2,
                child: TicketPerforation(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Yatay kupon (tablet + masaüstü öne çıkan): gövde solda, koçan sağda
// ─────────────────────────────────────────────────────────────────────────

/// Öne çıkan kampanya. Sayfanın TEK birincil aksiyonu ("Kampanyayı
/// incele") gövdeye basılı damga butonudur; paylaş ikincil bir metin
/// bağlantısıdır.
class CampaignFeaturedCoupon extends StatelessWidget {
  final Campaign campaign;

  const CampaignFeaturedCoupon({super.key, required this.campaign});

  @override
  Widget build(final BuildContext context) {
    final CampaignValidity validity = CampaignValidity.of(campaign);
    final VoidCallback? open = campaignOpenAction(campaign);

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(aspectRatio: 16 / 9, child: _couponImage(campaign)),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxl, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  campaign.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TicketInk.headline(28).copyWith(height: 1.12),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    child: TicketStampButton(
                      label: validity.expired
                          ? 'Kampanyayı gör'
                          : 'Kampanyayı incele',
                      leading: const Icon(Icons.local_offer_outlined),
                      onTap: open,
                    ),
                  ),
                  TicketTextLink(
                    label: 'Paylaş',
                    onTap: () => shareCampaign(campaign),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final Widget stub = Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KUPON', style: TicketInk.label()),
          const SizedBox(height: AppSpacing.xs),
          Container(height: 1, color: TicketInk.inkSoft(0.4)),
          const SizedBox(height: AppSpacing.lg),
          if (validity.hasDates || validity.status != null)
            _ValidityFields(validity: validity, direction: Axis.vertical),
          const Spacer(),
          TicketBarcode(seed: campaign.id, height: 48),
        ],
      ),
    );

    return AdmitTicket(
      direction: Axis.horizontal,
      stubExtent: 190,
      shadows: AppShadows.level2(TicketInk.ink),
      body: body,
      stub: stub,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Kampanya seçici satırı (masaüstü yan liste, tablet ızgara)
// ─────────────────────────────────────────────────────────────────────────

/// Kampanyayı öne çıkarmak için seçilen sade satır. Bilet değil — temanın
/// yüzeyinde; seçili olan vurgu çerçevesiyle belli olur.
class CampaignPickerRow extends StatefulWidget {
  final Campaign campaign;
  final bool selected;
  final VoidCallback onTap;

  const CampaignPickerRow({
    super.key,
    required this.campaign,
    required this.selected,
    required this.onTap,
  });

  @override
  State<CampaignPickerRow> createState() => _CampaignPickerRowState();
}

class _CampaignPickerRowState extends State<CampaignPickerRow> {
  bool _focused = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final CampaignValidity validity = CampaignValidity.of(widget.campaign);
    final bool selected = widget.selected;
    final String? meta = validity.status ??
        (validity.until != null ? 'Son gün ${validity.until}' : null);
    final BorderRadius radius = BorderRadius.circular(AppRadius.sm);

    return Semantics(
      button: true,
      selected: selected,
      label: [widget.campaign.title, if (meta != null) meta].join(', '),
      excludeSemantics: true,
      child: Material(
        color: selected
            ? Color.alphaBlend(cs.primary.withOpacity(0.08), cs.surface)
            : cs.surfaceContainer,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (final v) => setState(() => _focused = v),
          mouseCursor: SystemMouseCursors.click,
          hoverColor: cs.onSurface.withOpacity(0.04),
          focusColor: Colors.transparent,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            foregroundDecoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: _focused || selected ? cs.primary : Colors.transparent,
                width: _focused ? 2.5 : 1.5,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: OptimizedCachedImage(
                      imageUrl: widget.campaign.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      borderRadius: 0,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.campaign.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      if (meta != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: validity.status != null && !validity.expired
                                ? cs.primary
                                : cs.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.chevron_right_rounded,
                  size: 20,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
