import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../shows/presentation/providers/show_detail_provider.dart';
import '../../domain/show_faq_matcher.dart';
import 'show_chat_message.dart';

/// Oyun detayında açılan, tek oturumluk (kalıcı geçmiş YOK) yardım
/// sohbeti. `ShowFaqMatcher` — saf yerel anahtar kelime eşleştirmesi, ağ
/// çağrısı/API anahtarı yok — zaten sayfa için çekilmiş `ShowDetailState`
/// üzerinden gerçek veriyle cevap üretir; cevaplayamadığında WhatsApp'a
/// yönlendirir (mantık değişmedi).
///
/// Görünüm: temanın yüzeyinde sade, okunaklı bir konuşma. Balonlar
/// simetrik yuvarlak köşeli (eski "D harfi" / keskin kuyruk köşeleri
/// kaldırıldı); kim konuşuyor hizalama + renkle belli. Sohbet başında
/// hazır sorular (aynı eşleştiriciye gider) — yazmadan sormak için.
///
/// [floating] true → masaüstünde sağ altta yüzen panel (tüm köşeler
/// yuvarlak, tutamaç yok); false → alttan açılan sayfa (mobil/tablet).
class ShowChatSheet extends ConsumerStatefulWidget {
  final String showId;
  final String showName;
  final bool floating;

  const ShowChatSheet({
    super.key,
    required this.showId,
    required this.showName,
    this.floating = false,
  });

  @override
  ConsumerState<ShowChatSheet> createState() => _ShowChatSheetState();
}

/// Hazır sorular — metinleri `ShowFaqMatcher`'ın anahtar kelimelerini
/// içerir (saat/fiyat/nerede/oyuncu/süre).
const List<String> _kSuggestions = [
  'Seanslar ne zaman?',
  'Bilet fiyatı ne kadar?',
  'Oyun nerede oynanıyor?',
  'Oyuncu kadrosu kim?',
  'Oyun süresi kaç dakika?',
];

