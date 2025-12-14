import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart'; // ✅ Senin renk dosyan

class ShowInfoSection extends StatefulWidget {
  final String title;
  final String description;
  final String duration;
  final String rating;

  const ShowInfoSection({
    super.key,
    required this.title,
    required this.description,
    this.duration = "120 Dk",
    this.rating = "4.8",
  });

  @override
  State<ShowInfoSection> createState() => _ShowInfoSectionState();
}

class _ShowInfoSectionState extends State<ShowInfoSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🔥 KRİTİK DÜZELTME:
    // Marka rengini (Kırmızı) her iki modda da sabit tutuyoruz.
    // Dark modda grileşmemesi için AppLightColors.primary kullanıyoruz.
    const brandRed = AppLightColors.primary;

    // Metin Rengi: Dark ise Beyaz, Light ise Siyah
    final textColor =
        isDark ? AppDarkColors.textPrimary : AppLightColors.textPrimary;
    final cleanDesc = widget.description.replaceAll('\\n', '\n');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KATEGORİ ETİKETİ (TİYATRO)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              // Dark modda çok patlamaması için hafif şeffaflık verebiliriz ama kırmızı kalmalı
              color: brandRed.withOpacity(isDark ? 0.2 : 1.0),
              borderRadius: BorderRadius.circular(20),
              border: isDark ? Border.all(color: brandRed) : null,
              // Dark'ta kırmızı çerçeve
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: brandRed.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Text(
              "TİYATRO",
              style: TextStyle(
                  // Dark modda zemin şeffaf olduğu için yazı kırmızı olsun, Light'ta zemin dolu olduğu için yazı beyaz.
                  color: isDark ? brandRed : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 15),

          // BAŞLIK
          Text(
            widget.title,
            style: TextStyle(
              color: textColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          // İSTATİSTİKLER
          Row(
            children: [
              const Icon(Icons.star, color: brandRed, size: 20),
              // ⭐ Yıldız Kırmızı
              const SizedBox(width: 5),
              Text(
                "${widget.rating} (120 İnceleme)",
                style:
                    TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(width: 20),
              Icon(Icons.timer, color: textColor.withOpacity(0.5), size: 18),
              const SizedBox(width: 5),
              Text(
                widget.duration,
                style:
                    TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 25),

          // AÇIKLAMA VE BUTON
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleanDesc,
                  maxLines: _isExpanded ? null : 4,
                  overflow: _isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 16,
                    height: 1.6,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 10),

                // "DAHA FAZLA GÖSTER" BUTONU
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isExpanded
                              ? "Daha Az Göster"
                              : "Daha Fazlasını Göster",
                          style: const TextStyle(
                            color: brandRed, // ✅ Yazı Rengi Kırmızı
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: brandRed, // ✅ Ok Rengi Kırmızı
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
