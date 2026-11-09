// Kural tabanlı SSS botu (Q-2, docs/SSS-BOTU.md). YAPAY ZEKA YOK: Türkçe normalizasyon + anahtar sözcük (kök) eşleşmesi.
// Cevap YALNIZ oyunun gerçek alanlarından ya da sabit politika cümlesinden üretilir; alan yoksa cevap null (uydurma yok).
// Web karşılığı: site/js/ssb.js. Aynı kural tablosu + ortak test vektörleri (docs/ssb-vectors.json).
// Birini değiştirirsen diğerini ve docs/SSS-BOTU.md tablosunu BİRLİKTE güncelle.

/// Botun okuduğu oyun gerçekleri. Boş string = bilgi yok.
class FaqFacts {
  const FaqFacts({
    this.name = '',
    this.duration = '',
    this.ageLimit = '',
    this.interval = '',
    this.contentNotes = '',
    this.accessCodes = const <String>[],
    this.venueName = '',
    this.venueAddress = '',
    this.transit = '',
    this.accessNotes = '',
    this.external = false,
    this.externalHost = '',
    this.ended = false,
    this.saleMode = 'rezervasyon',
    this.castNames = const <String>[],
    this.teamName = '',
    this.price,
    this.nextDate = '',
    this.description = '',
  });

  final String name,
      duration,
      ageLimit,
      interval,
      contentNotes,
      venueName,
      venueAddress,
      transit,
      accessNotes,
      externalHost,
      saleMode,
      teamName,
      nextDate,
      description;
  final List<String> accessCodes;
  final List<String> castNames;
  final bool external, ended;
  final double? price;

  factory FaqFacts.fromJson(final Map<String, dynamic> j) => FaqFacts(
        name: (j['name'] ?? '') as String,
        duration: (j['duration'] ?? '') as String,
        ageLimit: (j['ageLimit'] ?? '') as String,
        interval: (j['interval'] ?? '') as String,
        contentNotes: (j['contentNotes'] ?? '') as String,
        accessCodes: [for (final c in (j['accessCodes'] as List? ?? const [])) c.toString()],
        venueName: (j['venueName'] ?? '') as String,
        venueAddress: (j['venueAddress'] ?? '') as String,
        transit: (j['transit'] ?? '') as String,
        accessNotes: (j['accessNotes'] ?? '') as String,
        external: j['external'] == true,
        externalHost: (j['externalHost'] ?? '') as String,
        ended: j['ended'] == true,
        saleMode: (j['saleMode'] ?? 'rezervasyon') as String,
        castNames: [for (final c in (j['castNames'] as List? ?? const [])) c.toString()],
        teamName: (j['teamName'] ?? '') as String,
        price: (j['price'] as num?)?.toDouble(),
        nextDate: (j['nextDate'] ?? '') as String,
        description: (j['description'] ?? '') as String,
      );
}

class FaqReply {
  const FaqReply(this.intent, this.answer);

  /// '' = soru anlaşılmadı.
  final String intent;

  /// null = bu konuda oyunun verisi yok.
  final String? answer;
}

class _Niyet {
  const _Niyet(this.id, this.kw);
  final String id;
  final List<String> kw;
}

class FaqBot {
  const FaqBot._();

  static const String yok = 'Bu konuda bilgi yok, ekibe sorabilirsin.';

