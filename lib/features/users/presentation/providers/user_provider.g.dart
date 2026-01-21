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

/// 🔥 Uygulamanın en kritik provider'ı. Auth UID'sini izler ve
/// Firestore dökümanını (entity.User) asenkron döndürür.

@ProviderFor(currentUser)
const currentUserProvider = CurrentUserProvider._();

/// 🔥 Uygulamanın en kritik provider'ı. Auth UID'sini izler ve
/// Firestore dökümanını (entity.User) asenkron döndürür.

final class CurrentUserProvider extends $FunctionalProvider<
        AsyncValue<entity.User?>, entity.User?, FutureOr<entity.User?>>
    with $FutureModifier<entity.User?>, $FutureProvider<entity.User?> {
  /// 🔥 Uygulamanın en kritik provider'ı. Auth UID'sini izler ve
  /// Firestore dökümanını (entity.User) asenkron döndürür.
  const CurrentUserProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentUserProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $FutureProviderElement<entity.User?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<entity.User?> create(Ref ref) {
    return currentUser(ref);
  }
}

String _$currentUserHash() => r'792aa23a940977e131300a3c158d3a23c12d96b7';

/// Kullanıcının Admin veya Küratör olup olmadığını kontrol eder.

@ProviderFor(isUserPrivileged)
const isUserPrivilegedProvider = IsUserPrivilegedProvider._();

/// Kullanıcının Admin veya Küratör olup olmadığını kontrol eder.

final class IsUserPrivilegedProvider
    extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  /// Kullanıcının Admin veya Küratör olup olmadığını kontrol eder.
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

String _$isUserPrivilegedHash() => r'cdc0ae68b3f0c49281533883cbdec985131c1842';

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

String _$userTicketCountHash() => r'ab46631a3448354e184c868be7d46de980257583';
