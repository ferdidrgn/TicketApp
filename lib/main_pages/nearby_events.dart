import 'package:flutter/material.dart';

class NearbyEventsPage extends StatefulWidget {
  const NearbyEventsPage({super.key});

  @override
  _NearbyEventsPageState createState() => _NearbyEventsPageState();
}

class _NearbyEventsPageState extends State<NearbyEventsPage> {
  final List<String> _categories = [
    'Müzikal',
    'Tiyatro',
    'Sinema',
    'Dans',
    'Opera',
    'Bale'
  ];
  final List<String> _selectedCategories = [];
  RangeValues _priceRange = const RangeValues(0, 1000);

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
                )),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Yakınınızdaki Etkinlikler',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildEventCard(
                    imageUrl: 'https://www.cumhuriyet.com.tr/Archive/2021/8/27/1863857/kapak_002553.jpg',
                    title: 'Müzikal',
                    date: '12 Eylül 2024',
                    location: 'İstanbul',
                    price: 150.0,
                  ),
                  const SizedBox(height: 16),
                  _buildEventCard(
                    imageUrl: 'https://versustiyatro.com/wp-content/uploads/2016/02/GHT_36101.jpg',
                    title: 'Tiyatro',
                    date: '15 Eylül 2024',
                    location: 'Ankara',
                    price: 100.0,
                  ),
                  const SizedBox(height: 16),
                  _buildEventCard(
                    imageUrl: 'https://tiyatronline.com/isDosyalar/2019/05/20/crop_gozlerimi-kaparim-vazifemi-yaparim-ank_ilf4LaFHkp.jpg',
                    title: 'Sinema',
                    date: '20 Eylül 2024',
                    location: 'İzmir',
                    price: 80.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard({
    required String imageUrl,
    required String title,
    required String date,
    required String location,
    required double price,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              height: 120,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tarih: $date',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fiyat: $price₺',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
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