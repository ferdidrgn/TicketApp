mixin ArtQuotes {
  static final List<Map<String, String>> quotes = [
    {
      "word": "Sanat, doğanın taklidi değil, doğanın tamamlanmasıdır",
      "author": "Aristo"
    },
    {"word": "Sanat, ruhun sessiz dilidir", "author": "Pablo Picasso"},
    {
      "word": "Her sanat eseri, bir umut ışığıdır",
      "author": "Leonardo da Vinci"
    },
    {
      "word": "Sanat, insanın kendini ifade etme biçimidir",
      "author": "Vincent van Gogh"
    },
    {"word": "Sanat uzun, hayat kısadır", "author": "Hipokrat"},
    {"word": "Sanat, görünmez olanı görünür kılmaktır", "author": "Paul Klee"},
  ];

  static Map<String, String> getRandomQuote() =>
      quotes[DateTime.now().second % quotes.length];
}
