// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'processing_seats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProcessingSeats)
const processingSeatsProvider = ProcessingSeatsProvider._();

final class ProcessingSeatsProvider
    extends $NotifierProvider<ProcessingSeats, Set<String>> {
  const ProcessingSeatsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'processingSeatsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$processingSeatsHash();

  @$internal
  @override
  ProcessingSeats create() => ProcessingSeats();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$processingSeatsHash() => r'5366c93b3ee6840cdff515c5a114567a73ebab89';

abstract class _$ProcessingSeats extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<Set<String>, Set<String>>, Set<String>, Object?, Object?>;
    element.handleValue(ref, created);
  }
}
