import 'package:flutter/material.dart';

class ShowInfoSection extends StatefulWidget {
  final String title;
  final String description;
  final String duration; // Örn: "120 Dk"
  final String rating; // Örn: "4.8"

  const ShowInfoSection({
    super.key,
    required this.title,
    required this.description,
    this.duration = "120 Dk", // Varsayılan veya parametre
    this.rating = "4.8", // Varsayılan veya parametre
  });

  @override
  State<ShowInfoSection> createState() => _ShowInfoSectionState();
}

class _ShowInfoSectionState extends State<ShowInfoSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kategori Etiketi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37), // Altın Rengi
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "TİYATRO",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),

            // Başlık
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),

            // İstatistikler (Süre, Puan)
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFD4AF37), size: 20),
                const SizedBox(width: 5),
                Text(
                  "${widget.rating} (120 İnceleme)",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 20),
                const Icon(Icons.timer, color: Colors.white54, size: 18),
                const SizedBox(width: 5),
                Text(
                  widget.duration,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // --- AÇILIR KAPANIR AÇIKLAMA ---
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.description.replaceAll('\\n', '\n'),
                    maxLines: _isExpanded ? null : 4,
                    // Açıkken sınır yok, kapalıyken 4 satır
                    overflow: _isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.6,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Göster / Gizle Butonu
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isExpanded
                              ? "Daha Az Göster"
                              : "Daha Fazlasını Göster",
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: const Color(0xFFD4AF37),
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
