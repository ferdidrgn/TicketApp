// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getPlayersUseCase)
const getPlayersUseCaseProvider = GetPlayersUseCaseProvider._();

final class GetPlayersUseCaseProvider extends $FunctionalProvider<
    GetPlayersUseCase,
    GetPlayersUseCase,
    GetPlayersUseCase> with $Provider<GetPlayersUseCase> {
  const GetPlayersUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getPlayersUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getPlayersUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetPlayersUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetPlayersUseCase create(Ref ref) {
    return getPlayersUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetPlayersUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetPlayersUseCase>(value),
    );
  }
}

String _$getPlayersUseCaseHash() => r'6fb447412e6e858389b64d830be65cefdbea2d7c';

@ProviderFor(getPlayerByIdUseCase)
const getPlayerByIdUseCaseProvider = GetPlayerByIdUseCaseProvider._();

final class GetPlayerByIdUseCaseProvider extends $FunctionalProvider<
    GetPlayerByIdUseCase,
    GetPlayerByIdUseCase,
    GetPlayerByIdUseCase> with $Provider<GetPlayerByIdUseCase> {
  const GetPlayerByIdUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getPlayerByIdUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getPlayerByIdUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetPlayerByIdUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetPlayerByIdUseCase create(Ref ref) {
    return getPlayerByIdUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetPlayerByIdUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetPlayerByIdUseCase>(value),
    );
  }
}

String _$getPlayerByIdUseCaseHash() =>
    r'50c36b4ced873dbb7025b0243553407fc3146cd8';

@ProviderFor(players)
const playersProvider = PlayersFamily._();

final class PlayersProvider extends $FunctionalProvider<
        AsyncValue<List<Player>>, List<Player>, FutureOr<List<Player>>>
    with $FutureModifier<List<Player>>, $FutureProvider<List<Player>> {
  const PlayersProvider._(
      {required PlayersFamily super.from, required bool super.argument})
      : super(
          retry: null,
          name: r'playersProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$playersHash();

  @override
  String toString() {
    return r'playersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Player>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Player>> create(Ref ref) {
    final argument = this.argument as bool;
    return players(
      ref,
      isLimit: argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlayersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playersHash() => r'c61dc2e0c244adfd1e71b4f0aadd0f1478fd6e5d';

final class PlayersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Player>>, bool> {
  const PlayersFamily._()
      : super(
          retry: null,
          name: r'playersProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  PlayersProvider call({
    bool isLimit = false,
  }) =>
      PlayersProvider._(argument: isLimit, from: this);

  @override
  String toString() => r'playersProvider';
}

@ProviderFor(playersByIds)
const playersByIdsProvider = PlayersByIdsFamily._();

final class PlayersByIdsProvider extends $FunctionalProvider<
        AsyncValue<List<Player>>, List<Player>, FutureOr<List<Player>>>
    with $FutureModifier<List<Player>>, $FutureProvider<List<Player>> {
  const PlayersByIdsProvider._(
      {required PlayersByIdsFamily super.from,
      required List<String> super.argument})
      : super(
          retry: null,
          name: r'playersByIdsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$playersByIdsHash();

  @override
  String toString() {
    return r'playersByIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Player>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Player>> create(Ref ref) {
    final argument = this.argument as List<String>;
    return playersByIds(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlayersByIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playersByIdsHash() => r'2385e1c99ccd48e27eee4e0a2edba9c1025366e2';

final class PlayersByIdsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Player>>, List<String>> {
  const PlayersByIdsFamily._()
      : super(
          retry: null,
          name: r'playersByIdsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  PlayersByIdsProvider call(
    List<String> ids,
  ) =>
      PlayersByIdsProvider._(argument: ids, from: this);

  @override
  String toString() => r'playersByIdsProvider';
}

@ProviderFor(playerById)
const playerByIdProvider = PlayerByIdFamily._();

final class PlayerByIdProvider
    extends $FunctionalProvider<AsyncValue<Player?>, Player?, FutureOr<Player?>>
    with $FutureModifier<Player?>, $FutureProvider<Player?> {
  const PlayerByIdProvider._(
      {required PlayerByIdFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'playerByIdProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$playerByIdHash();

  @override
  String toString() {
    return r'playerByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Player?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Player?> create(Ref ref) {
    final argument = this.argument as String;
    return playerById(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerByIdHash() => r'a291914551f619ecf93263d40e00793e37c0a97c';

final class PlayerByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Player?>, String> {
  const PlayerByIdFamily._()
      : super(
          retry: null,
          name: r'playerByIdProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  PlayerByIdProvider call(
    String id,
  ) =>
      PlayerByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'playerByIdProvider';
}

/// 🔥 OYUNCU DETAY VE GÖSTERİLERİNİ BİRLEŞTİREN ANA PROVIDER

@ProviderFor(playerDetail)
const playerDetailProvider = PlayerDetailFamily._();

/// 🔥 OYUNCU DETAY VE GÖSTERİLERİNİ BİRLEŞTİREN ANA PROVIDER

final class PlayerDetailProvider extends $FunctionalProvider<
        AsyncValue<PlayerDetailState>,
        PlayerDetailState,
        FutureOr<PlayerDetailState>>
    with
        $FutureModifier<PlayerDetailState>,
        $FutureProvider<PlayerDetailState> {
  /// 🔥 OYUNCU DETAY VE GÖSTERİLERİNİ BİRLEŞTİREN ANA PROVIDER
  const PlayerDetailProvider._(
      {required PlayerDetailFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'playerDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$playerDetailHash();

  @override
  String toString() {
    return r'playerDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PlayerDetailState> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PlayerDetailState> create(Ref ref) {
    final argument = this.argument as String;
    return playerDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerDetailHash() => r'f1a41df6ca983ab3188581d581b44620354346ff';

/// 🔥 OYUNCU DETAY VE GÖSTERİLERİNİ BİRLEŞTİREN ANA PROVIDER

final class PlayerDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlayerDetailState>, String> {
  const PlayerDetailFamily._()
      : super(
          retry: null,
          name: r'playerDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 🔥 OYUNCU DETAY VE GÖSTERİLERİNİ BİRLEŞTİREN ANA PROVIDER

  PlayerDetailProvider call(
    String playerId,
  ) =>
      PlayerDetailProvider._(argument: playerId, from: this);

  @override
  String toString() => r'playerDetailProvider';
}
