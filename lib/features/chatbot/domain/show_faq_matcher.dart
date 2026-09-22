import '../../../core/util/date_formatter.dart';
import '../../events/domain/entities/event.dart';
import '../../shows/presentation/providers/show_detail_provider.dart';
import '../../stages/domain/entities/stage.dart';

/// Bir sohbet cevabının sonucu. [offerWhatsApp] true olduğunda, UI bu
/// cevabın altına gerçek `TiyatrolCommunicationActions.contactWhatsApp()`
/// bağlı bir buton çizer — botun cevaplayamadığı (ya da elindeki gerçek
/// veriyle cevaplayamadığı) her durumda kullanıcı ölü bir uca değil, gerçek
/// bir iletişim kanalına yönlendirilir.
class ShowFaqAnswer {
  final String text;
  final bool offerWhatsApp;

  const ShowFaqAnswer(this.text, {this.offerWhatsApp = false});
}

/// SAF Dart, ağ çağrısı YOK, API anahtarı YOK — tamamen yerel anahtar
/// kelime eşleştirmesi. Bilinçli olarak "en ucuz" seçenek: gerçek bir
/// LLM/asistan API'si değil, `ShowDetailState`'te zaten elde bulunan
/// gerçek veriden (show/events/stages/players) kural tabanlı cevap üreten
/// bir SSS botu.
final class ShowFaqMatcher {
  ShowFaqMatcher._();

  static const int _maxPlayerNames = 8;

