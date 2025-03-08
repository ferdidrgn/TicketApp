import 'package:flutter/material.dart';

class CustomDescriptionCard extends StatefulWidget {
  final String description;

  const CustomDescriptionCard({super.key, required this.description});

  @override
  _CustomDescriptionCardState createState() => _CustomDescriptionCardState();
}

class _CustomDescriptionCardState extends State<CustomDescriptionCard> {
  bool isExpanded = false;

  @override
  Widget build(final BuildContext context) {
    String? displayDescription = widget.description.replaceAll('\\n', '\n');

    // Eğer açıklama uzunsa, kısalt
    if (!isExpanded && displayDescription.length > 100) {
      displayDescription = '${displayDescription.substring(0, 100)}...';
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayDescription,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(isExpanded ? 'Daralt' : 'Daha Fazlasını Göster'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
