import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/events/presentation/providers/event_provider.dart';
import 'package:ticketapp/shared/widgets/admin_guard.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../providers/seats_provider.dart';

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

  @override
  Widget build(final BuildContext context) {
    // Eğer ID'ler yoksa boş state göstererek seçime zorla
    if (widget.eventId == null || widget.showId == null)
      return Scaffold(body: _buildEmptyState());

    // 🔥 Tüm ilişkili veriyi (Show, Event, Layout) tek noktadan izle
    final seatingAsync = ref.watch(
        eventSeatingProvider(eventId: widget.eventId!, showId: widget.showId!));

    // Dinamik bilet durumu (SATILDI/MÜSAİT) için mevcut eventProvider'ı izle
    final eventStatus = ref.watch(eventProvider);
    final theme = context.theme;

    return AdminGuard(
      child: Scaffold(
        body: CustomAppBackground(
          child: SafeArea(
            child: seatingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (final err, final _) =>
                  Center(child: Text("Hata oluştu: $err")),
              data: (final state) => Column(
                children: [
                  _buildHeader(context, state),
                  _buildOccupancyStats(eventStatus),
                  const SizedBox(height: 10),

                  // 🚀 ETKİLEŞİMLİ KOLTUK PLANI
                  Expanded(child: _buildInteractiveMap(state, eventStatus)),

                  // 👤 SEÇİLİ KOLTUK DETAYI
                  if (_focusedSeatId != null)
                    _buildSeatDetailPanel(eventStatus, theme)
                  else
                    _buildLegend(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI BİLEŞENLERİ ---

  Widget _buildInteractiveMap(
          final EventSeatingState state, final dynamic eventStatus) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.black26, borderRadius: BorderRadius.circular(20)),
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 2.5,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildStageVisual(),
                const SizedBox(height: 20),
                _buildGrid(state.layout, eventStatus),
              ],
            ),
          ),
        ),
      );

  Widget _buildGrid(
          final Map<String, List<String>> layout, final dynamic eventStatus) =>
      Column(
        children: layout.entries
            .map((final entry) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 25,
                        child: Text(entry.key,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12))),
                    ...entry.value.map((final seatId) {
                      final info = eventStatus.seatStatus[seatId];
                      final isSold = info?['status'] == 'sold';
                      final isFocused = _focusedSeatId == seatId;

                      return GestureDetector(
                        onTap: () => setState(() => _focusedSeatId = seatId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 35,
                          height: 35,
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isSold ? Colors.redAccent : Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: isFocused
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2),
                          ),
                          child: Center(
                              child: Text(seatId.substring(1),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold))),
                        ),
                      );
                    }),
                  ],
                ))
            .toList(),
      );

  Widget _buildHeader(
          final BuildContext context, final EventSeatingState state) =>
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.show.name.toUpperCase(),
                      style: context.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  Text(state.event.date ?? "",
                      style:
                          const TextStyle(color: Colors.green, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildSeatDetailPanel(
      final dynamic eventStatus, final ThemeData theme) {
    final seatData = eventStatus.seatStatus[_focusedSeatId];
    final uid = seatData?['customerId'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: theme.colorScheme.primary.withOpacity(0.2))),
      child: uid != null
          ? _UserDetailFetcher(uid: uid)
          : const Center(child: Text("Bu koltuk şu an müsait.")),
    );
  }

  Widget _buildOccupancyStats(final dynamic eventStatus) {
    final int sold = eventStatus.seatStatus.values
        .where((final s) => s != null && s['status'] == 'sold')
        .length;
    final double percent = eventStatus.seatStatus.isEmpty
        ? 0
        : (sold / eventStatus.seatStatus.length) * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Doluluk: %${percent.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text("$sold / ${eventStatus.seatStatus.length} Bilet",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() =>
      const Center(child: Text("Lütfen bir seans seçiniz"));

  Widget _buildStageVisual() => const Column(children: [
        Divider(indent: 50, endIndent: 50),
        Text("SAHNE", style: TextStyle(letterSpacing: 5, fontSize: 10))
      ]);

  Widget _buildLegend() =>
      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.square, color: Colors.redAccent, size: 12),
        SizedBox(width: 4),
        Text("Dolu", style: TextStyle(fontSize: 12))
      ]);
}

class _UserDetailFetcher extends ConsumerWidget {
  final String uid;

  const _UserDetailFetcher({required this.uid, super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(uid));

    return userAsync.when(
      loading: () => const ShimmerLoading(),
      error: (final e, final _) => Text("Hata: $e"),
      data: (final user) {
        if (user == null) return const Text("Kullanıcı bulunamadı.");

        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                user.imageUrl.isNotEmpty ? NetworkImage(user.imageUrl) : null,
            child: user.imageUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text("${user.firstName} ${user.lastName}"),
          subtitle: Text(user.eMail),
        );
      },
    );
  }
}
