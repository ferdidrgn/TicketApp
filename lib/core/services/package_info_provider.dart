import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Gerçek çalışan uygulama sürümünü (pubspec.yaml'daki version) verir —
/// böylece ayarlar/hakkında gibi ekranlarda elle yazılmış, zamanla
/// pubspec'ten kopan sabit bir sürüm metni yerine gerçek değer gösterilir.
final packageInfoProvider =
    FutureProvider<PackageInfo>((final ref) => PackageInfo.fromPlatform());
