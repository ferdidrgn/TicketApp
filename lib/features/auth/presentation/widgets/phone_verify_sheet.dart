import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show PhoneAuthCredential;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/phone_link_service.dart';
import '../providers/auth_mutation_provider.dart';
import '../providers/phone_link_provider.dart';

/// "Telefonunu doğrula" sonucu.
enum PhoneVerifyResult {
  /// Telefon mevcut hesaba bağlandı (hesap aynı).
  verified,

  /// Telefon başka hesapta bulundu; kullanıcı o hesapla giriş yaptı.
  switchedAccount,

  /// Vazgeçildi.
  cancelled,
}

/// Mevcut kullanıcıya (misafir/Google) SMS ile telefonu BAĞLAYAN alt sayfa.
/// Hesabı DEĞİŞTİRMEZ (`linkWithCredential`); telefon başka hesaptaysa
/// kullanıcıya açık seçenek sunar.
Future<PhoneVerifyResult> showPhoneVerifySheet(final BuildContext context) async {
  final r = await showModalBottomSheet<PhoneVerifyResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (final _) => const PhoneVerifySheet(),
  );
  return r ?? PhoneVerifyResult.cancelled;
}

enum _Step { phone, code, inUse }

class PhoneVerifySheet extends ConsumerStatefulWidget {
  const PhoneVerifySheet({super.key});

  @override
  ConsumerState<PhoneVerifySheet> createState() => _PhoneVerifySheetState();
}

class _PhoneVerifySheetState extends ConsumerState<PhoneVerifySheet> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _code = TextEditingController();

  _Step _step = _Step.phone;
  bool _busy = false;
  String? _error;
  String? _verificationId;
  int? _resendToken;
  PhoneAuthCredential? _otherAccountCredential;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  PhoneLinkService get _svc => ref.read(phoneLinkServiceProvider);

  /// 5XX XXX XX XX (başında 0 olsa da olmasa da) -> +905XXXXXXXXX
  String? get _e164 {
    var d = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0')) {
      d = d.substring(1);
    }
    return d.length == 10 && d.startsWith('5') ? '+90$d' : null;
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (final t) {
      if (!mounted || _resendIn <= 1) {
        t.cancel();
      }
      if (mounted) {
        setState(() => _resendIn = _resendIn > 0 ? _resendIn - 1 : 0);
      }
    });
  }

  Future<void> _send({final bool resend = false}) async {
    final number = _e164;
    if (number == null) {
      setState(() => _error =
          'Numaranı başında 0 olmadan 10 hane olarak gir (5XX XXX XX XX).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await _svc.sendCode(number,
          resendToken: resend ? _resendToken : null);
      if (!mounted) return;
      if (r.autoCredential != null) {
        // Android anlık doğrulama: kod girmeden bağla.
        await _handleOutcome(await _svc.linkWithCredential(r.autoCredential!));
        return;
      }
      _verificationId = r.verificationId;
      _resendToken = r.resendToken;
      _code.clear();
      setState(() {
        _step = _Step.code;
        _busy = false;
      });
      _startTimer();
    } on PhoneLinkException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = phoneAuthErrorMessage('');
        });
      }
    }
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    final id = _verificationId;
    if (code.length != 6 || id == null) {
      setState(() => _error = 'Lütfen 6 haneli kodu eksiksiz gir.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await _handleOutcome(await _svc.linkWithCode(id, code));
  }

  Future<void> _handleOutcome(final PhoneLinkOutcome outcome) async {
    if (!mounted) return;
    switch (outcome) {
      case PhoneLinked():
        ref.read(authMutationProvider.notifier).refreshAfterPhoneLink();
        Navigator.of(context).pop(PhoneVerifyResult.verified);
      case PhoneInUse(:final credential):
        setState(() {
          _busy = false;
          _step = _Step.inUse;
          _otherAccountCredential = credential;
          _error = null;
        });
      case PhoneLinkError(:final message):
        setState(() {
          _busy = false;
          _error = message;
        });
    }
  }

  Future<void> _switchAccount() async {
    final c = _otherAccountCredential;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await _svc.switchToPhoneAccount(c);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = '$err Telefonla giriş ekranından o hesaba girebilirsin.';
      });
      return;
    }
    await ref.read(authMutationProvider.notifier).finishPhoneAccountSwitch();
    if (mounted) {
      Navigator.of(context).pop(PhoneVerifyResult.switchedAccount);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    final title = switch (_step) {
      _Step.phone => 'Telefonunu doğrula',
      _Step.code => 'SMS kodunu gir',
      _Step.inUse => 'Bu numara başka bir hesapta',
    };
    final body = switch (_step) {
      _Step.phone => 'Biletlerin ve koltukların telefon numarana bağlı. '
          'SMS ile 6 haneli bir kod göndereceğiz.',
      _Step.code => '${maskPhone(_e164)} numarasına gelen 6 haneli kodu gir.',
      _Step.inUse => 'Bu telefon daha önce başka bir hesaba bağlanmış. '
          'O hesapla giriş yaparsan şu anki oturumun kapanır ve o hesabın '
          'bilet bilgilerine geçersin.',
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.xxl + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(title,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(body,
                style: tt.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant, height: 1.45)),
            const SizedBox(height: AppSpacing.xl),
            if (_step == _Step.phone) _phoneField(),
            if (_step == _Step.code) _codeField(),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Semantics(
                liveRegion: true,
                child: Text(_error!,
                    style: tt.bodySmall?.copyWith(color: cs.error)),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            ..._actions(),
          ],
        ),
      ),
    );
  }

  Widget _phoneField() => TextField(
        controller: _phone,
        enabled: !_busy,
        autofocus: true,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
        ],
        onSubmitted: (final _) => _send(),
        decoration: InputDecoration(
          labelText: 'Telefon numarası',
          hintText: '5XX XXX XX XX',
          prefixText: '+90  ',
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      );

  Widget _codeField() => TextField(
        controller: _code,
        enabled: !_busy,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        onSubmitted: (final _) => _verify(),
        decoration: InputDecoration(
          labelText: 'SMS kodu',
          hintText: '6 haneli kod',
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      );

  Widget _primary(final String label, final VoidCallback? onPressed) =>
      FilledButton(
        onPressed: _busy ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      );

  Widget _text(final String label, final VoidCallback? onPressed) => TextButton(
        onPressed: _busy ? null : onPressed,
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        child: Text(label),
      );

  List<Widget> _actions() {
    switch (_step) {
      case _Step.phone:
        return [
          _primary('Kodu gönder', _send),
          _text('Vazgeç', () => Navigator.of(context).pop()),
        ];
      case _Step.code:
        return [
          _primary('Doğrula ve bağla', _verify),
          _text(
            _resendIn > 0
                ? 'Kodu yeniden gönder ($_resendIn sn)'
                : 'Kodu yeniden gönder',
            _resendIn > 0 ? null : () => _send(resend: true),
          ),
          _text('Numarayı değiştir', () {
            setState(() {
              _step = _Step.phone;
              _error = null;
            });
          }),
        ];
      case _Step.inUse:
        return [
          if (_otherAccountCredential != null)
            _primary('O hesapla telefonla giriş yap', _switchAccount),
          _text('Başka bir numara dene', () {
            setState(() {
              _step = _Step.phone;
              _error = null;
              _otherAccountCredential = null;
            });
          }),
          _text('Vazgeç', () => Navigator.of(context).pop()),
        ];
    }
  }
}
