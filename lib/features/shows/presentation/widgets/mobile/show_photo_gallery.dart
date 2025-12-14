import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ShowPhotoGallery extends StatelessWidget {
  final List<String> photos;

  const ShowPhotoGallery({super.key, required this.photos});

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bölüm Başlığı
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
            child: Row(
              children: [
                Container(width: 4, height: 24, color: const Color(0xFFD4AF37)),
                const SizedBox(width: 10),
                const Text(
                  "OYUNDAN KARELER",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // Fotoğraf Listesi
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: photos.length,
              itemBuilder: (final context, final index) {
                return GestureDetector(
                  onTap: () => _showFullImage(context, photos[index]),
                  child: Container(
                    width: 260, // Geniş sinematik oran
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CachedNetworkImage(
                        imageUrl: photos[index],
                        fit: BoxFit.cover,
                        placeholder: (final context, final url) => Container(
                          color: const Color(0xFF151525),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFD4AF37),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (final context, final url, final error) =>
                            Container(
                          color: const Color(0xFF151525),
                          child: const Icon(Icons.broken_image,
                              color: Colors.white24),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );

  // Resmi Tam Ekran Açma Fonksiyonu (Kendi İçinde)
  void _showFullImage(final BuildContext context, final String imageUrl) =>
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.95), // Sinema modu
        builder: (final context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Resim (Zoomlanabilir)
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
              ),

              // Kapat Butonu
              Positioned(
                top: 50,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
