// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LocaleController)
const localeControllerProvider = LocaleControllerProvider._();

final class LocaleControllerProvider
    extends $AsyncNotifierProvider<LocaleController, Locale> {
  const LocaleControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'localeControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$localeControllerHash();

  @$internal
  @override
  LocaleController create() => LocaleController();
}

String _$localeControllerHash() => r'b14857c6096b4f3638bc4946e1a963ddd36eca26';

abstract class _$LocaleController extends $AsyncNotifier<Locale> {
  FutureOr<Locale> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<Locale>, Locale>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<Locale>, Locale>,
        AsyncValue<Locale>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
