import 'package:flutter/material.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';

class EventsCard extends StatelessWidget {
  final String imageUrl;
  final String showName;
  final String category;
  final String fullDateString; // Örn: "15 Eylül Pazar"
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
    return Container(
      width: width ?? 260,
      margin: margin ?? const EdgeInsets.only(right: 16, bottom: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼️ RESİM VE TARİH ROZETİ
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24), bottom: Radius.circular(0)),
                    child: OptimizedCachedImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Kategori Etiketi (Sağ Üst)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
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
                  // Tarih Rozeti (Sol Üst)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            timeString, // Saat
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: context.primaryColor,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            height: 2,
                            width: 20,
                            color: Colors.grey.shade200,
                          ),
                          const Icon(Icons.access_time_rounded,
                              size: 12, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 📝 İÇERİK
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Text(
                      showName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Sahne Bilgisi
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 16, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            stage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Kesikli Çizgi (Bilet Havası)
                    Row(
                      children: List.generate(
                          15,
                          (final index) => Expanded(
                                child: Container(
                                  color: index % 2 == 0
                                      ? Colors.transparent
                                      : Colors.grey.shade300,
                                  height: 1,
                                ),
                              )),
                    ),
                    const SizedBox(height: 12),

                    // Alt Kısım: Tarih ve Fiyat Butonu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tam Tarih Yazısı
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded,
                                  size: 16, color: context.primaryColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  fullDateString,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Fiyat Hapı
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '₺${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: context.primaryColor,
                            ),
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
