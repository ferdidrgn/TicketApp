import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/features/stages/domain/entities/stage.dart';

/// Bir kenar çubuğu (sidebar) ile ana içeriği yan yana yerleştiren,
/// kullanıcı sayfayı kaydırırken kenar çubuğunu -- içerik sütununun
/// sınırları içinde kalacak şekilde -- ekranda sabit (CSS `position:
/// sticky` benzeri) tutan editoryal bir düzen yardımcısı.
///
/// [scrollListenable], sayfanın kullandığı `ScrollController` olmalıdır;
/// her kaydırma olayında konum yeniden hesaplanır.
class StickyEditorialSplit extends StatefulWidget {
  final Widget sidebar;
  final Widget content;
  final Listenable scrollListenable;
  final double sidebarWidth;
  final double gap;

  /// Kenar çubuğunun ekranın üstünden ne kadar boşlukla "yapışacağı".
  final double topPin;

  const StickyEditorialSplit({
    super.key,
    required this.sidebar,
    required this.content,
    required this.scrollListenable,
    this.sidebarWidth = 340,
    this.gap = 64,
    this.topPin = 116,
  });

  @override
  State<StickyEditorialSplit> createState() => _StickyEditorialSplitState();
}

class _StickyEditorialSplitState extends State<StickyEditorialSplit> {
  final GlobalKey _wrapperKey = GlobalKey();
  final GlobalKey _sidebarKey = GlobalKey();
  double _top = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollListenable.addListener(_recalculate);
    WidgetsBinding.instance.addPostFrameCallback((final _) => _recalculate());
  }

  @override
  void didUpdateWidget(covariant final StickyEditorialSplit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollListenable != widget.scrollListenable) {
      oldWidget.scrollListenable.removeListener(_recalculate);
      widget.scrollListenable.addListener(_recalculate);
    }
  }

  void _recalculate() {
    if (!mounted) return;
    final wrapperObj = _wrapperKey.currentContext?.findRenderObject();
    final sidebarObj = _sidebarKey.currentContext?.findRenderObject();
    if (wrapperObj is! RenderBox || !wrapperObj.hasSize) return;
    if (sidebarObj is! RenderBox || !sidebarObj.hasSize) return;

    final double wrapperTop = wrapperObj.localToGlobal(Offset.zero).dy;
    final double wrapperHeight = wrapperObj.size.height;
    final double sidebarHeight = sidebarObj.size.height;
    final double maxTop =
        wrapperHeight - sidebarHeight > 0 ? wrapperHeight - sidebarHeight : 0;
    final double proposedTop =
        (widget.topPin - wrapperTop).clamp(0.0, maxTop);

    if ((proposedTop - _top).abs() > 0.5) setState(() => _top = proposedTop);
  }

  @override
  void dispose() {
    widget.scrollListenable.removeListener(_recalculate);
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => Container(
        key: _wrapperKey,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(left: widget.sidebarWidth + widget.gap),
              child: widget.content,
            ),
            Positioned(
              top: _top,
              left: 0,
              width: widget.sidebarWidth,
              child: KeyedSubtree(key: _sidebarKey, child: widget.sidebar),
            ),
          ],
        ),
      );
}

/// Mekan bilgilerini (adres, kapasite, iletişim) gösteren, üzerine
/// gelindiğinde her satırın hafifçe aydınlandığı zarif bir kenar çubuğu
/// kartı.
class StageInfoCard extends StatelessWidget {
  final Stage stage;

  const StageInfoCard({super.key, required this.stage});

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 14)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MEKAN BİLGİLERİ',
              style: TextStyle(
                color: WebColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 22),
            if (stage.address.isNotEmpty)
              _InfoRow(
                icon: Icons.location_on_rounded,
                label: 'Açık Adres',
                value: stage.address,
              ),
            if (stage.capacity.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.event_seat_rounded,
                label: 'Kapasite',
                value: '${stage.capacity} Kişi',
              ),
            ],
            if (stage.communication.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.phone_in_talk_rounded,
                label: 'İletişim',
                value: stage.communication,
              ),
            ],
          ],
        ),
      );
}

class _InfoRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  State<_InfoRow> createState() => _InfoRowState();
}

class _InfoRowState extends State<_InfoRow> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovered
                ? WebColors.primaryGold.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: WebColors.primaryGold.withOpacity(_hovered ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon,
                    color: WebColors.primaryGoldLight, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: WebColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.value,
                      style: const TextStyle(
                          color: WebColors.whiteText, fontSize: 15, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