  /// Küçük harfe çevirir + Türkçe karakterleri sadeleştirir (İ/I/ı -> i,
  /// ş/ç/ğ/ö/ü -> s/c/g/o/u) — böylece hem kullanıcının yazdığı soru hem de
  /// bu dosyadaki anahtar kelimeler (ASCII) aynı biçimde karşılaştırılır.
  /// Tam bir NLP hattı değil, kasıtlı olarak bu kadar basit tutuldu.
  static String normalize(final String input) {
    var result = input.replaceAll('İ', 'i').replaceAll('I', 'i').toLowerCase();
    const diacritics = {
      'ı': 'i',
      'ş': 's',
      'ç': 'c',
      'ğ': 'g',
      'ö': 'o',
      'ü': 'u',
    };
    for (final entry in diacritics.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result.trim();
  }

  static bool _matchesAny(final String q, final List<String> keywords) =>
      keywords.any(q.contains);

  /// `state.events`'ten, tarihi henüz geçmemiş, en yakın etkinliği bulur.
  /// `show_provider.dart`'taki `_activeShowIdsFromEvents` ile aynı "geçerlilik"
  /// felsefesi: `DateFormatter.parseDateString` + `date.isAfter(now)`.
  static Event? _nextUpcomingEvent(final List<Event> events) {
    final now = DateTime.now();
    Event? nearest;
    DateTime? nearestDate;
    for (final event in events) {
      final date = DateFormatter.parseDateString(event.date);
      if (date == null || !date.isAfter(now)) continue;
      if (nearestDate == null || date.isBefore(nearestDate)) {
        nearest = event;
        nearestDate = date;
      }
    }
    return nearest;
  }

  static Stage? _stageFor(final Event event, final List<Stage> stages) {
    for (final stage in stages) {
      if (stage.id == event.stageId) return stage;
    }
    return null;
  }

  static String _formatEventDateTime(final Event event) {
    final parts = DateFormatter.parseFormattedDateTime(event.date,
        formatWithMonthName: true);
    return '${parts['date']}, ${parts['time']}';
  }

  static ShowFaqAnswer answer(
      final String question, final ShowDetailState state) {
    final q = normalize(question);
    final show = state.show;

    // Süre — "fiyat"/"ne kadar" ile karışmasın diye önce kontrol edilir
    // (bkz. "ne kadar sürüyor" hem burada hem fiyat sorusunda geçebilir).
    if (_matchesAny(q, ['sure', 'kac dakika', 'ne kadar suruyor'])) {
      return _durationAnswer(show.duration);
    }

    // Yaş sınırı
    if (_matchesAny(q, ['yas', 'sinir', 'kac yas'])) {
      return _ageLimitAnswer(show.ageLimit);
    }

    // Tarih / saat
    if (_matchesAny(q, ['saat', 'ne zaman', 'tarih', 'hangi gun'])) {
      return _dateAnswer(state.events);
    }

    // Fiyat
    if (_matchesAny(q, ['fiyat', 'ucret', 'kac para', 'ne kadar'])) {
      return _priceAnswer(state.events);
    }

    // Mekan / sahne / adres
    if (_matchesAny(q, ['nerede', 'mekan', 'sahne', 'adres'])) {
      return _venueAnswer(state.events, state.stages);
    }

    // Oyuncu kadrosu
    if (_matchesAny(q, ['oyuncu', 'kim oynuyor', 'kadro'])) {
      return _castAnswer(state);
    }

    // Bilet / rezervasyon
    if (_matchesAny(q, ['bilet', 'nasil alirim', 'rezervasyon'])) {
      return _ticketAnswer();
    }

    // Konu / özet
    if (_matchesAny(q, ['konu', 'ne anlatiyor', 'ozet'])) {
      return _descriptionAnswer(show.description);
    }

    return const ShowFaqAnswer(
      'Bu soruyu şu an yanıtlayamıyorum. Ama ekibimize WhatsApp\'tan '
      'yazarsan sana hemen yardımcı olurlar.',
      offerWhatsApp: true,
    );
  }

  static ShowFaqAnswer _durationAnswer(final String duration) {
    final trimmed = duration.trim();
    if (trimmed.isEmpty) {
      return const ShowFaqAnswer(
        'Bu gösterinin süresi şu an sistemde kayıtlı değil. WhatsApp\'tan '
        'sorabilirsin.',
        offerWhatsApp: true,
      );
    }
    return ShowFaqAnswer('Gösterinin süresi yaklaşık $trimmed.');
  }

  static ShowFaqAnswer _ageLimitAnswer(final String ageLimit) {
    final trimmed = ageLimit.trim();
    if (trimmed.isEmpty) {
      return const ShowFaqAnswer(
        'Bu gösteri için özel bir yaş sınırı bilgisi sistemde kayıtlı '
        'değil. WhatsApp\'tan sorabilirsin.',
        offerWhatsApp: true,
      );
    }
    return ShowFaqAnswer('Bu gösterinin yaş sınırı: $trimmed.');
  }

  static ShowFaqAnswer _dateAnswer(final List<Event> events) {
    final next = _nextUpcomingEvent(events);
    if (next == null) {
      return const ShowFaqAnswer(
        'Şu an için planlanmış, tarihi geçmemiş bir seans göremiyorum. '
        'Yeni seanslar eklendiğinde burada görünecek — WhatsApp\'tan da '
        'sorabilirsin.',
        offerWhatsApp: true,
      );
    }
    return ShowFaqAnswer('En yakın seans: ${_formatEventDateTime(next)}.');
  }

  static ShowFaqAnswer _priceAnswer(final List<Event> events) {
    final next = _nextUpcomingEvent(events);
    if (next == null) {
      return const ShowFaqAnswer(
        'Şu an planlanmış bir seans olmadığı için bilet fiyatını '
        'söyleyemiyorum. WhatsApp\'tan sorabilirsin.',
        offerWhatsApp: true,
      );
    }
    final priceValue = double.tryParse(next.price);
    final priceLabel = priceValue != null && priceValue > 0
        ? '₺${priceValue.toStringAsFixed(0)}'
        : null;
    if (priceLabel == null) {
      return const ShowFaqAnswer(
        'En yakın seans için bilet fiyatı sistemde kayıtlı değil. '
        'WhatsApp\'tan sorabilirsin.',
        offerWhatsApp: true,
      );
    }
    return ShowFaqAnswer(
        'En yakın seans (${_formatEventDateTime(next)}) için bilet '
        'fiyatı: $priceLabel.');
  }

  static ShowFaqAnswer _venueAnswer(
      final List<Event> events, final List<Stage> stages) {
    final next = _nextUpcomingEvent(events);
    final stage = next != null ? _stageFor(next, stages) : null;
    if (stage == null || stage.name.trim().isEmpty) {
      return const ShowFaqAnswer(
        'Mekan bilgisini şu an bulamadım. WhatsApp\'tan sorabilirsin.',
        offerWhatsApp: true,
      );
    }
    final address = stage.address.trim();
    return ShowFaqAnswer(address.isEmpty
        ? 'Gösteri ${stage.name} sahnesinde.'
        : 'Gösteri ${stage.name} sahnesinde. Adres: $address');
  }

  static ShowFaqAnswer _castAnswer(final ShowDetailState state) {
    final nowPlayerIds = state.show.nowPlayersId.toSet();
    var cast = state.players
        .where((final p) => nowPlayerIds.contains(p.id))
        .toList();
    // `nowPlayersId` boş/eşleşmiyorsa (ör. veri henüz senkron değil) elimizdeki
    // tüm kadroyu göster — uydurma isim üretmek yerine mevcut gerçek veriyi
    // kullanmaya devam ediyoruz.
    if (cast.isEmpty) cast = state.players;
    if (cast.isEmpty) {
      return const ShowFaqAnswer(
        'Kadro bilgisi şu an sistemde kayıtlı değil. WhatsApp\'tan '
        'sorabilirsin.',
        offerWhatsApp: true,
      );
    }
    final names = cast
        .take(_maxPlayerNames)
        .map((final p) => '${p.firstName} ${p.lastName}'.trim())
        .where((final n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      return const ShowFaqAnswer(
        'Kadro bilgisi şu an sistemde kayıtlı değil. WhatsApp\'tan '
        'sorabilirsin.',
        offerWhatsApp: true,
      );
    }
    final suffix = cast.length > names.length ? ' ve daha fazlası' : '';
    return ShowFaqAnswer('Kadroda: ${names.join(', ')}$suffix.');
  }

  static ShowFaqAnswer _ticketAnswer() => const ShowFaqAnswer(
        'Bilet almak için gösteri sayfasındaki seans listesinden bir '
        'tarih seç, "Bilet Al" ile koltuk seçim ekranına geçip sana uygun '
        'koltukları seçebilirsin.',
      );

  static ShowFaqAnswer _descriptionAnswer(final String description) {
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      return const ShowFaqAnswer(
        'Bu gösterinin konu özeti şu an sistemde kayıtlı değil. '
        'WhatsApp\'tan sorabilirsin.',
        offerWhatsApp: true,
      );
    }
    return ShowFaqAnswer(trimmed.replaceAll('\\n', ' '));
  }
}
