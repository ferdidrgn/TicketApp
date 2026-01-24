import 'package:flutter/material.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';

class EventsCard extends StatelessWidget {
  final String imageUrl;
  final String showName;
  final String category;
  final String date;
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
    required this.date,
    required this.stage,
    required this.price,
    this.onTap,
    this.width,
    this.margin,
  });

  @override
  Widget build(final BuildContext context) => Container(
        width: width ?? 280,
        margin: margin ?? const EdgeInsets.only(right: 15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Card(
            elevation: 4,
            color: context.colors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: context.isDarkMode
                    ? const BorderSide(color: Colors.white10, width: 0.5)
                    : BorderSide.none),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    // --- RESİM ---
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: OptimizedCachedImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover),
                    ),

                    // --- KATEGORİ ETİKETİ ---
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: context.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: context.primaryColor.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]),
                        child: Text(
                          category.toUpperCase(),
                          style: context.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    // --- İSİM ---
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
                          style: context.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              const Shadow(color: Colors.black, blurRadius: 4)
                            ],
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
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: context.primaryColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              stage,
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(
                          color: context.isDarkMode
                              ? Colors.white12
                              : Colors.black12,
                          height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                date,
                                style: context.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                          Text(
                            '₺${price.toStringAsFixed(0)}',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.primaryColor,
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
