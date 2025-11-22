import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/about_cart.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/contact_card.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/goz_kap_vaz_yap_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/hero_video_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/kurtar_beni_doktor_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/metafor_landing.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/shows_section.dart';
import 'package:ticketapp/presentation/web/pages/nav_pages/home/widgets/team_card.dart';
import 'widgets/footer.dart';

class HomePage extends StatefulWidget {
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
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey _homeKey = GlobalKey();

  // ----------------------------------------------------
  // HATA DÜZELTMELERİ: Eksik değişken tanımlamaları eklendi
  // ----------------------------------------------------
  bool _isMiddleMousePressed = false;
  Offset _middleMouseStartPosition = Offset.zero;
  double _scrollStartOffset = 0.0;

  // _currentMousePosition değişkeni kullanılmadığı için kaldırıldı.
  // _isMiddleMouseScrollActive değişkeni yerine _isMiddleMousePressed kullanıldı.
  // ----------------------------------------------------

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.activeSection == null) return;
    final scrollPosition = widget.scrollController.position.pixels;

    // Her section'ın pozisyonunu kontrol et
    final sections = {
      'home': _homeKey,
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
        final position = box.localToGlobal(Offset.zero);
        final sectionTop = position.dy + scrollPosition;

        // Section'un viewport'un üst kısmına olan mesafesi
        final distance = (sectionTop - scrollPosition - 100).abs();

        if (distance < minDistance) {
          minDistance = distance;
          currentSection = key;
        }
      }
    });

    if (currentSection != null &&
        currentSection != widget.activeSection?.value) {
      widget.activeSection?.value = currentSection!;
    }
  }

  void _handlePointerDown(final PointerDownEvent event) {
    // Orta fare tuşuna basıldı mı kontrol et
    if (event.buttons == kMiddleMouseButton) {
      setState(() {
        _isMiddleMousePressed = true;
        _middleMouseStartPosition = event.position;
        // HATA DÜZELTME: Doğru değişken ataması
        _scrollStartOffset = widget.scrollController.offset;
      });
    }
  }

  void _handlePointerMove(final PointerMoveEvent event) {
    // Orta fare tuşu basılıyken hareket
    if (_isMiddleMousePressed) {
      final delta = event.position - _middleMouseStartPosition;

      // Dikey hareket için scroll yap
      final newOffset = _scrollStartOffset - delta.dy;

      widget.scrollController.jumpTo(
        newOffset.clamp(
          widget.scrollController.position.minScrollExtent,
          widget.scrollController.position.maxScrollExtent,
        ),
      );
    }
  }

  void _handlePointerUp(final PointerUpEvent event) {
    // Orta fare tuşu bırakıldı
    // HATA DÜZELTME: Sadece _isMiddleMousePressed kontrolü yeterli.
    if (_isMiddleMousePressed) {
      setState(() {
        _isMiddleMousePressed = false;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    return MouseRegion(
      cursor: _isMiddleMousePressed
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.basic,
      child: Listener(
        // Normal mouse wheel scroll desteği
        onPointerSignal: (final pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            final newOffset =
                widget.scrollController.offset + pointerSignal.scrollDelta.dy;
            widget.scrollController.jumpTo(newOffset.clamp(
              widget.scrollController.position.minScrollExtent,
              widget.scrollController.position.maxScrollExtent,
            ));
          }
        },
        // Orta fare tuşu için event handler'lar
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: (final event) {
          setState(() {
            _isMiddleMousePressed = false;
          });
        },
        child: Stack(
          children: [
            // Ana içerik
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
                scrollbars: false,
              ),
              child: SingleChildScrollView(
                controller: widget.scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Hero Section
                    Container(key: _homeKey, child: const HeroVideoSection()),

                    const SizedBox(height: 40),

                    // Quote Section with parallax effect
                    _buildQuoteSection(),

                    // Shows Section
                    Container(
                        key: widget.showsKey, child: const ShowsSection()),

                    // Metafor Landing
                    Container(
                        key: widget.artisticKey, child: const MetaforLanding()),

                    const SizedBox(height: 40),

                    // Kurtar Beni Doktor
                    const KurtarBeniDoktorLanding(),

                    const SizedBox(height: 40),

                    // Göz Kap Vaz Yap
                    const GozYapVazYapLanding(),

                    // About Section
                    Container(
                        key: widget.aboutKey,
                        child: AboutCard(
                            mainScrollController: widget.scrollController)),
                    // Team Section
                    Container(key: widget.teamKey, child: const TeamCard()),

                    // Contact Section
                    Container(
                        key: widget.contactKey, child: const ContactCard()),

                    // Footer spacing
                    const SizedBox(height: 60),
                    const ArtFooter(),
                  ],
                ),
              ),
            ),

            // Orta fare tuşu scroll göstergesi
            if (_isMiddleMousePressed)
              Positioned(
                // HATA DÜZELTME: Positioned widget'ının kullanacağı değişkenler artık tanımlı
                left: _middleMouseStartPosition.dx - 20,
                top: _middleMouseStartPosition.dy - 20,
                child: IgnorePointer(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: WebColors.primaryGold.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: WebColors.primaryGold,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.open_with,
                      color: WebColors.primaryGold,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteSection() {
    return AnimatedBuilder(
      animation: widget.scrollController,
      builder: (final context, final child) {
        // Parallax effect için scroll pozisyonuna göre opacity hesapla
        final scrollPosition = widget.scrollController.hasClients
            ? widget.scrollController.offset
            : 0.0;
        final opacity = (1 - (scrollPosition / 800)).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
            decoration: const BoxDecoration(
              gradient: WebColors.backgroundGradient,
            ),
            child: Text(
              '"Hikayelerimizle kalplere dokunuyor,\nsanatla hayata anlam katıyoruz"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: WebColors.whiteText.withOpacity(0.9),
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ),
        );
      },
    );
  }
}
