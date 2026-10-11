import 'package:flutter/material.dart';
import 'package:ticketapp/shared/widgets/gallery_section.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/section_header.dart';

class ShowPhotoGallery extends StatelessWidget {
  final List<String> photos;

  const ShowPhotoGallery({super.key, required this.photos});

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
              padding: EdgeInsets.fromLTRB(20, 30, 20, 15),
              child: SectionHeader(title: 'OYUNDAN KARELER', fontSize: 20)),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: photos.length,
              itemBuilder: (final context, final index) => GestureDetector(
                onTap: () => GalleryViewerDialog.open(
                  context,
                  photos,
                  initialIndex: index,
                ),
                child: Container(
                  width: 260,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: OptimizedCachedImage(
                      imageUrl: photos[index],
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
