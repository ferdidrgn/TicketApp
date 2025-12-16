import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/theme_context_extension.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double scrollOffset;
  final String title;

  const GlassAppBar({
    super.key,
    required this.scrollOffset,
    this.title = "TicketApp",
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final opacity = (scrollOffset / 100).clamp(0.0, 0.85);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: scrollOffset > 50 ? 12 : 0,
            sigmaY: scrollOffset > 50 ? 12 : 0,
          ),
          child: Container(
            color: context.scaffoldBackgroundColor.withOpacity(opacity),
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(
              bottom: 15,
              left: 20,
              right: 20,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
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