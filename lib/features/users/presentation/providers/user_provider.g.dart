// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(saveUserUseCase)
const saveUserUseCaseProvider = SaveUserUseCaseProvider._();

final class SaveUserUseCaseProvider extends $FunctionalProvider<SaveUserUseCase,
    SaveUserUseCase, SaveUserUseCase> with $Provider<SaveUserUseCase> {
  const SaveUserUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'saveUserUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$saveUserUseCaseHash();

  @$internal
  @override
  $ProviderElement<SaveUserUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SaveUserUseCase create(Ref ref) {
    return saveUserUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveUserUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveUserUseCase>(value),
    );
  }
}

String _$saveUserUseCaseHash() => r'd3eae48e68d90e86229f48d6e930c7b064a48918';

@ProviderFor(getUserByIdUseCase)
const getUserByIdUseCaseProvider = GetUserByIdUseCaseProvider._();

final class GetUserByIdUseCaseProvider extends $FunctionalProvider<
    GetUserByIdUseCase,
    GetUserByIdUseCase,
    GetUserByIdUseCase> with $Provider<GetUserByIdUseCase> {
  const GetUserByIdUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getUserByIdUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getUserByIdUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetUserByIdUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetUserByIdUseCase create(Ref ref) {
    return getUserByIdUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetUserByIdUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetUserByIdUseCase>(value),
    );
  }
}

String _$getUserByIdUseCaseHash() =>
    r'451de2589cc0a8204a8830a7895e369a6b1fa45b';

@ProviderFor(deleteUserUseCase)
const deleteUserUseCaseProvider = DeleteUserUseCaseProvider._();

final class DeleteUserUseCaseProvider extends $FunctionalProvider<
    DeleteUserUseCase,
    DeleteUserUseCase,
    DeleteUserUseCase> with $Provider<DeleteUserUseCase> {
  const DeleteUserUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'deleteUserUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$deleteUserUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteUserUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeleteUserUseCase create(Ref ref) {
    return deleteUserUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteUserUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteUserUseCase>(value),
    );
  }
}

String _$deleteUserUseCaseHash() => r'a8e29c52a73c5a6d0c8bfc12f489a552afc15d87';

/// 🔥 Profil sayfası için kullanılan ana provider.
/// Auth ID'sini izler ve Firestore'dan kullanıcı verisini getirir.

@ProviderFor(userProfile)
const userProfileProvider = UserProfileProvider._();

/// 🔥 Profil sayfası için kullanılan ana provider.
/// Auth ID'sini izler ve Firestore'dan kullanıcı verisini getirir.

final class UserProfileProvider extends $FunctionalProvider<
        AsyncValue<entity.User?>, entity.User?, FutureOr<entity.User?>>
    with $FutureModifier<entity.User?>, $FutureProvider<entity.User?> {
  /// 🔥 Profil sayfası için kullanılan ana provider.
  /// Auth ID'sini izler ve Firestore'dan kullanıcı verisini getirir.
  const UserProfileProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userProfileProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userProfileHash();

  @$internal
  @override
  $FutureProviderElement<entity.User?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<entity.User?> create(Ref ref) {
    return userProfile(ref);
  }
}

String _$userProfileHash() => r'd03982487315e9c6adfb0810bf6245a5b1828520';

/// 🆔 Verilen UID'ye göre kullanıcı dökümanını asenkron getirir.
/// UI'da bilet sahibi veya admin paneli gibi yerlerde kullanılır.

@ProviderFor(userById)
const userByIdProvider = UserByIdFamily._();

/// 🆔 Verilen UID'ye göre kullanıcı dökümanını asenkron getirir.
/// UI'da bilet sahibi veya admin paneli gibi yerlerde kullanılır.

final class UserByIdProvider extends $FunctionalProvider<
        AsyncValue<entity.User?>, entity.User?, FutureOr<entity.User?>>
    with $FutureModifier<entity.User?>, $FutureProvider<entity.User?> {
  /// 🆔 Verilen UID'ye göre kullanıcı dökümanını asenkron getirir.
  /// UI'da bilet sahibi veya admin paneli gibi yerlerde kullanılır.
  const UserByIdProvider._(
      {required UserByIdFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'userByIdProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userByIdHash();

  @override
  String toString() {
    return r'userByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<entity.User?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<entity.User?> create(Ref ref) {
    final argument = this.argument as String;
    return userById(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userByIdHash() => r'c17092179095bcfc6ec36fe7f55bfb10bb6aac43';

/// 🆔 Verilen UID'ye göre kullanıcı dökümanını asenkron getirir.
/// UI'da bilet sahibi veya admin paneli gibi yerlerde kullanılır.

final class UserByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<entity.User?>, String> {
  const UserByIdFamily._()
      : super(
          retry: null,
          name: r'userByIdProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 🆔 Verilen UID'ye göre kullanıcı dökümanını asenkron getirir.
  /// UI'da bilet sahibi veya admin paneli gibi yerlerde kullanılır.

  UserByIdProvider call(
    String uid,
  ) =>
      UserByIdProvider._(argument: uid, from: this);

  @override
  String toString() => r'userByIdProvider';
}

/// Admin/Küratör kontrolü

@ProviderFor(isUserPrivileged)
const isUserPrivilegedProvider = IsUserPrivilegedProvider._();

/// Admin/Küratör kontrolü

final class IsUserPrivilegedProvider
    extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  /// Admin/Küratör kontrolü
  const IsUserPrivilegedProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'isUserPrivilegedProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$isUserPrivilegedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isUserPrivileged(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isUserPrivilegedHash() => r'58d75105f1d810c3fdee5c5cbf906e56b98cc2c6';

/// Kullanıcının toplam bilet sayısını döner.

@ProviderFor(userTicketCount)
const userTicketCountProvider = UserTicketCountProvider._();

/// Kullanıcının toplam bilet sayısını döner.

final class UserTicketCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Kullanıcının toplam bilet sayısını döner.
  const UserTicketCountProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userTicketCountProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userTicketCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return userTicketCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$userTicketCountHash() => r'6dbb2b39cad95cc6f5d7c31c1af02dac2a36c888';
