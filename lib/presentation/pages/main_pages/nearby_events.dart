import 'package:flutter/material.dart';
import '../../../core/custom_views/custom_event_card.dart';

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
      builder: (final BuildContext context) {
        return AlertDialog(
          title: const Text('Filtreler'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kategoriler:'),
                ..._categories.map((final category) => CheckboxListTile(
                      title: Text(category),
                      value: _selectedCategories.contains(category),
                      onChanged: (final bool? checked) {
                        setState(() {
                          if (checked != null && checked == true) {
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
                  onChanged: (final RangeValues values) {
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
  Widget build(final BuildContext context) {
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
                children: const [
                  EventCard(
                    imageUrl:
                        'https://www.cumhuriyet.com.tr/Archive/2021/8/27/1863857/kapak_002553.jpg',
                    showName: 'Cimri',
                    category: 'Müzikal',
                    date: '12 Eylül 2024',
                    stage: 'Harbiye',
                    price: 150.0,
                  ),
                  SizedBox(height: 16),
                  EventCard(
                    imageUrl:
                        'https://versustiyatro.com/wp-content/uploads/2016/02/GHT_36101.jpg',
                    showName: 'Hamlet',
                    category: 'Tiyatro',
                    date: '15 Eylül 2024',
                    stage: 'Zoru',
                    price: 100.0,
                  ),
                  SizedBox(height: 16),
                  EventCard(
                    imageUrl:
                        'https://tiyatronline.com/isDosyalar/2019/05/20/crop_gozlerimi-kaparim-vazifemi-yaparim-ank_ilf4LaFHkp.jpg',
                    showName: 'Gözlerimi Kaparım Vazifemi Yaparım',
                    category: 'Sinema',
                    date: '20 Eylül 2024',
                    stage: 'Göztepe',
                    price: 80.0,
                  ),
                  SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