  static const List<_Niyet> niyetler = [
    _Niyet('sure', ['sure', 'suruyor', 'surer', 'kac dakika', 'kac saat', 'kac dk', 'uzun', 'ne zaman biter', 'kacta biter', 'dakika']),
    _Niyet('cocuk', ['cocu', 'bebek', 'minik', 'ilkokul', 'ortaokul', 'anaokul']),
    _Niyet('yas', ['yas\$', 'yasi\$', 'yasinda', 'yas sinir', 'kac yas', 'yas kisit', 'yetiskin']),
    _Niyet('ara', ['ara\$', 'araya', 'ara var', 'antrakt', 'intermission', 'kac ara']),
    _Niyet('gec', ['gec kal', 'gec gel', 'gec gir', 'gec kald', 'geciktim', 'gecik', 'salona al', 'sonradan gir', 'basladiktan sonra']),
    _Niyet('iade', ['iade', 'iptal', 'geri ver', 'para iade', 'bileti degis', 'vazgec', 'bileti ver']),
    _Niyet('bilet', ['nasil bilet', 'bilet al', 'biletini nereden', 'bilet nereden', 'bilet nerden', 'nereden al', 'nerden al', 'satin al', 'rezervasyon', 'bilet nasil', 'nasil alirim', 'nasil alabilir', 'nasil satin']),
    _Niyet('erisim', ['engelli', 'erisil', 'tekerlek', 'rampa', 'asansor', 'sesli betimleme', 'isaret dili', 'altyazi', 'isitme', 'gorme', 'kolay erisim']),
    _Niyet('ulasim', ['park', 'otopark', 'ulasim', 'metro', 'otobus', 'nasil gid', 'nasil gel', 'yol tarif', 'adres', 'nerede\$', 'nerde\$', 'konum', 'mekan']),
    _Niyet('uyari', ['icerik uyari', 'uyari', 'siddet', 'kufur', 'argo', 'korku', 'cinsel', 'strobo', 'isik efekt', 'yuksek ses', 'silah', 'kan\$']),
    _Niyet('kadro', ['kim oynuyor', 'kimler oynuyor', 'kim oynar', 'oyuncu', 'oyuncular', 'kadro', 'ekip kim', 'oyun ekibi', 'kim var\$', 'kimler var\$', 'kim rol']),
    _Niyet('fiyat', ['fiyat', 'ucret', 'kac para', 'bilet fiyat', 'ne kadar tutuyor', 'kaca']),
    _Niyet('tarih', ['ne zaman oynuyor', 'ne zaman var', 'hangi tarih', 'sonraki seans', 'bir sonraki seans', 'yaklasan seans', 'bugun var mi', 'bu hafta var mi']),
    _Niyet('konu', ['konu', 'ozet', 'ne anlatiyor', 'hikayesi ne', 'nedir bu oyun', 'ne hakkinda']),
  ];

  static const Map<String, String> _erisAd = {
    'AD': 'Sesli betimleme',
    'CAP': 'Altyazılı',
    'BSL': 'İşaret dili',
    'R': 'Rahat gösterim',
    'TS': 'İşaret dili',
  };

  /// Türkçe normalizasyon: küçük harf, ı/ğ/ş/ü/ö/ç -> i/g/s/u/o/c, harf-rakam dışı -> boşluk.
  static String norm(final String s) {
    final b = StringBuffer();
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      b.write(ch == 'İ' || ch == 'I' || ch == 'ı' ? 'i' : ch);
    }
    return b
        .toString()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  static bool _eslesir(final String metin, final String kw) {
    final tam = kw.endsWith('\$');
    final k = tam ? kw.substring(0, kw.length - 1) : kw;
    final s = ' $metin ';
    return tam ? s.contains(' $k ') : s.contains(' $k');
  }

  static FaqReply sor(final String soru, final FaqFacts f) {
    final m = norm(soru);
    _Niyet? en;
    int enPuan = 0;
    for (final n in niyetler) {
      int p = 0;
      for (final k in n.kw) {
        if (_eslesir(m, k)) p++;
      }
      if (p > enPuan) {
        en = n;
        enPuan = p;
      }
    }
    if (en == null) return const FaqReply('', null);
    return FaqReply(en.id, _cevap(en.id, f));
  }

  static bool _dolu(final String v) => v.trim().isNotEmpty;
  static String _nokta(final String s) => RegExp(r'[.!?]$').hasMatch(s) ? s : '$s.';

