import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // GoRouter ekledik
import '../../../core/theme/theme_context_extension.dart';

/// Cam Efektli Geri Butonu
class GlassBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const GlassBackButton({super.key, this.onTap});

  @override
  Widget build(final BuildContext context) {
    final textColor = context.isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 5), // Sol padding eklendi
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.isDarkMode ? Colors.white24 : Colors.black12,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 18, color: textColor),
              // GlassBackButton içindeki onPressed kısmını bu şekilde güncelle:
              onPressed: onTap ??
                  () {
                    // 1. Navigator'da geri gidilecek bir sayfa var mı? (Geleneksel Push/Pop)
                    if (Navigator.of(context).canPop())
                      Navigator.pop(context);
                    // 2. GoRouter stack'inde gidilecek bir yer var mı?
                    else if (GoRouter.of(context).canPop())
                      context.pop();
                    // 3. Hiçbir yer yoksa (Siyah ekran riski), güvenli liman: Anasayfa
                    else
                      context.go('/');
                  },
            ),
          ),
        ),
      ),
    );
  }
}
