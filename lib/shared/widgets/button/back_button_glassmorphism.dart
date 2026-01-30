import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/common/extentions/app_context_ui_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../navigation/widgets/nav_handler.dart';

/// 🎨 Glassmorphism Back Button Widget
/// Buzlu cam efektli, modern geri butonu
class GlassmorphismBackButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool showBorder;

  const GlassmorphismBackButton({
    super.key,
    this.onPressed,
    this.size = 48,
    this.backgroundColor,
    this.iconColor,
    this.showBorder = true,
  });

  @override
  State<GlassmorphismBackButton> createState() =>
      _GlassmorphismBackButtonState();
}

class _GlassmorphismBackButtonState extends State<GlassmorphismBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(final TapDownDetails details) => _controller.forward();

  void _handleTapUp(final TapUpDetails details) => _controller.reverse();

  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(final BuildContext context) {
    final bool isDark = context.isDarkMode;

    // 🎨 Light temada ikon ve borderlar için antrasit/siyah, Dark temada beyaz
    final Color baseColor =
        isDark ? AppDarkColors.onSurface : AppLightColors.textPrimary;

    // 🍷 Light temada cam efekti senin kırmızı (primary) tonundan, Dark'ta gri tondan beslensin
    final Color glassColor =
        isDark ? AppDarkColors.secondary : AppLightColors.primary;

    return MouseRegion(
      onEnter: (final _) => setState(() => _isHovered = true),
      onExit: (final _) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: () {
          // Custom callback varsa onu çalıştır, yoksa NavigationHandler kullan
          if (widget.onPressed != null)
            widget.onPressed!();
          else
            NavigationHandler.smartGoBack(context);
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.size / 4),
              border: widget.showBorder
                  ? Border.all(color: baseColor.withOpacity(0.2), width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.size / 4),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (widget.backgroundColor ?? glassColor)
                            .withOpacity(_isHovered ? 0.25 : 0.15),
                        (widget.backgroundColor ?? glassColor)
                            .withOpacity(_isHovered ? 0.15 : 0.05),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: widget.iconColor ?? baseColor,
                      size: widget.size * 0.5,
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
}

/// 🎨 Glassmorphism Icon Button (Genel Amaçlı)
/// Herhangi bir icon için kullanılabilir
class GlassmorphismIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool showBorder;

  const GlassmorphismIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 48,
    this.backgroundColor,
    this.iconColor,
    this.showBorder = true,
  });

  @override
  State<GlassmorphismIconButton> createState() =>
      _GlassmorphismIconButtonState();
}

class _GlassmorphismIconButtonState extends State<GlassmorphismIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final bool isDark = context.isDarkMode;

    // 🎨 Light temada ikon ve borderlar için antrasit/siyah, Dark temada beyaz
    final Color baseColor =
        isDark ? AppDarkColors.onSurface : AppLightColors.textPrimary;

    // 🍷 Light temada cam efekti senin kırmızı (primary) tonundan, Dark'ta gri tondan beslensin
    final Color glassColor =
        isDark ? AppDarkColors.secondary : AppLightColors.primary;

    return MouseRegion(
      onEnter: (final _) => setState(() => _isHovered = true),
      onExit: (final _) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (final _) => _controller.forward(),
        onTapUp: (final _) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onPressed,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.size / 4),
              border: widget.showBorder
                  ? Border.all(color: baseColor.withOpacity(0.2), width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.size / 4),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (widget.backgroundColor ?? glassColor)
                            .withOpacity(_isHovered ? 0.25 : 0.15),
                        (widget.backgroundColor ?? glassColor)
                            .withOpacity(_isHovered ? 0.15 : 0.05),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: widget.iconColor ?? baseColor,
                      size: widget.size * 0.5,
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
}

/// 🎨 Glassmorphism App Bar (Tam Ekran Header)
/// Scroll'da görünen sticky header için
class GlassmorphismAppBar extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const GlassmorphismAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.surface.withOpacity(0.95),
                  colors.surface.withOpacity(0.85),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Leading / Back Button
                    if (showBackButton)
                      GlassmorphismBackButton(
                          onPressed: onBackPressed,
                          backgroundColor: colors.primary)
                    else if (leading != null)
                      leading!,

                    const SizedBox(width: 16),

                    // Title & Subtitle
                    if (title != null)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.secondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: colors.secondaryContainer),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      const Spacer(),

                    // Actions
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