  static String? _cevap(final String id, final FaqFacts f) {
    final notlar = _dolu(f.contentNotes) ? ' İçerik uyarısı: ${_nokta(f.contentNotes.trim())}' : '';
    switch (id) {
      case 'sure':
        if (!_dolu(f.duration)) return null;
        return 'Oyunun süresi ${f.duration.trim()}${_dolu(f.interval) ? '; ${f.interval.trim()}' : ''}.';
      case 'yas':
        if (!_dolu(f.ageLimit)) return null;
        return 'Önerilen yaş: ${f.ageLimit.trim()}.$notlar';
      case 'cocuk':
        if (!_dolu(f.ageLimit) && !_dolu(f.contentNotes)) return null;
        return '${_dolu(f.ageLimit) ? 'Önerilen yaş: ${f.ageLimit.trim()}.' : ''}$notlar Küçük çocuklarla gelmeden önce yaş önerisine ve içerik uyarısına bakmanı öneririz.'
            .trim();
      case 'ara':
        return _dolu(f.interval) ? 'Ara bilgisi: ${_nokta(f.interval.trim())}' : null;
      case 'gec':
        return 'Geç kalanların salona alınıp alınmayacağı ve hangi arada alınacağı salona ve organizatöre göre değişir; garanti verilemez. Seanstan 20-30 dakika önce yerinde olmanı öneririz.';
      case 'iade':
        if (f.external) {
          return 'Bilet bu sitede değil ${_dolu(f.externalHost) ? f.externalHost.trim() : 'organizatörün sitesinde'} satıldığı için iade ve iptal koşullarını satış yapılan platformdan öğrenmelisin.';
        }
        return f.saleMode == 'rezervasyon'
            ? 'Şu an biletler rezervasyon olarak veriliyor; etkinlikten (varsayılan) 24 saat öncesine kadar Biletlerim sayfasından iptal edebilirsin. Ayrıntılar İade ve İptal Koşulları sayfasında.'
            : 'İptal ve iade koşulları satış moduna ve etkinliğe göre değişir; güncel koşullar İade ve İptal Koşulları sayfasında yer alır. Organizatör etkinliği iptal ederse bilet bedelinin tamamı iade edilir.';
      case 'bilet':
        if (f.ended) return null;
        return f.external
            ? 'Biletler ${_dolu(f.externalHost) ? f.externalHost.trim() : 'organizatörün sitesi'} üzerinden satılıyor; TiyatRol seni doğru sayfaya yönlendirir.'
            : 'Bu sayfada bir seans seçip Bilet al diyerek koltuğunu seçebilirsin; biletlerin hesabındaki Biletlerim sayfasında ve uygulamada görünür.';
      case 'erisim':
        final kodlar = <String>[];
        for (final k in f.accessCodes) {
          final a = _erisAd[k.toUpperCase()];
          if (a != null && !kodlar.contains(a)) kodlar.add(a);
        }
        final p = <String>[];
        if (kodlar.isNotEmpty) p.add('Erişilebilir gösterim etiketleri: ${kodlar.join(', ')}.');
        if (_dolu(f.accessNotes)) p.add('Mekân notu: ${_nokta(f.accessNotes.trim())}');
        return p.isEmpty ? null : p.join(' ');
      case 'ulasim':
        final p = <String>[];
        if (_dolu(f.venueName)) {
          p.add('Mekân: ${f.venueName.trim()}${_dolu(f.venueAddress) ? ', ${f.venueAddress.trim()}' : ''}.');
        }
        if (_dolu(f.transit)) p.add('Ulaşım: ${_nokta(f.transit.trim())}');
        return p.isEmpty ? null : p.join(' ');
      case 'uyari':
        return _dolu(f.contentNotes) ? 'İçerik uyarısı: ${_nokta(f.contentNotes.trim())}' : null;
      case 'kadro':
        final isimler = f.castNames.where(_dolu).toList();
        if (isimler.isEmpty) return null;
        final takim = _dolu(f.teamName) ? ' Oyunu sahneleyen topluluk: ${f.teamName.trim()}.' : '';
        return 'Kadroda: ${isimler.join(', ')}.$takim';
      case 'fiyat':
        if (f.ended) return null;
        if (f.external) {
          return 'Bilet fiyatını ${_dolu(f.externalHost) ? f.externalHost.trim() : 'organizatörün sitesinde'} görebilirsin.';
        }
        if (f.price == null) return null;
        return f.price! > 0 ? 'En yakın seans için bilet fiyatı: ${f.price!.round()} ₺.' : 'En yakın seans ücretsiz.';
      case 'tarih':
        if (!_dolu(f.nextDate)) return f.ended ? 'Bu oyunun planlanmış, tarihi geçmemiş bir seansı görünmüyor.' : null;
        return 'En yakın seans: ${f.nextDate.trim()}${_dolu(f.venueName) ? ', ${f.venueName.trim()}' : ''}.';
      case 'konu':
        return _dolu(f.description) ? f.description.trim() : null;
    }
    return null;
  }
}
