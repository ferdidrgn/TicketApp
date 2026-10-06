import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticketapp/features/events/presentation/providers/event_provider.dart';
import 'package:ticketapp/shared/widgets/admin_guard.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/util/responsive_utils.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/ticket/seat_plan.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../events/domain/repositories/event_repository.dart'
    show kAdminBlockCustomerId;
import '../../../users/presentation/providers/user_provider.dart';
import '../providers/seats_provider.dart';

/// Küratör/yönetici koltuk denetimi: bir seansın basılı oturma planı
/// üzerinde satılan, tutulan ve kapatılan koltuklar; bir koltuğa dokununca
/// sahibinin bilgisi. Kullanıcı tarafındaki koltuk planıyla aynı görsel
/// dil (`seat_plan.dart`).
class CuratorSeatingAuditPage extends ConsumerStatefulWidget {
  final String? eventId;
  final String? showId;

  const CuratorSeatingAuditPage({super.key, this.eventId, this.showId});

  @override
  ConsumerState<CuratorSeatingAuditPage> createState() =>
      _CuratorSeatingAuditPageState();
}

class _CuratorSeatingAuditPageState
    extends ConsumerState<CuratorSeatingAuditPage> {
  String? _focusedSeatId;
  final SeatHallPlanController _hallPlanController = SeatHallPlanController();

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (widget.eventId == null || widget.showId == null)
      return Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(child: _buildEmptyState()),
      );

    final seatingAsync = ref.watch(
        eventSeatingProvider(eventId: widget.eventId!, showId: widget.showId!));
    final seatsStatusAsync = ref.watch(eventSeatsProvider(widget.eventId!));

    return AdminGuard(
      allowDebugBypass: true,
      child: Scaffold(
        backgroundColor: cs.surface,
        body: TicketStage(
          themed: true,
          child: SafeArea(
            child: seatingAsync.when(
              loading: () => const _AuditSkeleton(),
              error: (final err, final _) => _AuditError(
                message: 'Seans ve salon bilgisi yüklenemedi.',
                error: err,
                onRetry: () => ref.invalidate(eventSeatingProvider(
                    eventId: widget.eventId!, showId: widget.showId!)),
              ),
              data: (final state) => seatsStatusAsync.when(
                loading: () => const _AuditSkeleton(),
                error: (final err, final _) => _AuditError(
                  message: 'Canlı koltuk durumu alınamadı.',
                  error: err,
                  onRetry: () =>
                      ref.invalidate(eventSeatsProvider(widget.eventId!)),
                ),
                data: (final seatsStatus) => Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveUtils.isLargeDesktop(context)
                          ? 1440
                          : (ResponsiveUtils.isDesktop(context) ? 1280 : 760),
                    ),
                    child: Column(
                      children: [
                        _buildHeader(context, state),
                        _buildOccupancyStats(seatsStatus),
                        const SizedBox(height: AppSpacing.md),
                        Expanded(
                            child: _buildInteractiveMap(state, seatsStatus)),
                        const SizedBox(height: AppSpacing.md),
                        if (_focusedSeatId != null)
                          _buildSeatDetailPanel(seatsStatus),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI BİLEŞENLERİ ---

  SeatVisual _visualOf(
          final Map<String, Map<String, dynamic>> status, final String id) =>
      seatVisualOf(
        status: status[id]?['status']?.toString() ?? 'available',
        ownerId: status[id]?['customerId']?.toString(),
        customerId: '',
      );

  Widget _buildInteractiveMap(final EventSeatingState state,
      final Map<String, Map<String, dynamic>> seatsStatus) {
    // Salon planı sahne düzeninden gelir; yoksa seansın kendi koltukları.
    final Iterable<String> ids = state.layout.isNotEmpty
        ? state.layout.values.expand((final r) => r)
        : seatsStatus.keys;
    final rows = groupSeatsByRow(ids);

    final Set<SeatVisual> present = {
      for (final id in rows.values.expand((final r) => r))
        _visualOf(seatsStatus, id),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TicketPiece(
        perforated: TicketEdge.bottom,
        shadows: AppShadows.level2(Theme.of(context).colorScheme.shadow),
        child: rows.isEmpty
            ? Center(
                child: Text('Bu sahne için koltuk planı tanımlı değil.',
                    style: TicketInk.value()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        SeatHallPlan(
                          controller: _hallPlanController,
                          rows: rows,
                          minSeat: 40,
                          maxSeat: 48,
                          seatBuilder: (final context, final seatId, final size) {
                        final bool isFocused = _focusedSeatId == seatId;
                        return TicketSeat(
                          seatId: seatId,
                          visual: _visualOf(seatsStatus, seatId),
                          size: size,
                          outlined: isFocused,
                          semanticLabel: '$seatId koltuğu, '
                              '${_visualOf(seatsStatus, seatId).label.toLowerCase()}'
                              '${isFocused ? ', incelemede' : ''}',
                          onTap: () =>
                              setState(() => _focusedSeatId = seatId),
                        );
                      },
                        ),
                        SeatPlanZoomBar(controller: _hallPlanController),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    child: SeatLegend(visible: [
                      SeatVisual.available,
                      SeatVisual.held,
                      SeatVisual.sold,
                      if (present.contains(SeatVisual.blocked))
                        SeatVisual.blocked,
                    ]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(
      final BuildContext context, final EventSeatingState state) {
    final cs = Theme.of(context).colorScheme;
    final parsed = DateFormatter.parseDateString(state.event.date);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Geri',
            icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
            onPressed: () => NavigationHandler.smartGoBack(context),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    state.show.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      color: cs.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  parsed != null
                      ? 'Koltuk denetimi, ${ticketDate(parsed)} ${ticketTime(parsed)}'
                      : 'Koltuk denetimi',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatDetailPanel(
      final Map<String, Map<String, dynamic>> seatsStatus) {
    final seatId = _focusedSeatId!;
    final visual = _visualOf(seatsStatus, seatId);
    final String? uid = seatsStatus[seatId]?['customerId']?.toString();
    final bool hasCustomer = uid != null &&
        uid.isNotEmpty &&
        uid != kAdminBlockCustomerId &&
        (visual == SeatVisual.sold || visual == SeatVisual.held);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TicketPiece(
        perforated: TicketEdge.top,
        shadows: AppShadows.level2(Theme.of(context).colorScheme.shadow),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.sm, AppSpacing.lg),
          child: Row(
            children: [
              TicketField(label: 'KOLTUK', value: seatId),
              const SizedBox(width: AppSpacing.xl),
              TicketField(label: 'DURUM', value: visual.label),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: hasCustomer
                    ? _UserDetailFetcher(uid: uid!)
                    : Text(
                        visual == SeatVisual.blocked
                            ? 'Yönetici tarafından satışa kapatıldı.'
                            : 'Bu koltuk şu an müsait.',
                        style: TextStyle(
                            color: TicketInk.inkSoft(0.7), fontSize: 13.5),
                      ),
              ),
              IconButton(
                tooltip: 'Kapat',
                icon: Icon(Icons.close_rounded, color: TicketInk.inkSoft()),
                onPressed: () => setState(() => _focusedSeatId = null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 DÜZELTME: Önceden `eventSeatsProvider`'ın döndürdüğü
  /// `Map<String, Map<String, dynamic>>` `dynamic` olarak alınıp üzerinde
  /// var olmayan bir `.seatStatus` alanı okunuyordu — sayfa açılır açılmaz
  /// `NoSuchMethodError` ile çöküyordu. Artık doğrudan harita kullanılıyor.
  Widget _buildOccupancyStats(
      final Map<String, Map<String, dynamic>> seatsStatus) {
    final cs = Theme.of(context).colorScheme;
    int sold = 0, held = 0, blocked = 0;
    for (final id in seatsStatus.keys) {
      switch (_visualOf(seatsStatus, id)) {
        case SeatVisual.sold:
        case SeatVisual.owned:
          sold++;
        case SeatVisual.held:
        case SeatVisual.selected:
          held++;
        case SeatVisual.blocked:
          blocked++;
        case SeatVisual.available:
          break;
      }
    }
    final int total = seatsStatus.length;
    final double percent = total == 0 ? 0 : (sold / total) * 100;

    Widget stat(final String label, final String value) => Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          runSpacing: AppSpacing.sm,
          children: [
            stat('DOLULUK', '%${percent.toStringAsFixed(0)}'),
            stat('SATILAN', '$sold / $total'),
            stat('TUTULAN', '$held'),
            if (blocked > 0) stat('KAPALI', '$blocked'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Denetlemek için bir seans seç.',
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () => NavigationHandler.smartGoBack(context),
                child: const Text('Geri dön'),
              ),
            ],
          ),
        ),
      );
}

class _AuditSkeleton extends StatelessWidget {
  const _AuditSkeleton();

  @override
  Widget build(final BuildContext context) => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerLoading(height: 28, width: 240, borderRadius: AppRadius.xs),
            SizedBox(height: AppSpacing.lg),
            ShimmerLoading(height: 40, width: 320, borderRadius: AppRadius.xs),
            SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ShimmerLoading(
                  height: double.infinity,
                  width: double.infinity,
                  borderRadius: AppRadius.md),
            ),
          ],
        ),
      );
}

class _AuditError extends StatelessWidget {
  final String message;
  final Object error;
  final VoidCallback onRetry;

  const _AuditError(
      {required this.message, required this.error, required this.onRetry});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Text('$error',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDetailFetcher extends ConsumerWidget {
  final String uid;

  const _UserDetailFetcher({required this.uid});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(uid));

    return userAsync.when(
      loading: () => const ShimmerLoading(height: 40, width: 220),
      error: (final e, final _) => Text("Kullanıcı bilgisi alınamadı: $e",
          style: TextStyle(color: TicketInk.inkSoft(0.7), fontSize: 13)),
      data: (final user) {
        if (user == null)
          return Text("Kullanıcı bulunamadı.",
              style: TextStyle(color: TicketInk.inkSoft(0.7), fontSize: 13));

        return Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  user.imageUrl.isNotEmpty ? NetworkImage(user.imageUrl) : null,
              child: user.imageUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${user.firstName} ${user.lastName}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TicketInk.value()),
                  Text(user.eMail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: TicketInk.inkSoft(0.6), fontSize: 12.5)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
