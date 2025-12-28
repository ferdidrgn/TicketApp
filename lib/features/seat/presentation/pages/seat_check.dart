import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';
import 'package:ticketapp/features/events/presentation/providers/event_provider.dart';
import 'package:ticketapp/features/users/presentation/providers/user_provider.dart';
import 'package:ticketapp/shared/widgets/background/custom_app_background.dart';

class CuratorSeatingAuditPage extends ConsumerStatefulWidget {
  final String eventId;
  final String showId;

  const CuratorSeatingAuditPage({
    super.key,
    required this.eventId,
    required this.showId,
  });

  @override
  ConsumerState<CuratorSeatingAuditPage> createState() =>
      _CuratorSeatingAuditPageState();
}

class _CuratorSeatingAuditPageState
    extends ConsumerState<CuratorSeatingAuditPage> {
  String? _focusedSeatId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      // Admin görünümü için event verilerini başlat
      ref.read(eventProvider.notifier).initializeWithParams(
            eventId: widget.eventId,
            showId: widget.showId,
            customerId: "ADMIN_OPERATOR",
          );
    });
  }

  @override
  Widget build(final BuildContext context) {
    final eventState = ref.watch(eventProvider);
    final theme = context.theme;

    return Scaffold(
      body: CustomAppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAuditHeader(theme, eventState),
              _buildOccupancyBar(eventState),
              const SizedBox(height: 10),

              // 🚀 KOLTUK PLANI - SCROLLABLE ALAN
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildStageVisual(theme),
                      Expanded(
                        child: InteractiveViewer(
                          // Hem zoom hem scroll desteği
                          boundaryMargin: const EdgeInsets.all(20),
                          minScale: 0.5,
                          maxScale: 2.0,
                          child: Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: _buildInteractiveGrid(eventState),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 👤 DETAY PANELİ
              if (_focusedSeatId != null)
                _buildOccupantDetailCard(eventState, theme)
              else
                _buildAuditLegend(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI BİLEŞENLERİ ---

  Widget _buildAuditHeader(final ThemeData theme, final state) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("OPERASYON PANELİ",
                    style: TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 2)),
                Text(state.isLoading ? "Yükleniyor..." : "Canlı Denetim",
                    style: TextStyle(
                        color: state.isLoading ? Colors.orange : Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      );

  Widget _buildOccupancyBar(final state) {
    int soldCount = state.seatStatus.values
        .where((final s) => s != null && s['status'] == 'sold')
        .length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Satılan Koltuk:",
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          Text("$soldCount / ${state.seatStatus.length}",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInteractiveGrid(final state) => Column(
        children: state.seatLayout.entries.map<Widget>((final entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                    width: 30,
                    child: Text(entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                ...entry.value.map<Widget>((final seatId) {
                  final info = state.seatStatus[seatId];
                  final isSold = info?['status'] == 'sold';
                  final isFocused = _focusedSeatId == seatId;

                  return GestureDetector(
                    onTap: () => setState(() => _focusedSeatId = seatId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSold ? Colors.redAccent : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isFocused ? Colors.white : Colors.white10,
                            width: isFocused ? 2 : 1),
                      ),
                      child: Center(
                        child: Text(seatId.substring(1),
                            style: TextStyle(
                                color: isSold ? Colors.white : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      );

  Widget _buildOccupantDetailCard(final eventState, final ThemeData theme) {
    final seatData = eventState.seatStatus[_focusedSeatId];
    final String? uid = seatData?['customerId'];
    final bool isSold = seatData?['status'] == 'sold';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: _neuBox(theme),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Koltuk $_focusedSeatId",
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 20)),
              _statusChip(isSold),
            ],
          ),
          const Divider(height: 30),
          if (isSold && uid != null)
            _UserDetailFetcher(uid: uid) // 🚀 Gerçek isim çeken parça
          else
            const Text("Bu koltuk şu an müsait.",
                style:
                    TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _statusChip(final bool sold) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: sold ? Colors.red : Colors.green,
            borderRadius: BorderRadius.circular(6)),
        child: Text(sold ? "SATILDI" : "MÜSAİT",
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      );

  Widget _buildStageVisual(final ThemeData theme) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
                height: 4,
                width: 100,
                decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 4),
            const Text("SAHNE",
                style: TextStyle(
                    fontSize: 9, letterSpacing: 4, color: Colors.grey)),
          ],
        ),
      );

  Widget _buildAuditLegend() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(Colors.white10, "Müsait"),
            const SizedBox(width: 20),
            _legend(Colors.redAccent, "Dolu"),
          ],
        ),
      );

  Widget _legend(final Color c, final String t) => Row(children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: c, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(t, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]);

  BoxDecoration _neuBox(final ThemeData theme) => BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(8, 8),
              blurRadius: 16),
          BoxShadow(
              color: Colors.white.withOpacity(0.05),
              offset: const Offset(-8, -8),
              blurRadius: 16),
        ],
      );
}

// 🔥 GERÇEK VERİ ÇEKEN VE HATALARI YÖNETEN WIDGET
// 🔥 REFRESH HATASI DÜZELTİLMİŞ WIDGET
class _UserDetailFetcher extends ConsumerStatefulWidget {
  final String uid;

  const _UserDetailFetcher({required this.uid, super.key});

  @override
  ConsumerState<_UserDetailFetcher> createState() => _UserDetailFetcherState();
}

class _UserDetailFetcherState extends ConsumerState<_UserDetailFetcher> {
  // Future nesnesini burada tanımlıyoruz ki her build'da yenilenmesin
  late Future<dynamic> _userFuture;

  @override
  void initState() {
    super.initState();
    // İşlemi sadece widget ilk oluştuğunda (veya UID değiştiğinde) başlatıyoruz
    _initFuture();
  }

  @override
  void didUpdateWidget(final _UserDetailFetcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Eğer farklı bir koltuğa tıklandıysa ve UID değiştiyse future'ı yenile
    if (oldWidget.uid != widget.uid) {
      _initFuture();
    }
  }

  void _initFuture() {
    _userFuture = ref.read(getUserByIdUseCaseProvider).call(widget.uid);
  }

  @override
  Widget build(final BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _userFuture, // 🚀 Sabitlenmiş future kullanılıyor
      builder: (final context, final snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final result = snapshot.data;
        if (result == null) return const Text("Veri yok");

        return result.fold(
          (final failure) => _buildError(failure.message),
          (final user) => _buildUserInfo(user),
        );
      },
    );
  }

  // --- UI PARÇALARI ---

  Widget _buildUserInfo(final dynamic user) {
    final fullName = "${user.firstName} ${user.lastName}";
    return Column(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: context.theme.colorScheme.primary.withOpacity(0.2),
          backgroundImage: user.imageUrl.isNotEmpty == true
              ? NetworkImage(user.imageUrl)
              : null,
          child:
              user.imageUrl.isEmpty ? const Icon(Icons.person, size: 30) : null,
        ),
        const SizedBox(height: 12),
        Text(fullName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("E-posta: ${user.eMail}",
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        _buildPhoneBadge(user.phoneNumber),
      ],
    );
  }

  Widget _buildPhoneBadge(final String phone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.phone_android_rounded, size: 16, color: Colors.blue),
          const SizedBox(width: 10),
          Text(phone.isNotEmpty ? phone : "Telefon Yok",
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildError(final String message) => Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 30),
          Text("Hata: $message", style: const TextStyle(fontSize: 12)),
        ],
      );
}
