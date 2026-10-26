import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/router/app_router.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/providers/navigation_keys.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/purchase_entities.dart';
import '../providers/purchase_provider.dart';

/// Uygulama açılırken / ön plana dönerken kullanıcının yarım kalmış
/// (`held`/`paying`, süresi dolmamış) bir siparişi var mı diye bakar ve
/// "Devam et" ya da "Bırak" sunar. Süresi dolmuş siparişler sessizce yok
/// sayılır (sunucu `expireHolds` zaten bırakır).
///
/// Kullanıcı o etkinliğin koltuk ekranındaysa sormaz (ekran kendi
/// `restore`'unu yapar).
class PendingOrderGate extends ConsumerStatefulWidget {
  final Widget child;

  const PendingOrderGate({super.key, required this.child});

  @override
  ConsumerState<PendingOrderGate> createState() => _PendingOrderGateState();
}

class _PendingOrderGateState extends ConsumerState<PendingOrderGate>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((final _) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_check());
    }
  }

  Future<void> _check() async {
    if (_checking || _showing || !mounted) {
      return;
    }
    final uid = ref.read(currentUserIdProvider);
    if (uid == null || uid.isEmpty) {
      return;
    }
    _checking = true;
    try {
      final result = await ref.read(getOpenOrdersUseCaseProvider)(uid);
      if (!mounted) {
        return;
      }
      final now = ref.read(purchaseClockProvider)();
      final open = result.fold<List<PurchaseOrder>>(
        (final _) => const [],
        (final orders) => [
          for (final o in orders)
            if (o.status.isOpen && o.expiresAt != null && !o.isExpiredAt(now)) o
        ]..sort((final a, final b) => b.expiresAt!.compareTo(a.expiresAt!)),
      );
      if (open.isEmpty) {
        return;
      }
      final order = open.first;

      final router = ref.read(appRouterProvider);
      final location = router.routerDelegate.currentConfiguration.uri.toString();
      if (location.contains('/seat-selection/') &&
          location.contains(order.eventId)) {
        return;
      }

      final ctx = NavigationKeys.rootNavigator.currentContext;
      if (ctx == null || !ctx.mounted) {
        return;
      }
      _showing = true;
      final choice = await showDialog<_PendingChoice>(
        context: ctx,
        barrierDismissible: false,
        builder: (final c) => _PendingOrderDialog(order: order),
      );
      _showing = false;
      if (!mounted) {
        return;
      }
      switch (choice) {
        case _PendingChoice.resume:
          unawaited(router.push(
              '/seat-selection/${order.showId}-${order.eventId}-$uid?from=/app'));
        case _PendingChoice.release:
          await ref.read(releaseHoldUseCaseProvider)(order.id);
        case _PendingChoice.dismiss:
        case null:
          break;
      }
    } finally {
      _checking = false;
      _showing = false;
    }
  }

  @override
  Widget build(final BuildContext context) {
    // Giriş yapıldığında (ya da hesap değiştiğinde) yeniden bak.
    ref.listen<String?>(currentUserIdProvider, (final prev, final next) {
      if (next != null && next != prev) {
        unawaited(_check());
      }
    });
    return widget.child;
  }
}

enum _PendingChoice { resume, release, dismiss }

class _PendingOrderDialog extends StatelessWidget {
  final PurchaseOrder order;

  const _PendingOrderDialog({required this.order});

  @override
  Widget build(final BuildContext context) {
    final bool paying = order.status == OrderStatus.paying;
    final String seats = order.seatIds.join(', ');
    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TicketPiece(
                perforated: TicketEdge.bottom,
                shadows: AppShadows.level4(TicketInk.ink),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xxl,
                      AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TicketHeaderStrip(kind: 'YARIM KALAN BİLET'),
                      const SizedBox(height: AppSpacing.xl),
                      Semantics(
                        header: true,
                        child: Text(
                          paying
                              ? 'Ödemen tamamlanmadı'
                              : 'Koltukların senin için ayrılmış durumda',
                          style: TicketInk.headline(26),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        paying
                            ? 'Ödeme adımına geçmiştin. Devam edebilirsin; '
                                'tamamlamazsan süre dolunca koltuklar kendiliğinden bırakılır.'
                            : 'Bilet alma işlemini yarıda bıraktın. Devam '
                                'edebilir ya da koltukları bırakabilirsin.',
                        style: TextStyle(
                          color: TicketInk.inkSoft(0.72),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      if (seats.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        TicketField(
                          label: order.seatIds.length > 1
                              ? 'KOLTUKLAR'
                              : 'KOLTUK',
                          value: seats,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      TicketStampButton(
                        label: 'Devam et',
                        leading: const Icon(Icons.confirmation_number_outlined),
                        onTap: () =>
                            Navigator.of(context).pop(_PendingChoice.resume),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Center(
                        child: TicketTextLink(
                          label: paying ? 'Şimdi değil' : 'Koltukları bırak',
                          onTap: () => Navigator.of(context).pop(paying
                              ? _PendingChoice.dismiss
                              : _PendingChoice.release),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
