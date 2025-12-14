import 'package:flutter/material.dart';

import '../../../../shared/widgets/custom_event_card.dart';
import '../../../../shared/widgets/custom_title.dart';

class NearbyEventsPage extends StatefulWidget {
  const NearbyEventsPage({super.key});

  @override
  State<NearbyEventsPage> createState() => _NearbyEventsPageState();
}

class _NearbyEventsPageState extends State<NearbyEventsPage> {
  final categories = ['Müzikal', 'Tiyatro', 'Sinema', 'Dans', 'Opera', 'Bale'];
  final selectedCategories = <String>[];
  RangeValues priceRange = const RangeValues(0, 1000);

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (final _) => AlertDialog(
        title: Text('Filtreler',
            style: Theme.of(context).textTheme.headlineMedium),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kategoriler:',
                  style: Theme.of(context).textTheme.bodyMedium),
              ...categories.map(
                (final cat) => CheckboxListTile(
                  title:
                      Text(cat, style: Theme.of(context).textTheme.bodyMedium),
                  value: selectedCategories.contains(cat),
                  onChanged: (final checked) => setState(() {
                    if (checked == true)
                      selectedCategories.add(cat);
                    else
                      selectedCategories.remove(cat);
                  }),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 20),
              Text('Fiyat Aralığı:',
                  style: Theme.of(context).textTheme.bodyMedium),
              RangeSlider(
                values: priceRange,
                min: 0,
                max: 1000,
                divisions: 10,
                labels: RangeLabels(
                  '${priceRange.start.round()}₺',
                  '${priceRange.end.round()}₺',
                ),
                onChanged: (final v) => setState(() => priceRange = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Uygula', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const CustomSectionTitle(title: 'Yakınınızdaki Etkinlikler'),
            IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog),
          ]),
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
                  price: 150,
                ),
                SizedBox(height: 16),
                EventCard(
                  imageUrl:
                      'https://versustiyatro.com/wp-content/uploads/2016/02/GHT_36101.jpg',
                  showName: 'Hamlet',
                  category: 'Tiyatro',
                  date: '15 Eylül 2024',
                  stage: 'Zoru',
                  price: 100,
                ),
                SizedBox(height: 16),
                EventCard(
                  imageUrl:
                      'https://tiyatronline.com/isDosyalar/2019/05/20/crop_gozlerimi-kaparim-vazifemi-yaparim-ank_ilf4LaFHkp.jpg',
                  showName: 'Gözlerimi Kaparım Vazifemi Yaparım',
                  category: 'Sinema',
                  date: '20 Eylül 2024',
                  stage: 'Göztepe',
                  price: 80,
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
