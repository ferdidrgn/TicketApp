import 'package:flutter/material.dart';

class NearbyEventsPage extends StatefulWidget {
  const NearbyEventsPage({super.key});

  @override
  _NearbyEventsPageState createState() => _NearbyEventsPageState();
}

class _NearbyEventsPageState extends State<NearbyEventsPage> {
  // Filtreleme seçenekleri
  final List<String> _categories = [
    'Müzikal',
    'Tiyatro',
    'Sinema',
    'Dans',
    'Opera',
    'Bale'
  ];
  List<String> _selectedCategories = [];
  RangeValues _priceRange = RangeValues(0, 1000);

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtreler'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kategoriler:'),
                ..._categories
                    .map((category) => CheckboxListTile(
                          title: Text(category),
                          value: _selectedCategories.contains(category),
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                          },
                        ))
                    .toList(),
                const SizedBox(height: 20),
                const Text('Fiyat Aralığı:'),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 1000,
                  divisions: 10,
                  labels: RangeLabels(
                    '${_priceRange.start.round()}₺',
                    '${_priceRange.end.round()}₺',
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _priceRange = values;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Uygula'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakınımdaki Etkinlikler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Etkinlikler başlığı
            const Text(
              'Yakınınızdaki Etkinlikler',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Etkinlikler listesi (Örnek veri)
            Expanded(
              child: ListView(
                children: [
                  _buildEventCard('Müzikal Etkinlik 1', '12 Eylül 2024', 150.0),
                  _buildEventCard('Tiyatro Etkinlik 2', '15 Eylül 2024', 100.0),
                  _buildEventCard('Sinema Etkinlik 3', '20 Eylül 2024', 80.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(String title, String date, double price) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      child: ListTile(
        title: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(date),
        trailing: Text('$price₺'),
      ),
    );
  }
}
