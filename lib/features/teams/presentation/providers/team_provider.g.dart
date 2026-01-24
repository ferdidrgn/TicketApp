// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getTeamsUseCase)
const getTeamsUseCaseProvider = GetTeamsUseCaseProvider._();

final class GetTeamsUseCaseProvider extends $FunctionalProvider<GetTeamsUseCase,
    GetTeamsUseCase, GetTeamsUseCase> with $Provider<GetTeamsUseCase> {
  const GetTeamsUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getTeamsUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getTeamsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetTeamsUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetTeamsUseCase create(Ref ref) {
    return getTeamsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetTeamsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetTeamsUseCase>(value),
    );
  }
}

String _$getTeamsUseCaseHash() => r'22004b4c50fd7f2b0e20651c0779c0a419604e87';

@ProviderFor(getTeamByIdUseCase)
const getTeamByIdUseCaseProvider = GetTeamByIdUseCaseProvider._();

final class GetTeamByIdUseCaseProvider extends $FunctionalProvider<
    GetTeamByIdUseCase,
    GetTeamByIdUseCase,
    GetTeamByIdUseCase> with $Provider<GetTeamByIdUseCase> {
  const GetTeamByIdUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getTeamByIdUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getTeamByIdUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetTeamByIdUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetTeamByIdUseCase create(Ref ref) {
    return getTeamByIdUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetTeamByIdUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetTeamByIdUseCase>(value),
    );
  }
}

String _$getTeamByIdUseCaseHash() =>
    r'455b45421c260189c3639150f423ff05022c22d1';

/// 🔥 TÜM TAKIMLARI ÇEKER
/// Parametre: isLimit (bool) -> true ise son 20 kaydı getirir.

@ProviderFor(teams)
const teamsProvider = TeamsFamily._();

/// 🔥 TÜM TAKIMLARI ÇEKER
/// Parametre: isLimit (bool) -> true ise son 20 kaydı getirir.

final class TeamsProvider extends $FunctionalProvider<AsyncValue<List<Team>>,
        List<Team>, FutureOr<List<Team>>>
    with $FutureModifier<List<Team>>, $FutureProvider<List<Team>> {
  /// 🔥 TÜM TAKIMLARI ÇEKER
  /// Parametre: isLimit (bool) -> true ise son 20 kaydı getirir.
  const TeamsProvider._(
      {required TeamsFamily super.from, required bool super.argument})
      : super(
          retry: null,
          name: r'teamsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$teamsHash();

  @override
  String toString() {
    return r'teamsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Team>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Team>> create(Ref ref) {
    final argument = this.argument as bool;
    return teams(
      ref,
      isLimit: argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TeamsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamsHash() => r'c64519e604d2b16edbc72a3bb1de86984a92ed35';

/// 🔥 TÜM TAKIMLARI ÇEKER
/// Parametre: isLimit (bool) -> true ise son 20 kaydı getirir.

final class TeamsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Team>>, bool> {
  const TeamsFamily._()
      : super(
          retry: null,
          name: r'teamsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 🔥 TÜM TAKIMLARI ÇEKER
  /// Parametre: isLimit (bool) -> true ise son 20 kaydı getirir.

  TeamsProvider call({
    required bool isLimit,
  }) =>
      TeamsProvider._(argument: isLimit, from: this);

  @override
  String toString() => r'teamsProvider';
}

/// 🆔 TEK BİR TAKIM VE DETAYLARINI ÇEKER (Composite)
/// Bu provider, bir takımın kendisini ve ilişkili gösterilerini (Show) paketler.

@ProviderFor(teamDetail)
const teamDetailProvider = TeamDetailFamily._();

/// 🆔 TEK BİR TAKIM VE DETAYLARINI ÇEKER (Composite)
/// Bu provider, bir takımın kendisini ve ilişkili gösterilerini (Show) paketler.

final class TeamDetailProvider extends $FunctionalProvider<
        AsyncValue<TeamDetailState>, TeamDetailState, FutureOr<TeamDetailState>>
    with $FutureModifier<TeamDetailState>, $FutureProvider<TeamDetailState> {
  /// 🆔 TEK BİR TAKIM VE DETAYLARINI ÇEKER (Composite)
  /// Bu provider, bir takımın kendisini ve ilişkili gösterilerini (Show) paketler.
  const TeamDetailProvider._(
      {required TeamDetailFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'teamDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$teamDetailHash();

  @override
  String toString() {
    return r'teamDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TeamDetailState> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TeamDetailState> create(Ref ref) {
    final argument = this.argument as String;
    return teamDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TeamDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamDetailHash() => r'4f2d9bb967bd846db44546d564ce82ef6f8ec7e4';

/// 🆔 TEK BİR TAKIM VE DETAYLARINI ÇEKER (Composite)
/// Bu provider, bir takımın kendisini ve ilişkili gösterilerini (Show) paketler.

final class TeamDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TeamDetailState>, String> {
  const TeamDetailFamily._()
      : super(
          retry: null,
          name: r'teamDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 🆔 TEK BİR TAKIM VE DETAYLARINI ÇEKER (Composite)
  /// Bu provider, bir takımın kendisini ve ilişkili gösterilerini (Show) paketler.

  TeamDetailProvider call(
    String teamId,
  ) =>
      TeamDetailProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamDetailProvider';
}
