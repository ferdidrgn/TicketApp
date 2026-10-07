import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/common/extentions/app_context_ui_extension.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/shows/presentation/widgets/detail/show_detail_data.dart';
import 'ticket/ticket_kit.dart';

/// Oyun/oyuncu detayının ortak metaforu: tiyatro programı (playbill).
/// Perde süsü yok; perde açılışı sadece yazıda (`AuthWipeReveal`).

class PlaybillActHeader extends StatelessWidget {
  final String act;
  final String title;
  final String? meta;

  const PlaybillActHeader({
    super.key,
    required this.act,
    required this.title,
    this.meta,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          act,
          style: GoogleFonts.playfairDisplay(
            color: colors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            height: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    color: colors.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            if (meta != null) ...[
              const SizedBox(width: AppSpacing.md),
              Text(
                meta!,
                style: context.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TitleInkMark(color: colors.primary),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class PlaybillQuote extends StatelessWidget {
  final String text;
  final Animation<double>? reveal;

  const PlaybillQuote({super.key, required this.text, this.reveal});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final Widget body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '“',
          style: GoogleFonts.playfairDisplay(
            color: colors.primary,
            fontSize: 44,
            height: 0.85,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.playfairDisplay(
              color: colors.onSurface,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
    if (reveal == null) return body;
    return AuthWipeReveal(reveal: reveal!, child: body);
  }
}

/// Satıştaki seanslar: kaydırılan tarih kartları. Dokununca koltuk.
class PlaybillSessionStrip extends StatelessWidget {
  final List<ShowSession> sessions;
  final void Function(ShowSession session) onSelect;

  const PlaybillSessionStrip({
    super.key,
    required this.sessions,
    required this.onSelect,
  });

  @override
  Widget build(final BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sessions.length,
        separatorBuilder: (final _, final __) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (final context, final i) {
          final ShowSession session = sessions[i];
          final DateTime? d = session.when;
          final String day = d == null ? '—' : '${d.day}';
          final String week =
              d == null ? '' : trWeekdaysShort[d.weekday - 1];
          final String month =
              d == null ? session.event.date.trim() : trMonthsShort[d.month - 1];
          final String time = d == null ? '' : hhmm(d);
          return Semantics(
            button: true,
            label: session.semanticLabel,
            excludeSemantics: true,
            child: Material(
              color: i == 0
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(session);
                },
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 88,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          week,
                          style: TextStyle(
                            color: i == 0
                                ? colors.onPrimaryContainer
                                : colors.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          day,
                          style: GoogleFonts.playfairDisplay(
                            color: i == 0
                                ? colors.onPrimaryContainer
                                : colors.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        Text(
                          month,
                          style: TextStyle(
                            color: i == 0
                                ? colors.onPrimaryContainer
                                : colors.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: TextStyle(
                              color: i == 0
                                  ? colors.onPrimaryContainer
                                  : colors.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Afiş kapağı: Ken Burns + isim perde açılışı. Tek koreografi.
class PlaybillCoverTitle extends StatelessWidget {
  final String title;
  final Animation<double> reveal;
  final Color color;

  const PlaybillCoverTitle({
    super.key,
    required this.title,
    required this.reveal,
    required this.color,
  });

  @override
  Widget build(final BuildContext context) => Semantics(
        header: true,
        child: AuthWipeReveal(
          reveal: reveal,
          child: Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: color,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
      );
}

