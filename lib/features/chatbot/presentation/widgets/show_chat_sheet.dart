import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../shows/presentation/providers/show_detail_provider.dart';
import '../../domain/show_faq_matcher.dart';
import 'show_chat_message.dart';

/// Gösteri detay sayfasında açılan, tek seansı süren (kalıcı geçmiş YOK)
/// basit SSS sohbet paneli. `ShowFaqMatcher` — saf yerel anahtar kelime
/// eşleştirmesi, ağ çağrısı/API anahtarı yok — zaten sayfa için çekilmiş
/// olan `ShowDetailState` üzerinden gerçek veriyle cevap üretir.
class ShowChatSheet extends ConsumerStatefulWidget {
  final String showId;
  final String showName;

  const ShowChatSheet(
      {super.key, required this.showId, required this.showName});

  @override
  ConsumerState<ShowChatSheet> createState() => _ShowChatSheetState();
}

class _ShowChatSheetState extends ConsumerState<ShowChatSheet> {
  final List<ShowChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages.add(ShowChatMessage(
      text: '👋 Merhaba! "${widget.showName}" hakkında saat, tarih, fiyat, '
          'mekan, oyuncu kadrosu, süre, yaş sınırı ya da konusu ile ilgili '
          'soru sorabilirsin.',
      isUser: false,
    ));
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
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
      );
    });
  }

  void _handleSend(final ShowDetailState? state) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() {
      _messages.add(ShowChatMessage(text: text, isUser: true));
      if (state == null) {
        _messages.add(const ShowChatMessage(
          text: 'Gösteri bilgileri henüz yükleniyor, birazdan tekrar '
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

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final detailAsync = ref.watch(showDetailProvider(widget.showId));
    final state = detailAsync.value;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          boxShadow: AppShadows.level4(colors.shadow),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DragHandle(color: colors.onSurfaceVariant),
              _Header(showName: widget.showName, colors: colors),
              Divider(height: 1, color: colors.outlineVariant.withOpacity(0.4)),
              Flexible(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _messages.length,
                  itemBuilder: (final context, final index) =>
                      _ChatBubble(message: _messages[index]),
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant.withOpacity(0.4)),
              _InputRow(
                controller: _controller,
                isLoading: detailAsync.isLoading && state == null,
                onSend: () => _handleSend(state),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  final Color color;

  const _DragHandle({required this.color});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: AppRadius.asymSm,
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  final String showName;
  final ColorScheme colors;

  const _Header({required this.showName, required this.colors});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.forum_rounded, color: colors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hızlı Sorular',
                      style: context.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(showName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Kapat',
              icon: Icon(Icons.close_rounded, color: colors.onSurfaceVariant),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      );
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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (final _) => onSend(),
              decoration: InputDecoration(
                hintText: isLoading
                    ? 'Gösteri bilgileri yükleniyor...'
                    : 'Örn: seanslar ne zaman?',
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              boxShadow: AppShadows.level2(colors.primary),
            ),
            child: IconButton(
              tooltip: 'Gönder',
              icon: Icon(Icons.send_rounded, color: colors.onPrimary),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔥 DÜZELTME: Önceden mesajlar birdenbire, hiç hareketsiz beliriyordu ve
/// bot balonlarının kimden geldiğini gösteren bir kimliği (avatar) yoktu —
/// yalnızca renk/köşe farkıyla ayrılıyorlardı. Araştırılan chat-UI
/// paketlerinin (flutter_chat_ui, chat_ui_kit) ortak dili iki şeydi: (1)
/// her bot mesajının yanında küçük bir kimlik rozeti, (2) yeni mesajın
/// yumuşak bir giriş hareketiyle belirmesi. Burada da AYNI iki fikir,
/// paket eklemeden, mevcut token'larla: bot balonlarının yanında küçük bir
/// "SSS" ikon rozeti + her balonun BİR KEZ fade+kaymayla girişi
/// (`AppMotion.normal`/`standard` — sohbetin kendi hızı, `curtainTransition`
/// gibi "sahne anı" değil, sıradan bir içerik geçişi).
class _ChatBubble extends StatefulWidget {
  final ShowChatMessage message;

  const _ChatBubble({required this.message});

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
  )..forward();
  late final Animation<double> _entrance = CurvedAnimation(
      parent: _entranceController, curve: AppMotion.standard);

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.colors;
    final isUser = widget.message.isUser;

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: isUser ? colors.primary : colors.surfaceContainerHighest,
        // Klasik sohbet balonu "kuyruğu": kullanıcı balonunda sağ-alt,
        // bot balonunda sol-alt köşe keskin — hangi taraftan geldiği bir
        // bakışta anlaşılsın diye.
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppRadius.md),
          topRight: const Radius.circular(AppRadius.md),
          bottomLeft: Radius.circular(isUser ? AppRadius.md : 4),
          bottomRight: Radius.circular(isUser ? 4 : AppRadius.md),
        ),
      ),
      child: Text(
        widget.message.text,
        style: context.textTheme.bodyMedium?.copyWith(
          color: isUser ? colors.onPrimary : colors.onSurface,
          height: 1.4,
        ),
      ),
    );

    // Bot mesajının yanındaki küçük kimlik rozeti — kullanıcı balonunda
    // yok (kendi mesajı, kimden geldiği zaten belli).
    final Widget row = isUser
        ? bubble
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.forum_rounded,
                    size: 14, color: colors.primary),
              ),
              Flexible(child: bubble),
            ],
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: FadeTransition(
        opacity: _entrance,
        child: SlideTransition(
          position: _entrance.drive(
              Tween(begin: const Offset(0, 0.08), end: Offset.zero)),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: row,
              ),
              if (!isUser && widget.message.offerWhatsApp)
                Padding(
                  padding: const EdgeInsets.only(
                      top: AppSpacing.sm, left: AppSpacing.xxl),
                  child: OutlinedButton.icon(
                    onPressed: TiyatrolCommunicationActions.contactWhatsApp,
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 16),
                    label: const Text("WhatsApp'tan Sor"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side:
                          BorderSide(color: colors.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
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
