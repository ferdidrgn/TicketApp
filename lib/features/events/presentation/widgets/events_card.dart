import 'dart:ui'; // Glassmorphism için gerekli
import 'package:flutter/material.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';

class EventsCard extends StatelessWidget {
  final String imageUrl;
  final String showName;
  final String category;
  final String fullDateString; // Örn: "15 Eyl"
  final String timeString; // Örn: "20:30"
  final String stage;
  final double price;
  final VoidCallback? onTap;
  final double? width;
  final EdgeInsetsGeometry? margin;

  const EventsCard({
    super.key,
    required this.imageUrl,
    required this.showName,
    required this.category,
    required this.fullDateString,
    required this.timeString,
    required this.stage,
    required this.price,
    this.onTap,
    this.width,
    this.margin,
  });

  @override
  Widget build(final BuildContext context) {
    // Tema renklerini çekelim (Material 3 uyumlu)
    final colors = context.colors;

    return Container(
      width: width ?? 280,
      margin: margin ?? const EdgeInsets.only(right: 20, bottom: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainer, // M3 Surface rengi
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              // Derinlik veren yumuşak gölge
              BoxShadow(
                color: colors.shadow.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼️ 1. GÖRSEL ALANI (Parallax Etkisi İçin Hazırlık)
              Stack(
                children: [
                  // Ana Resim
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    child: Container(
                      height: 200, // Daha yüksek, daha etkileyici
                      width: double.infinity,
                      foregroundDecoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.2), // Hafif karartma
                            Colors.black.withOpacity(0.8), // Alt kısım koyu
                          ],
                          stops: const [0.5, 0.7, 1.0],
                        ),
                      ),
                      child: OptimizedCachedImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // ✨ Kategori Rozeti (Glassmorphism)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.8),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: context.textTheme.labelSmall?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ⏰ Tarih Kartı (Sağ Üst - Takvim Yaprağı Şeklinde)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.surfaceBright,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            fullDateString.split(' ')[0], // Gün (15)
                            style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: colors.primary,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            fullDateString.split(' ').length > 1
                                ? fullDateString
                                    .split(' ')[1]
                                    .substring(0, 3)
                                    .toUpperCase()
                                : "", // Ay (EYL)
                            style: context.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 🏷️ Fiyat Etiketi (Resmin Sağ Alt Köşesi)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.tertiaryContainer,
                        // Dikkat çekici 3. renk
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.confirmation_number_outlined,
                              size: 14, color: colors.onTertiaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            '₺${price.toStringAsFixed(0)}',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 📝 2. BİLGİ ALANI
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Text(
                      showName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900, // Ultra Bold
                        height: 1.1,
                        color: colors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sahne ve Saat Bilgisi (İkonlu Satır)
                    Row(
                      children: [
                        // Sahne Bilgisi
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: colors.secondaryContainer
                                      .withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.location_on_rounded,
                                    size: 14, color: colors.primary),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  stage,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Dikey Ayırıcı
                        Container(
                          height: 20,
                          width: 1,
                          color: colors.outlineVariant,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),

                        // Saat Bilgisi
                        Row(
                          children: [
                            Icon(Icons.access_time_filled_rounded,
                                size: 16, color: colors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              timeString,
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.secondary,
                              ),
                            ),
                          ],
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
