import 'package:flutter/material.dart';
import 'package:ticketapp/core/util/shimmer.dart';

class EventCard extends StatelessWidget {
  final String imageUrl;
  final String showName;
  final String category;
  final String date;
  final String stage;
  final double price;

  const EventCard({
    super.key,
    required this.imageUrl,
    required this.showName,
    required this.category,
    required this.date,
    required this.stage,
    required this.price,
  });

  @override
  Widget build(final BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  loadingBuilder: (final context, final child, final loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const ShimmerLoading();
                  },
                  errorBuilder: (final context, final error, final stackTrace) {
                    return const Center(child: Icon(Icons.error));
                  },
                ),
              ),
              // Show name overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.black.withOpacity(0.7),
                  child: Text(
                    showName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Category label
              Positioned(
                bottom: 28,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          // Event details
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Stage (bottom-left)
                Expanded(
                  child: Text(
                    stage,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                  ),
                ),
                // Price (bottom-center)
                Expanded(
                  child: Text(
                    '₺${price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                // Date (bottom-right)
                Expanded(
                  child: Text(
                    date,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
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
