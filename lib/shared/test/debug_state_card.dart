import 'package:flutter/material.dart';

class DebugStateCard extends StatelessWidget {
  final String title;
  final Object? value; // Herhangi bir nesneyi alabilir (State, String, int)

  const DebugStateCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(final BuildContext context) {
    // Sadece debug modda görünür, release'de boş döner.
    assert(() {
      return true;
    }());

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const Divider(color: Colors.white24),
          Text(
            value.toString(), // Nesnenin toString() metodunu otomatik çağırır
            style: const TextStyle(
                color: Colors.greenAccent,
                fontFamily: 'monospace',
                fontSize: 11),
          ),
        ],
      ),
    );
  }
}