class _ShowChatSheetState extends ConsumerState<ShowChatSheet> {
  final List<ShowChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _messages.add(ShowChatMessage(
      text: 'Merhaba! "${widget.showName}" hakkında seans, fiyat, mekan, '
          'oyuncu kadrosu, süre, yaş sınırı ya da konusu ile ilgili '
          'soru sorabilirsin.',
      isUser: false,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (!_scrollController.hasClients) return;
      final double end = _scrollController.position.maxScrollExtent;
      if (_reduceMotion) {
        _scrollController.jumpTo(end);
      } else {
        _scrollController.animateTo(
          end,
          duration: AppMotion.fast,
          curve: AppMotion.standard,
        );
      }
    });
  }

  void _ask(final String rawText, final ShowDetailState? state) {
    final text = rawText.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ShowChatMessage(text: text, isUser: true));
      if (state == null) {
        _messages.add(const ShowChatMessage(
          text: 'Oyun bilgileri henüz yükleniyor, birazdan tekrar '
              'dener misin?',
          isUser: false,
        ));
      } else {
        final answer = ShowFaqMatcher.answer(text, state);
        _messages.add(ShowChatMessage(
          text: answer.text,
          isUser: false,
          offerWhatsApp: answer.offerWhatsApp,
        ));
      }
    });
    _scrollToBottom();
  }

  void _handleSend(final ShowDetailState? state) {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    _ask(text, state);
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final detailAsync = ref.watch(showDetailProvider(widget.showId));
    final state = detailAsync.value;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final bool floating = widget.floating;
    // Kullanıcı henüz bir şey sormadıysa hazır sorular gösterilir.
    final bool showSuggestions = !_messages.any((final m) => m.isUser);

    final Widget panel = Column(
      mainAxisSize: floating ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!floating) _DragHandle(color: colors.outlineVariant),
        _Header(showName: widget.showName),
        Divider(height: 1, thickness: 1, color: colors.outlineVariant),
        Flexible(
          fit: floating ? FlexFit.tight : FlexFit.loose,
          child: ListView.builder(
            controller: _scrollController,
            shrinkWrap: !floating,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
                AppSpacing.lg, AppSpacing.sm),
            itemCount: _messages.length + (showSuggestions ? 1 : 0),
            itemBuilder: (final context, final index) {
              if (index == _messages.length) {
                return _Suggestions(
                  onPick: (final q) => _ask(q, state),
                );
              }
              return _ChatBubble(
                message: _messages[index],
                animate: !_reduceMotion,
              );
            },
          ),
        ),
        Divider(height: 1, thickness: 1, color: colors.outlineVariant),
        _InputRow(
          controller: _controller,
          isLoading: detailAsync.isLoading && state == null,
          onSend: () => _handleSend(state),
        ),
      ],
    );

    if (floating) {
      return Material(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: panel,
      );
    }

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          boxShadow: AppShadows.level4(colors.shadow),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(top: false, child: panel),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  final Color color;

  const _DragHandle({required this.color});

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  final String showName;

  const _Header({required this.showName});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Bu oyun hakkında sor',
                    style: GoogleFonts.playfairDisplay(
                      color: colors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  showName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kapat',
            icon: Icon(Icons.close_rounded, color: colors.onSurfaceVariant),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

/// Sohbet başındaki hazır sorular — dokununca kullanıcı mesajı olarak
/// gönderilir.
class _Suggestions extends StatelessWidget {
  final ValueChanged<String> onPick;

  const _Suggestions({required this.onPick});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final q in _kSuggestions)
            ActionChip(
              label: Text(q),
              onPressed: () => onPick(q),
              labelStyle: TextStyle(
                color: colors.onSurface,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: colors.surface,
              side: BorderSide(color: colors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputRow(
      {required this.controller, required this.isLoading, required this.onSend});

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (final _) => onSend(),
              style: TextStyle(color: colors.onSurface, fontSize: 15),
              decoration: InputDecoration(
                hintText: isLoading
                    ? 'Oyun bilgileri yükleniyor...'
                    : 'Sorunu yaz, ör. seanslar ne zaman?',
                hintStyle: TextStyle(color: colors.onSurfaceVariant),
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton.filled(
            tooltip: 'Gönder',
            onPressed: onSend,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            style: IconButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}

/// Tek mesaj. Bot solda, temanın ikincil yüzeyinde; kullanıcı sağda,
/// vurgu renginde. Yeni mesaj bir kez kısa bir kayma + solma ile girer
/// (azaltılmış harekette doğrudan görünür).
class _ChatBubble extends StatefulWidget {
  final ShowChatMessage message;
  final bool animate;

  const _ChatBubble({required this.message, required this.animate});

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
    value: widget.animate ? 0 : 1,
  );
  late final Animation<double> _entrance = CurvedAnimation(
      parent: _entranceController, curve: AppMotion.standard);

  @override
  void initState() {
    super.initState();
    if (widget.animate) _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final isUser = widget.message.isUser;

    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isUser ? colors.primary : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: SelectableText(
            widget.message.text,
            style: TextStyle(
              color: isUser ? colors.onPrimary : colors.onSurface,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: FadeTransition(
        opacity: _entrance,
        child: SlideTransition(
          position: _entrance.drive(
              Tween(begin: const Offset(0, 0.06), end: Offset.zero)),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Semantics(
                label: isUser ? 'Sen' : 'TiyatRol',
                child: Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: bubble,
                ),
              ),
              if (!isUser && widget.message.offerWhatsApp)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: OutlinedButton.icon(
                    onPressed: TiyatrolCommunicationActions.contactWhatsApp,
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 18),
                    label: const Text("WhatsApp'tan sor"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      minimumSize: const Size(0, 44),
                      side: BorderSide(color: colors.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
