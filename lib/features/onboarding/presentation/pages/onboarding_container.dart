import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import 'package:ticketapp/core/services/onboarding_service.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';

/// 🎨 Uygulamayı tanıtan, "tatlı"/samimi illüstratif kartlarla ilerleyen
/// çok sayfalı onboarding akışı. Son sayfada bildirim ve konum izinlerini
/// ister. Daha önce bu ekran hiçbir yerden tetiklenmiyordu (route vardı
/// ama ona yönlendiren hiçbir mantık yoktu) — artık ilk açılışta
/// (OnboardingService + app_router.dart) otomatik gösteriliyor.
class OnboardingContainer extends ConsumerStatefulWidget {
  const OnboardingContainer({super.key});

  @override
  ConsumerState<OnboardingContainer> createState() =>
      _OnboardingContainerState();
}

class _OnboardingPageData {
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  const _OnboardingPageData({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}

const _kPages = [
  _OnboardingPageData(
    eyebrow: 'TiyatRol.',
    title: 'Sahneleri\nKeşfet',
    description:
        'Şehrinin en iyi tiyatro, müzikal ve konserlerini tek yerde keşfet. Küratörlerin seçtiği en özel yapımlar seni bekliyor.',
    icon: Icons.theater_comedy_rounded,
    gradient: [Color(0xFFFF9A8B), Color(0xFFFF6A88)],
  ),
  _OnboardingPageData(
    eyebrow: 'TiyatRol.',
    title: 'Bileti Al,\nYerini Kap',
    description:
        'Koltuk planından yerini seç, saniyeler içinde biletini oluştur. Sıra derdi yok, kuyrukta bekleme yok.',
    icon: Icons.confirmation_number_rounded,
    gradient: [Color(0xFF6366F1), Color(0xFF818CF8)],
  ),
  _OnboardingPageData(
    eyebrow: 'TiyatRol.',
    title: 'Favorilerini\nBiriktir',
    description:
        'Beğendiğin oyunları, sahneleri ve sanatçıları kalbine ekle; hepsine tek dokunuşla geri dön.',
    icon: Icons.favorite_rounded,
    gradient: [Color(0xFF10B981), Color(0xFF34D399)],
  ),
];

class _OnboardingContainerState extends ConsumerState<OnboardingContainer> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  int get _pageCount => _kPages.length + 1; // + izin sayfası

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await OnboardingService.markSeen();
    if (mounted) NavigationHandler.goToHome(context);
  }

  @override
  Widget build(final BuildContext context) {
    final bool isLargeScreen = context.isTablet || context.isDesktop;
    final bool isLastPage = _currentPage == _pageCount - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isLargeScreen ? 480 : double.infinity),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: isLastPage
                        ? const SizedBox(height: 48)
                        : TextButton(
                            onPressed: _finish,
                            child: const Text('Atla',
                                style: TextStyle(
                                    color: Color(0xFF71717A),
                                    fontWeight: FontWeight.w700)),
                          ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (final i) => setState(() => _currentPage = i),
                    children: [
                      for (final page in _kPages) _OnboardingFeaturePage(data: page),
                      _OnboardingPermissionPage(onFinish: _finish),
                    ],
                  ),
                ),
                _PageIndicator(count: _pageCount, current: _currentPage),
                const SizedBox(height: 24),
                if (!isLastPage)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF18181B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Text('DEVAM ET',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingFeaturePage extends StatelessWidget {
  final _OnboardingPageData data;
  const _OnboardingFeaturePage({required this.data});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.eyebrow,
                style: const TextStyle(
                    color: Color(0xFF18181B),
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
            const SizedBox(height: 28),
            AspectRatio(
              aspectRatio: 1.15,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    colors: data.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: data.gradient.last.withOpacity(0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 16)),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Icon(data.icon,
                          size: 140, color: Colors.white.withOpacity(0.16)),
                    ),
                    Center(
                      child: Container(
                        width: 92,
                        height: 92,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(data.icon, size: 44, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(data.title,
                style: const TextStyle(
                    color: Color(0xFF18181B),
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
            const SizedBox(height: 14),
            Text(data.description,
                style: const TextStyle(
                    color: Color(0xFF71717A), fontSize: 15, height: 1.5)),
          ],
        ),
      );
}

class _OnboardingPermissionPage extends StatefulWidget {
  final VoidCallback onFinish;
  const _OnboardingPermissionPage({required this.onFinish});

  @override
  State<_OnboardingPermissionPage> createState() =>
      _OnboardingPermissionPageState();
}

class _OnboardingPermissionPageState extends State<_OnboardingPermissionPage> {
  bool? _notificationGranted;
  bool? _locationGranted;

  Future<void> _requestNotification() async {
    final status = await Permission.notification.request();
    if (mounted) setState(() => _notificationGranted = status.isGranted);
  }

  Future<void> _requestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    if (mounted) setState(() => _locationGranted = status.isGranted);
  }

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TiyatRol.',
                style: TextStyle(
                    color: Color(0xFF18181B),
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
            const SizedBox(height: 28),
            const Text('Seni Hiç\nKaçırmayalım',
                style: TextStyle(
                    color: Color(0xFF18181B),
                    fontSize: 32,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
            const SizedBox(height: 14),
            const Text(
                'Yeni oyunlar, kampanyalar ve yakınındaki etkinlikler için iki küçük izin isteyeceğiz — istediğin an Ayarlar\'dan değiştirebilirsin.',
                style: TextStyle(color: Color(0xFF71717A), fontSize: 15, height: 1.5)),
            const SizedBox(height: 32),
            _PermissionTile(
              icon: Icons.notifications_active_rounded,
              color: const Color(0xFF6366F1),
              title: 'Bildirimler',
              subtitle: 'Kampanya ve bilet güncellemelerini kaçırma',
              granted: _notificationGranted,
              onTap: _requestNotification,
            ),
            const SizedBox(height: 16),
            _PermissionTile(
              icon: Icons.location_on_rounded,
              color: const Color(0xFF10B981),
              title: 'Konum',
              subtitle: 'Yakınındaki etkinlikleri sana göre sıralayalım',
              granted: _locationGranted,
              onTap: _requestLocation,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: widget.onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text('BAŞLA',
                    style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      );
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool? granted;
  final VoidCallback onTap;

  const _PermissionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: granted == true ? null : onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Color(0xFF18181B),
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Color(0xFF71717A), fontSize: 12.5)),
                    ],
                  ),
                ),
                if (granted == true)
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF10B981), size: 22)
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('İzin Ver',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _PageIndicator({required this.count, required this.current});

  @override
  Widget build(final BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (final i) {
          final active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
}
