import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart'; // ✅ Renk dosyan
import 'package:ticketapp/shared/widgets/shimmer.dart'; // Shimmer widget'ın

class EventsCard extends StatelessWidget {
  final String imageUrl;
  final String showName;
  final String category;
  final String date;
  final String stage;
  final double price;
  final VoidCallback? onTap;

  const EventsCard({
    super.key,
    required this.imageUrl,
    required this.showName,
    required this.category,
    required this.date,
    required this.stage,
    required this.price,
    this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    // 🎨 TEMA VE RENKLER
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Marka Rengi (Kırmızı)
    const brandRed = AppLightColors.primary;

    // Kart Rengi: Dark ise senin Surface rengin, Light ise Beyaz
    final cardColor = isDark ? AppDarkColors.surface : Colors.white;

    // Yazı Renkleri
    final titleColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.grey[700];

    // Tarih Kutusu Rengi
    final dateBoxColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100];

    return Container(
      width: 280, // Kart genişliği
      margin: const EdgeInsets.only(right: 15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Card(
          elevation: 4,
          color: cardColor, // ✅ Temaya uygun arka plan
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            // Dark modda ince beyaz çerçeve, Light modda çerçeve yok
            side: isDark
                ? const BorderSide(color: Colors.white10, width: 0.5)
                : BorderSide.none,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // --- RESİM ---
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      placeholder: (final context, final url) => const ShimmerLoading(
                          width: double.infinity, height: 150),
                      errorWidget: (final context, final url, final error) => Container(
                        height: 150,
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                        child:
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),

                  // --- KATEGORİ ETİKETİ (Sağ Üst) ---
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: brandRed, // ✅ Kırmızı Etiket
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: brandRed.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]),
                      child: Text(
                        category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // --- İSİM (Gradient Üzeri) ---
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.9),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        showName,
                        style: const TextStyle(
                          color: Colors.white, // Resim üstü her zaman beyaz
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),

              // --- DETAYLAR ---
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // Sahne Bilgisi
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: brandRed),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            stage,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: titleColor, // Temaya göre değişir
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Divider(
                        color: isDark ? Colors.white12 : Colors.black12,
                        height: 1),
                    const SizedBox(height: 8),

                    // Tarih ve Fiyat
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tarih
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: subTextColor),
                            const SizedBox(width: 4),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 12,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),

                        // Fiyat
                        Text(
                          '₺${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: brandRed, // ✅ Fiyat Kırmızı
                          ),
                        ),
                      ],
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
