import 'package:flutter/material.dart';

class CustomArtWordsCard extends StatelessWidget {
  final String word;
  final String author;

  const CustomArtWordsCard({
    super.key,
    required this.word,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            word,
            style: const TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            author,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
