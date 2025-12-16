import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../core/theme/theme_context_extension.dart';

/// Sanat eseri gibi tasarlanmış search bar
/// Hero section'ın hemen altına yerleştirilebilir
class ArtisticSearchBar extends StatefulWidget {
  final VoidCallback onTap;
  final String hintText;

  const ArtisticSearchBar({
    super.key,
    required this.onTap,
    this.hintText = "Tiyatro, konser, sanatçı ara...",
  });

  @override
  State<ArtisticSearchBar> createState() => _ArtisticSearchBarState();
}

class _ArtisticSearchBarState extends State<ArtisticSearchBar>
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

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (final context, final child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    // Dış glow efekti
                    BoxShadow(
                      color: context.primaryColor
                          .withOpacity(_glowAnimation.value * 0.4),
                      blurRadius: 25,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    // Depth shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(32),
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
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                // Search icon with glow
                                Container(
                                  width: 40,
                                  height: 40,
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
                                    color: context.primaryColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                // Text
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      widget.hintText,
                                      style: TextStyle(
                                        fontSize: 15,
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

/// Minimalist floating search - AppBar'ın altına sticky olarak yerleştirilebilir
class FloatingSearchPill extends StatelessWidget {
  final VoidCallback onTap;

  const FloatingSearchPill({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              colors: [
                context.primaryColor.withOpacity(0.15),
                context.primaryColor.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: context.primaryColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: context.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Keşfet...",
                      style: TextStyle(
                        color: context.isDarkMode
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.6),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "⌘K",
                        style: TextStyle(
                          color: context.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
  }
}

/// Brutalist style search - Cesur ve farklı
class BrutalistSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const BrutalistSearchBar({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: context.primaryColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPatternPainter(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ARAMA YAP",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Etkinlik, mekan, sanatçı...",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neon style search - Gece kulübü havası
class NeonSearchBar extends StatefulWidget {
  final VoidCallback onTap;

  const NeonSearchBar({
    super.key,
    required this.onTap,
  });

  @override
  State<NeonSearchBar> createState() => _NeonSearchBarState();
}

class _NeonSearchBarState extends State<NeonSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (final context, final child) {
          return GestureDetector(
            onTap: widget.onTap,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: context.primaryColor.withOpacity(0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.primaryColor.withOpacity(0.6),
                    blurRadius: 20 + (_controller.value * 10),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: context.primaryColor.withOpacity(0.3),
                    blurRadius: 40 + (_controller.value * 20),
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            context.primaryColor,
                            context.primaryColor.withOpacity(0.5),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.primaryColor.withOpacity(0.8),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Sanat dünyasını keşfet...",
                        style: TextStyle(
                          color: context.primaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: context.primaryColor.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Icon(
                      Icons.auto_awesome,
                      color: context.primaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Minimal Elegant - En şık ve sade
class MinimalElegantSearch extends StatelessWidget {
  final VoidCallback onTap;

  const MinimalElegantSearch({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: context.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: context.isDarkMode
                      ? Colors.white.withOpacity(0.4)
                      : Colors.black.withOpacity(0.4),
                  size: 22,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "Ara...",
                    style: TextStyle(
                      color: context.isDarkMode
                          ? Colors.white.withOpacity(0.4)
                          : Colors.black.withOpacity(0.4),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: context.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                ),
                const SizedBox(width: 12),
                Text(
                  "⌘K",
                  style: TextStyle(
                    color: context.isDarkMode
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.3),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Grid pattern painter for brutalist style
class _GridPatternPainter extends CustomPainter {
  final Color color;

  _GridPatternPainter({required this.color});

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 20.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) => false;
}
