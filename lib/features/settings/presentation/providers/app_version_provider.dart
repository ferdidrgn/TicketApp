import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Cihaza GERÇEKTEN yüklenmiş uygulamanın sürüm/derleme numarası —
/// `pubspec.yaml`'daki `version:` satırından derleme zamanında üretilir
/// (`package_info_plus`), Settings ekranındaki eski sabit "Versiyon 1.0.4"
/// metninin yerine. Bu dosya klasik `FutureProvider` API'siyle yazıldı
/// (bu sandbox'ta `build_runner` çalışmadığı için yeni bir `@riverpod`
/// sınıfı eklenmiyor).
final appVersionLabelProvider = FutureProvider<String>((final ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});
