/// Oturum içi, bellekte tutulan tek bir sohbet mesajı. Kalıcılaştırma YOK
/// (Firestore'a yazılmıyor) — "en ucuz seçenek" kararıyla tutarlı: sayfa
/// kapanınca geçmiş kaybolur, bu kasıtlı.
class ShowChatMessage {
  final String text;
  final bool isUser;

  /// Bot mesajı cevapsız kaldığında (ya da elde gerçek veri yoksa) true —
  /// UI bu mesajın altına gerçek WhatsApp aksiyonuna bağlı bir buton çizer.
  final bool offerWhatsApp;

  const ShowChatMessage({
    required this.text,
    required this.isUser,
    this.offerWhatsApp = false,
  });
}
