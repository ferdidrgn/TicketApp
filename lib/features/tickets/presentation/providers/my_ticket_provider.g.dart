// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_ticket_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ==============================================================================
/// 2. USE CASE PROVIDERS (Dependency Injection)
/// Repository'yi UseCase'lere burada bağlıyoruz.
/// ==============================================================================

@ProviderFor(getTicketByIdUseCase)
const getTicketByIdUseCaseProvider = GetTicketByIdUseCaseProvider._();

/// ==============================================================================
/// 2. USE CASE PROVIDERS (Dependency Injection)
/// Repository'yi UseCase'lere burada bağlıyoruz.
/// ==============================================================================

final class GetTicketByIdUseCaseProvider extends $FunctionalProvider<
    GetTicketsByIdUseCase,
    GetTicketsByIdUseCase,
    GetTicketsByIdUseCase> with $Provider<GetTicketsByIdUseCase> {
  /// ==============================================================================
  /// 2. USE CASE PROVIDERS (Dependency Injection)
  /// Repository'yi UseCase'lere burada bağlıyoruz.
  /// ==============================================================================
  const GetTicketByIdUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getTicketByIdUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getTicketByIdUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetTicketsByIdUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetTicketsByIdUseCase create(Ref ref) {
    return getTicketByIdUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetTicketsByIdUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetTicketsByIdUseCase>(value),
    );
  }
}

String _$getTicketByIdUseCaseHash() =>
    r'de2bbbf8cba6713760e5f3bef0c52efc154bdf59';

@ProviderFor(getTicketByCustomerIdUseCase)
const getTicketByCustomerIdUseCaseProvider =
    GetTicketByCustomerIdUseCaseProvider._();

final class GetTicketByCustomerIdUseCaseProvider extends $FunctionalProvider<
        GetTicketsByCustomerIdUseCase,
        GetTicketsByCustomerIdUseCase,
        GetTicketsByCustomerIdUseCase>
    with $Provider<GetTicketsByCustomerIdUseCase> {
  const GetTicketByCustomerIdUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getTicketByCustomerIdUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getTicketByCustomerIdUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetTicketsByCustomerIdUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetTicketsByCustomerIdUseCase create(Ref ref) {
    return getTicketByCustomerIdUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetTicketsByCustomerIdUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<GetTicketsByCustomerIdUseCase>(value),
    );
  }
}

String _$getTicketByCustomerIdUseCaseHash() =>
    r'd7ef730590fcac8b7c35adb8f47cd4ea80c69559';

@ProviderFor(createTicketUseCase)
const createTicketUseCaseProvider = CreateTicketUseCaseProvider._();

final class CreateTicketUseCaseProvider extends $FunctionalProvider<
    CreateTicketUseCase,
    CreateTicketUseCase,
    CreateTicketUseCase> with $Provider<CreateTicketUseCase> {
  const CreateTicketUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'createTicketUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$createTicketUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreateTicketUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CreateTicketUseCase create(Ref ref) {
    return createTicketUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateTicketUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateTicketUseCase>(value),
    );
  }
}

String _$createTicketUseCaseHash() =>
    r'7d2aac21435eec2b9eadd22a4b265e654f258ed9';

/// ==============================================================================
/// 3. COMPOSITE PROVIDER (MAIN LOGIC)
/// Kullanıcının biletlerini çeker, diğer modüllerden (Show, Event, Stage)
/// verileri paralel olarak getirir ve birleştirir.
/// ==============================================================================

@ProviderFor(myTickets)
const myTicketsProvider = MyTicketsFamily._();

/// ==============================================================================
/// 3. COMPOSITE PROVIDER (MAIN LOGIC)
/// Kullanıcının biletlerini çeker, diğer modüllerden (Show, Event, Stage)
/// verileri paralel olarak getirir ve birleştirir.
/// ==============================================================================

final class MyTicketsProvider extends $FunctionalProvider<
        AsyncValue<List<DetailedTicket>>,
        List<DetailedTicket>,
        FutureOr<List<DetailedTicket>>>
    with
        $FutureModifier<List<DetailedTicket>>,
        $FutureProvider<List<DetailedTicket>> {
  /// ==============================================================================
  /// 3. COMPOSITE PROVIDER (MAIN LOGIC)
  /// Kullanıcının biletlerini çeker, diğer modüllerden (Show, Event, Stage)
  /// verileri paralel olarak getirir ve birleştirir.
  /// ==============================================================================
  const MyTicketsProvider._(
      {required MyTicketsFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'myTicketsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$myTicketsHash();

  @override
  String toString() {
    return r'myTicketsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<DetailedTicket>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<DetailedTicket>> create(Ref ref) {
    final argument = this.argument as String;
    return myTickets(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MyTicketsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myTicketsHash() => r'5a630fdf756c115bac4057075996793317de46d7';

/// ==============================================================================
/// 3. COMPOSITE PROVIDER (MAIN LOGIC)
/// Kullanıcının biletlerini çeker, diğer modüllerden (Show, Event, Stage)
/// verileri paralel olarak getirir ve birleştirir.
/// ==============================================================================

final class MyTicketsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<DetailedTicket>>, String> {
  const MyTicketsFamily._()
      : super(
          retry: null,
          name: r'myTicketsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// ==============================================================================
  /// 3. COMPOSITE PROVIDER (MAIN LOGIC)
  /// Kullanıcının biletlerini çeker, diğer modüllerden (Show, Event, Stage)
  /// verileri paralel olarak getirir ve birleştirir.
  /// ==============================================================================

  MyTicketsProvider call(
    String userId,
  ) =>
      MyTicketsProvider._(argument: userId, from: this);

  @override
  String toString() => r'myTicketsProvider';
}
