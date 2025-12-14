import 'package:flutter/material.dart';

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
    final primaryColor = theme.primaryColor; // Senin Kırmızın
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cleanDesc = widget.description.replaceAll('\\n', '\n');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategori Etiketi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: const Text(
              "TİYATRO",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 15),

          // Başlık
          Text(
            widget.title,
            style: TextStyle(
              color: textColor,
              // Temaya göre siyah veya beyaz
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          // İstatistikler
          Row(
            children: [
              Icon(Icons.star, color: primaryColor, size: 20),
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

          // Açılır/Kapanır Açıklama
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isExpanded
                            ? "Daha Az Göster"
                            : "Daha Fazlasını Göster",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: primaryColor,
                      ),
                    ],
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
