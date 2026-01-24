// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getStagesUseCase)
const getStagesUseCaseProvider = GetStagesUseCaseProvider._();

final class GetStagesUseCaseProvider extends $FunctionalProvider<
    GetStagesUseCase,
    GetStagesUseCase,
    GetStagesUseCase> with $Provider<GetStagesUseCase> {
  const GetStagesUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getStagesUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getStagesUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetStagesUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetStagesUseCase create(Ref ref) {
    return getStagesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetStagesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetStagesUseCase>(value),
    );
  }
}

String _$getStagesUseCaseHash() => r'8a9d8480374f6e132c7c20d826d6a9eada43dcfd';

@ProviderFor(getStageByIdUseCase)
const getStageByIdUseCaseProvider = GetStageByIdUseCaseProvider._();

final class GetStageByIdUseCaseProvider extends $FunctionalProvider<
    GetStagesByIdsUseCase,
    GetStagesByIdsUseCase,
    GetStagesByIdsUseCase> with $Provider<GetStagesByIdsUseCase> {
  const GetStageByIdUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getStageByIdUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getStageByIdUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetStagesByIdsUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetStagesByIdsUseCase create(Ref ref) {
    return getStageByIdUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetStagesByIdsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetStagesByIdsUseCase>(value),
    );
  }
}

String _$getStageByIdUseCaseHash() =>
    r'af004928bdee6ff05b91b4d081c1c6a32c36de48';

@ProviderFor(getSearchStageUseCase)
const getSearchStageUseCaseProvider = GetSearchStageUseCaseProvider._();

final class GetSearchStageUseCaseProvider extends $FunctionalProvider<
    GetSearchStageUseCase,
    GetSearchStageUseCase,
    GetSearchStageUseCase> with $Provider<GetSearchStageUseCase> {
  const GetSearchStageUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getSearchStageUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getSearchStageUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetSearchStageUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetSearchStageUseCase create(Ref ref) {
    return getSearchStageUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetSearchStageUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetSearchStageUseCase>(value),
    );
  }
}

String _$getSearchStageUseCaseHash() =>
    r'6c8bc1ea5df39c3a93eb355e7e26c3c0d3fdb274';

/// 🔥 TÜM SAHNELERİ ÇEKER
/// Kullanım: ref.watch(stagesProvider)

@ProviderFor(stages)
const stagesProvider = StagesFamily._();

/// 🔥 TÜM SAHNELERİ ÇEKER
/// Kullanım: ref.watch(stagesProvider)

final class StagesProvider extends $FunctionalProvider<AsyncValue<List<Stage>>,
        List<Stage>, FutureOr<List<Stage>>>
    with $FutureModifier<List<Stage>>, $FutureProvider<List<Stage>> {
  /// 🔥 TÜM SAHNELERİ ÇEKER
  /// Kullanım: ref.watch(stagesProvider)
  const StagesProvider._(
      {required StagesFamily super.from, required bool super.argument})
      : super(
          retry: null,
          name: r'stagesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$stagesHash();

  @override
  String toString() {
    return r'stagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Stage>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Stage>> create(Ref ref) {
    final argument = this.argument as bool;
    return stages(
      ref,
      isLimit: argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stagesHash() => r'b1f72a63f03da629a8f0197038cbc3613454c6f0';

/// 🔥 TÜM SAHNELERİ ÇEKER
/// Kullanım: ref.watch(stagesProvider)

final class StagesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Stage>>, bool> {
  const StagesFamily._()
      : super(
          retry: null,
          name: r'stagesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 🔥 TÜM SAHNELERİ ÇEKER
  /// Kullanım: ref.watch(stagesProvider)

  StagesProvider call({
    required bool isLimit,
  }) =>
      StagesProvider._(argument: isLimit, from: this);

  @override
  String toString() => r'stagesProvider';
}

/// 🆔 ID LİSTESİNE GÖRE SAHNELERİ ÇEKER
/// Kullanım: ref.watch(stagesByIdsProvider(['id1', 'id2']))

@ProviderFor(stagesByIds)
const stagesByIdsProvider = StagesByIdsFamily._();

/// 🆔 ID LİSTESİNE GÖRE SAHNELERİ ÇEKER
/// Kullanım: ref.watch(stagesByIdsProvider(['id1', 'id2']))

final class StagesByIdsProvider extends $FunctionalProvider<
        AsyncValue<List<Stage>>, List<Stage>, FutureOr<List<Stage>>>
    with $FutureModifier<List<Stage>>, $FutureProvider<List<Stage>> {
  /// 🆔 ID LİSTESİNE GÖRE SAHNELERİ ÇEKER
  /// Kullanım: ref.watch(stagesByIdsProvider(['id1', 'id2']))
  const StagesByIdsProvider._(
      {required StagesByIdsFamily super.from,
      required List<String> super.argument})
      : super(
          retry: null,
          name: r'stagesByIdsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$stagesByIdsHash();

  @override
  String toString() {
    return r'stagesByIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Stage>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Stage>> create(Ref ref) {
    final argument = this.argument as List<String>;
    return stagesByIds(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StagesByIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stagesByIdsHash() => r'c3598e527dd9587a6ca5726e4bdf091590a46701';

/// 🆔 ID LİSTESİNE GÖRE SAHNELERİ ÇEKER
/// Kullanım: ref.watch(stagesByIdsProvider(['id1', 'id2']))

final class StagesByIdsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Stage>>, List<String>> {
  const StagesByIdsFamily._()
      : super(
          retry: null,
          name: r'stagesByIdsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 🆔 ID LİSTESİNE GÖRE SAHNELERİ ÇEKER
  /// Kullanım: ref.watch(stagesByIdsProvider(['id1', 'id2']))

  StagesByIdsProvider call(
    List<String> ids,
  ) =>
      StagesByIdsProvider._(argument: ids, from: this);

  @override
  String toString() => r'stagesByIdsProvider';
}

/// 🔍 SAHNE ARAMA (Manuel Tetiklenen State)
/// Arama sonuçlarını tutmak için bir Notifier kullanıyoruz.

@ProviderFor(StageSearch)
const stageSearchProvider = StageSearchProvider._();

/// 🔍 SAHNE ARAMA (Manuel Tetiklenen State)
/// Arama sonuçlarını tutmak için bir Notifier kullanıyoruz.
final class StageSearchProvider
    extends $AsyncNotifierProvider<StageSearch, List<Stage>> {
  /// 🔍 SAHNE ARAMA (Manuel Tetiklenen State)
  /// Arama sonuçlarını tutmak için bir Notifier kullanıyoruz.
  const StageSearchProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'stageSearchProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$stageSearchHash();

  @$internal
  @override
  StageSearch create() => StageSearch();
}

String _$stageSearchHash() => r'e9771a56e3c00604d472513749ae6bd703c18927';

/// 🔍 SAHNE ARAMA (Manuel Tetiklenen State)
/// Arama sonuçlarını tutmak için bir Notifier kullanıyoruz.

abstract class _$StageSearch extends $AsyncNotifier<List<Stage>> {
  FutureOr<List<Stage>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Stage>>, List<Stage>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Stage>>, List<Stage>>,
        AsyncValue<List<Stage>>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
