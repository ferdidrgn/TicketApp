import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/about/presentation/widgets/contact_card_web.dart';
import 'package:ticketapp/features/home/presentation/widgets/web/hero_video_section.dart';
import 'package:ticketapp/features/home/presentation/widgets/web/theater_section_divider.dart';
import 'package:ticketapp/features/shows/presentation/widgets/web/goz_kap_vaz_yap_landing.dart';
import 'package:ticketapp/features/shows/presentation/widgets/web/kurtar_beni_doktor_landing.dart';
import 'package:ticketapp/features/shows/presentation/widgets/web/shows_section_web.dart';
import 'package:ticketapp/features/splash/presentation/widgets/splash_data_guard.dart';
import 'package:ticketapp/features/teams/presentation/pages/team_card_web.dart';
import 'package:ticketapp/shared/widgets/background/shimmer_components.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../about/presentation/widgets/about_cart_web.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../shows/presentation/widgets/web/metafor_landing.dart';
import '../providers/home_asset_video_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  final bool startAnimations;
  final GlobalKey showsKey;
  final GlobalKey aboutKey;
  final GlobalKey teamKey;
  final GlobalKey artisticKey;
  final GlobalKey contactKey;
  final ValueNotifier<String>? activeSection;
  final ScrollController scrollController;

  const HomePage({
    super.key,
    required this.showsKey,
    required this.aboutKey,
    required this.teamKey,
    required this.artisticKey,
    required this.contactKey,
    this.activeSection,
    required this.scrollController,
    this.startAnimations = false,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey _homeKey = GlobalKey();

  // Splash sonrası animasyonları başlatmak için yerel tetikleyici
  bool _internalAnimationTrigger = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback(
        (final _) => ref.read(homeAssetsProvider.notifier).initializeVideo());
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.activeSection == null) return;
    if (!widget.scrollController.hasClients) return;

    final scrollPosition = widget.scrollController.position.pixels;

    // En tepe kontrolü
    if (scrollPosition < 150) {
      if (widget.activeSection!.value != 'home')
        widget.activeSection!.value = 'home';
      return;
    }

    final sections = {
      'shows': widget.showsKey,
      'artistic': widget.artisticKey,
      'about': widget.aboutKey,
      'team': widget.teamKey,
      'contact': widget.contactKey,
    };

    String? currentSection;
    double minDistance = double.infinity;

    sections.forEach((final key, final globalKey) {
      final context = globalKey.currentContext;
      if (context != null) {
        final RenderBox box = context.findRenderObject()! as RenderBox;
        // Sliver yapısında global pozisyon
        final position = box.localToGlobal(Offset.zero);
        // Header payı vb. için offset eklenebilir
        final distance = (position.dy - 100).abs();

        if (distance < minDistance) {
          minDistance = distance;
          currentSection = key;
        }
      }
    });

    if (currentSection != null && currentSection != widget.activeSection?.value)
      widget.activeSection?.value = currentSection!;
  }

  @override
  Widget build(final BuildContext context) {
    final videoState = ref.watch(homeAssetsProvider);
    final showState = ref.watch(showsProvider(isLimit: true));

    final bool isLoading = videoState.isLoading || showState.isLoading;
    final bool hasError = videoState.hasError || showState.hasError;
    final bool isVideoReady = videoState.hasValue && videoState.value != null;

    // 3. HATA DURUMU (En üstte kontrol edilir)
    if (hasError) return Scaffold(body: _buildWebErrorWidget(context, ref));

    // 4. YÜKLEME DURUMU (Shimmer)
    if (isLoading) return const Scaffold(body: ArtisticWebShimmer());

    // 5. ASIL İÇERİK (Data hazırsa burası çalışır)
    // Eski video başlatma mantığını buraya aldık
    if (isVideoReady && !videoState.value!.value.isPlaying)
      videoState.value!.play();

    // Animasyon tetikleyici
    if (isVideoReady && !_internalAnimationTrigger)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _internalAnimationTrigger = true);
      });

    return SplashDataGuard(
      isLoading: !isVideoReady,
      loadingMessage: 'Oyunlar yükleniyor...',
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          // Mouse ile sürüklemeyi aktif ettik, ama manuel Listener'ı kaldırdık
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
          scrollbars: false,
        ),
        child: CustomScrollView(
          controller: widget.scrollController,
          // Web için Clamping daha stabil hissettirebilir, ama Bouncing de olur
          physics: const BouncingScrollPhysics(),
          // Cache alanını büyüttük ki geri dönünce yeniden çizmesin
          cacheExtent: 3000,
          slivers: [
            // 1. Hero Section (KeepAlive Eklendi)
            // Bu sayede aşağı inip yukarı çıkınca video baştan yüklenmez/yanıp sönmez.
            SliverToBoxAdapter(
                key: _homeKey,
                child: _KeepAliveWrapper(
                    child: HeroVideoSection(
                        startAnimations: _internalAnimationTrigger))),

            // 2. Shows Section
            SliverToBoxAdapter(
                key: widget.showsKey, child: const ShowsSection()),

            const SliverToBoxAdapter(
                child: TheaterSectionDivider(
                    style: DividerStyle.spotlight, height: 150)),

            // 3. Artistic Section
            SliverToBoxAdapter(
              key: widget.artisticKey,
              child: const RepaintBoundary(child: MetaforLanding()),
            ),

            const SliverToBoxAdapter(
                child: TheaterSectionDivider(
                    style: DividerStyle.spotlight, height: 150)),

            // 4. Goz Kap Vaz Yap
            const SliverToBoxAdapter(
                child: RepaintBoundary(child: GozYapVazYapLanding())),

            const SliverToBoxAdapter(
                child: TheaterSectionDivider(
                    style: DividerStyle.spotlight, height: 150)),

            // 5. Kurtar Beni Doktor
            SliverToBoxAdapter(
                child: RepaintBoundary(child: KurtarBeniDoktorLanding())),

            const SliverToBoxAdapter(
                child: TheaterSectionDivider(
                    style: DividerStyle.iconCenter, height: 120)),

            // 6. Info Sections
            SliverToBoxAdapter(key: widget.aboutKey, child: AboutCard()),
            SliverToBoxAdapter(key: widget.teamKey, child: const TeamCard()),
            SliverToBoxAdapter(
                key: widget.contactKey, child: const ContactCard()),
            const SliverToBoxAdapter(child: Footer()),
          ],
        ),
      ),
    );
  }

  Widget _buildWebErrorWidget(final BuildContext context, final WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: context.isDarkMode ? const Color(0xFF0F0F0F) : Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.theater_comedy, size: 120, color: Colors.redAccent),
          const SizedBox(height: 40),
          Text(
            "Sahne Hazırlanamadı!",
            style: context.textTheme.displaySmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
              "Işıklar ve dekorlar yüklenirken bir sorun oluştu. Lütfen tekrar deneyin."),
          const SizedBox(height: 40),
          ElevatedButton(
              onPressed: () {
                // Provider'ları invalidate ederek veriyi tekrar çektiriyoruz
                ref.invalidate(homeAssetsProvider);
                ref.invalidate(showsProvider);
              },
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  backgroundColor: Colors.redAccent),
              child: const Text("SAHNEYİ YENİLE",
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

// 🔥 ÖNEMLİ: Widget aşağıda veya yukarıda kalsa bile hafızada tutmak için bu wrapper'ı kullanıyoruz.
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(final BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true; // Sayfa scroll olsa bile bu widget'ı öldürme
}
