import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';

class ShowInfoSection extends StatefulWidget {
  final String title;
  final String description;

  const ShowInfoSection({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  State<ShowInfoSection> createState() => _ShowInfoSectionState();
}

class _ShowInfoSectionState extends State<ShowInfoSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(final BuildContext context) {
    final cleanDesc = widget.description.replaceAll('\\n', '\n');

    final isDark = context.isDarkMode;

    // Metin rengi
    final textColor = isDark ? Colors.white : Colors.black;

    // Sabit marka rengi
    const brandColor = AppLightColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? brandColor.withOpacity(0.1) : brandColor,
              border:
                  isDark ? Border.all(color: brandColor) : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "TİYATRO",
              style: TextStyle(
                color: isDark ? brandColor : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            widget.title,
            style: TextStyle(
              color: textColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.star, color: brandColor, size: 20),
              const SizedBox(width: 5),
              Text(
                "4.8 (120 İnceleme)",
                style: TextStyle(
                    color: textColor.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(width: 20),
              Icon(Icons.timer,
                  color: textColor.withOpacity(0.5), size: 18),
              const SizedBox(width: 5),
              Text(
                "120 Dk",
                style: TextStyle(
                    color: textColor.withOpacity(0.7), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 25),
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
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isExpanded
                              ? "Daha Az Göster"
                              : "Daha Fazlasını Göster",
                          style: TextStyle(
                            color: brandColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: brandColor,
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
