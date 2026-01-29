import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/common/extentions/app_context_ui_extension.dart';

/// Sanat eseri gibi tasarlanmış search bar
/// Hem ana sayfada hem AppBar'da kullanılabilir
class CustomSearchbar extends StatefulWidget {
  final VoidCallback onTap;
  final String hintText;
  final bool isCompact;

  const CustomSearchbar({
    super.key,
    required this.onTap,
    this.hintText = "Tiyatro, konser, sanatçı ara...",
    this.isCompact = false,
  });

  @override
  State<CustomSearchbar> createState() => _CustomSearchbarState();
}

class _CustomSearchbarState extends State<CustomSearchbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.isCompact ? 0.99 : 0.98,
      end: widget.isCompact ? 1.01 : 1.02,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
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
    final isDark = context.isDarkMode;
    final height = widget.isCompact ? 48.0 : 65.0;
    final borderRadius = widget.isCompact ? 24.0 : 32.0;
    final horizontalPadding = widget.isCompact ? 16.0 : 20.0;
    final iconSize = widget.isCompact ? 20.0 : 22.0;
    final fontSize = widget.isCompact ? 14.0 : 15.0;
    final blurSigma = widget.isCompact ? 15.0 : 20.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCompact ? 0 : 20,
        vertical: widget.isCompact ? 0 : 15,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (final context, final child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    // Dış glow efekti
                    BoxShadow(
                      color: context.primaryColor
                          .withOpacity(_glowAnimation.value * 0.4),
                      blurRadius: widget.isCompact ? 15 : 25,
                      spreadRadius: widget.isCompact ? 1 : 2,
                      offset: const Offset(0, 4),
                    ),
                    // Depth shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                      blurRadius: widget.isCompact ? 10 : 15,
                      offset: Offset(0, widget.isCompact ? 4 : 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: BackdropFilter(
                    filter:
                        ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.03),
                                ]
                              : [
                                  Colors.white.withOpacity(0.9),
                                  Colors.white.withOpacity(0.7),
                                ],
                        ),
                        border: Border.all(
                          color: context.primaryColor.withOpacity(0.2),
                          width: widget.isCompact ? 1.0 : 1.5,
                        ),
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                      child: Stack(
                        children: [
                          // Animated gradient overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    context.primaryColor.withOpacity(
                                        _glowAnimation.value * 0.1),
                                    Colors.transparent,
                                    context.primaryColor.withOpacity(
                                        _glowAnimation.value * 0.05),
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(borderRadius),
                              ),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding),
                            child: Row(
                              children: [
                                // Search icon with glow
                                Container(
                                  width: widget.isCompact ? 32 : 40,
                                  height: widget.isCompact ? 32 : 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        context.primaryColor.withOpacity(0.2),
                                        context.primaryColor.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: context.colors.primary,
                                    size: iconSize,
                                  ),
                                ),
                                SizedBox(width: widget.isCompact ? 12 : 15),
                                // Text
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      widget.hintText,
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.6)
                                            : Colors.black.withOpacity(0.5),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                                // Decorative element
                                if (!widget.isCompact)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          context.primaryColor.withOpacity(0.6),
                                          context.primaryColor.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
