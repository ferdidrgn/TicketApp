import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ticket/stage_moments.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';

/// Yönlendirme mantığı (go_router) içermeyen, sadece görsel Splash tasarımı.
/// Bu widget'ı veri yüklenirken "Loading Indicator" yerine kullanacağız.
///
/// TEK AN (bilet dili): giriş ekranındaki gibi karanlık sahnede fiziksel bir
/// bilet uzatılır → "TİYATROL" markası soldan sağa açılır → koçana "GİRİŞ"
/// damgası basılır (bilet kontrolden geçti). Toplam ~1.2 sn — eskisinden
/// (1.4 sn giriş + sürekli nabız) kısa; nabız yok, canlılığı koçandaki ince
/// yükleme çizgisi veriyor. Azaltılmış harekette her şey son hâlinde başlar.
///
/// Bilet koçanındaki TARİH/SAAT gerçek (şu an), DURUM satırı
/// `loadingMessage`'dır.
class SplashPage extends StatefulWidget {
  final String? loadingMessage;

  const SplashPage({super.key, this.loadingMessage});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _moment = AnimationController(
      vsync: this, duration: AppMotion.normal + AppMotion.slow);

  late final Animation<double> _ticketIn = CurvedAnimation(
      parent: _moment,
      curve: const Interval(0.0, 0.45, curve: AppMotion.standard));
  late final Animation<double> _brand = CurvedAnimation(
      parent: _moment,
      curve: const Interval(0.25, 0.7, curve: AppMotion.dramatic));
  late final Animation<double> _stamp = CurvedAnimation(
      parent: _moment, curve: const Interval(0.78, 1.0, curve: Curves.easeIn));

  // Açılış anı sabit; saniye ilerlerken yeniden çizilmesine gerek yok.
  final DateTime _openedAt = DateTime.now();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _moment.value = 1;
    } else {
      _moment.forward();
    }
  }

  @override
  void dispose() {
    _moment.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    // Telefonda koçan altta (dikey bilet), tablet/web'de sağda (yatay bilet).
    final bool wide = width >= 768;
    final String status = widget.loadingMessage ?? 'Sahne hazırlanıyor…';

    final Widget ticket = AdmitTicket(
      direction: wide ? Axis.horizontal : Axis.vertical,
      stubExtent: 200,
      body: _SplashTicketBody(brandReveal: _brand, stamp: _stamp, wide: wide),
      stub: _SplashTicketStub(openedAt: _openedAt, status: status),
    );

    return Scaffold(
      backgroundColor: WebColors.darkBlueBackground,
      body: TicketStage(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              // Gerçek bir bilet boyutu; ekran daha darsa ona uyar.
              child: SizedBox(
                width: wide ? 560 : 320,
                child: AnimatedBuilder(
                  animation: _ticketIn,
                  builder: (final context, final child) => Opacity(
                    opacity: _ticketIn.value,
                    child: Transform.translate(
                      // Bilet gişe camının altından uzatılıyormuş gibi.
                      offset: Offset(0, (1 - _ticketIn.value) * 40),
                      child: child,
                    ),
                  ),
                  child: Semantics(
                    label: 'TiyatRol. $status',
                    liveRegion: true,
                    child: ticket,
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

class _SplashTicketBody extends StatelessWidget {
  final Animation<double> brandReveal;
  final Animation<double> stamp;
  final bool wide;

  const _SplashTicketBody({
    required this.brandReveal,
    required this.stamp,
    required this.wide,
  });

  @override
  Widget build(final BuildContext context) {
    final double icon = wide ? 80 : 72;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Uygulama ikonu — düz, eşit köşeli (eski asimetrik "D harfi"
              // çerçeve kaldırıldı).
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.asset(
                  'assets/images/app_icon_master.png',
                  width: icon,
                  height: icon,
                  // 2000px kaynak; ekrandaki boyutta çözülür.
                  cacheWidth: 240,
                  fit: BoxFit.cover,
                  errorBuilder: (final context, final error, final stack) =>
                      SizedBox(
                    width: icon,
                    height: icon,
                    child: Icon(Icons.theater_comedy_rounded,
                        size: 48, color: TicketInk.accentOf(context)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthWipeReveal(
                reveal: brandReveal,
                child: Text(
                  'TİYATROL',
                  maxLines: 1,
                  style: GoogleFonts.playfairDisplay(
                    color: TicketInk.ink,
                    fontSize: wide ? 40 : 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Oyunu bul, seansını seç, biletini al.',
                style: TextStyle(
                  color: TicketInk.inkSoft(0.72),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        // Bilet kontrolden geçti: ikonun yanındaki boşluğa damga basılır.
        Positioned(
          top: AppSpacing.xxl + AppSpacing.sm,
          right: AppSpacing.xl,
          child: TicketInkStamp(text: 'GİRİŞ', appear: stamp),
        ),
      ],
    );
  }
}

class _SplashTicketStub extends StatelessWidget {
  final DateTime openedAt;
  final String status;

  const _SplashTicketStub({required this.openedAt, required this.status});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child:
                      TicketField(label: 'TARİH', value: ticketDate(openedAt)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child:
                      TicketField(label: 'SAAT', value: ticketTime(openedAt)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('DURUM', style: TicketInk.label()),
            const SizedBox(height: 3),
            Text(
              status,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TicketInk.value(size: 13),
            ),
            const SizedBox(height: AppSpacing.md),
            // Üç gong: Türk tiyatrosunda perde üç gongla açılır.
            ThreeGongIndicator(color: TicketInk.accentOf(context)),
          ],
        ),
      );
}
