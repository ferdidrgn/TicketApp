import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Kısa sinüs tonları üretir (ayrı ses dosyası gerekmez).
/// Enstrüman sahnesinde dokunuşa anlık ses + hafif haptic verir.
class StageTonePlayer {
  StageTonePlayer._();
  static final StageTonePlayer instance = StageTonePlayer._();

  final AudioPlayer _player = AudioPlayer();
  int _note = 0;

  static const List<double> _scale = [
    261.63, // C4
    293.66, // D4
    329.63, // E4
    349.23, // F4
    392.00, // G4
    440.00, // A4
    493.88, // B4
    523.25, // C5
  ];

  Future<void> playNext({final bool piano = false}) async {
    HapticFeedback.selectionClick();
    final double freq = _scale[_note % _scale.length] * (piano ? 1.0 : 0.75);
    _note++;
    final Uint8List wav = _sineWav(freq: freq, ms: piano ? 220 : 160);
    try {
      await _player.stop();
      await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
    } catch (_) {
      // Ses engelliyse sessizce geç; görsel animasyon sürer.
    }
  }

  Future<void> playAt(final int index, {final bool piano = false}) async {
    HapticFeedback.lightImpact();
    final double freq =
        _scale[index.clamp(0, _scale.length - 1)] * (piano ? 1.0 : 0.8);
    final Uint8List wav = _sineWav(freq: freq, ms: piano ? 260 : 180);
    try {
      await _player.stop();
      await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player.dispose();
  }

  static Uint8List _sineWav({
    required final double freq,
    required final int ms,
    final int sampleRate = 22050,
  }) {
    final int n = (sampleRate * ms / 1000).round();
    final ByteData data = ByteData(44 + n * 2);
    void str(final int o, final String s) {
      for (int i = 0; i < s.length; i++) {
        data.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, n * 2, Endian.little);

    for (int i = 0; i < n; i++) {
      final double t = i / sampleRate;
      final double env = math.min(1.0, i / 400.0) *
          math.min(1.0, (n - i) / 1200.0);
      final double sample = math.sin(2 * math.pi * freq * t) * env * 0.35;
      data.setInt16(44 + i * 2, (sample * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }
}
