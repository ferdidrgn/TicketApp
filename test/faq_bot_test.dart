import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/shows/domain/faq_bot.dart';

void main() {
  test('SSS botu: ortak test vektörleri (docs/ssb-vectors.json) web ile aynı sonucu verir', () {
    final v = jsonDecode(File('docs/ssb-vectors.json').readAsStringSync()) as Map<String, dynamic>;
    final facts = <String, FaqFacts>{
      for (final e in (v['facts'] as Map<String, dynamic>).entries) e.key: FaqFacts.fromJson(e.value as Map<String, dynamic>),
    };
    final cases = v['cases'] as List;
    expect(cases.length, greaterThan(20));
    for (final c in cases) {
      final m = c as Map<String, dynamic>;
      final r = FaqBot.sor(m['q'] as String, facts[m['f']]!);
      expect(r.intent, m['intent'], reason: m['q'] as String);
      expect(r.answer, m['answer'], reason: m['q'] as String);
    }
  });

  test('normalizasyon: Türkçe harfler', () {
    expect(FaqBot.norm('İSTANBUL ŞEHİR ÇOCUK ĞÜÖ ıI'), 'istanbul sehir cocuk guo ii');
  });
}
