import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/player/get_player_by_id_use_case_impl.dart';
import '../../../domain/useCase/player/get_players_use_case_impl.dart';
import '../../repository/player/player_repository_provider.dart';
import 'player_notifier.dart';
import 'player_state.dart';

/// Ana Player ViewModel provider'ı
final playerProvider = NotifierProvider.autoDispose<PlayerNotifier, PlayerState>(
  PlayerNotifier.new,
);

/// ID ile oyuncu getirme use case provider'ı
final getPlayerByIdUseCaseProvider = Provider<GetPlayerByIdUseCase>(
  (final ref) => GetPlayerByIdUseCaseImpl(ref.watch(playerRepositoryProvider)),
);

/// Tüm oyuncuları getirme use case provider'ı
final getPlayersUseCaseProvider = Provider<GetPlayersUseCase>(
  (final ref) => GetPlayersUseCaseImpl(ref.watch(playerRepositoryProvider)),
);

// ==============================================================================
// USAGE EXAMPLES
// ==============================================================================

/// Örnek 1: ConsumerWidget ile state dinleme
/// ```dart
/// class PlayerListScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final playerState = ref.watch(playerProvider);
///
///     if (playerState.isLoading) {
///       return const CircularProgressIndicator();
///     }
///
///     if (playerState.hasError) {
///       return Text(playerState.errorMessage!);
///     }
///
///     return ListView.builder(
///       itemCount: playerState.dataList?.length ?? 0,
///       itemBuilder: (context, index) {
///         final player = playerState.dataList![index];
///         return ListTile(title: Text(player.name));
///       },
///     );
///   }
/// }
/// ```

/// Örnek 2: Button ile veri yükleme
/// ```dart
/// ElevatedButton(
///   onPressed: () {
///     ref.read(playerProvider.notifier).loadPlayers(shouldLimit: false);
///   },
///   child: const Text('Oyuncuları Yükle'),
/// )
/// ```

/// Örnek 3: Pull-to-refresh implementasyonu
/// ```dart
/// RefreshIndicator(
///   onRefresh: () async {
///     await ref.read(playerProvider.notifier).refresh();
///   },
///   child: PlayerListView(),
/// )
/// ```

/// Örnek 4: Belirli oyuncuları ID ile yükleme
/// ```dart
/// final playerIds = ['player1', 'player2', 'player3'];
/// ref.read(playerProvider.notifier).loadPlayersByIds(playerIds);
/// ```

/// Örnek 5: Logout sonrası state temizleme
/// ```dart
/// void logout() {
///   ref.read(playerProvider.notifier).clearPlayers();
///   Navigator.pushReplacementNamed(context, '/login');
/// }
/// ```

/// Örnek 6: State'ten oyuncu kontrolü (Extension kullanımı)
/// ```dart
/// final playerState = ref.watch(playerProvider);
///
/// if (playerState.hasPlayer('player123')) {
///   final player = playerState.getPlayerById('player123');
///   print('Oyuncu bulundu: ${player.name}');
/// }
///
/// print('Toplam oyuncu sayısı: ${playerState.playerCount}');
/// ```

/// Örnek 7: initState'te otomatik veri yükleme
/// ```dart
/// class PlayerScreen extends ConsumerStatefulWidget {
///   @override
///   ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
/// }
///
/// class _PlayerScreenState extends ConsumerState<PlayerScreen> {
///   @override
///   void initState() {
///     super.initState();
///     WidgetsBinding.instance.addPostFrameCallback((_) {
///       ref.read(playerProvider.notifier).loadPlayers(shouldLimit: true);
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     final playerState = ref.watch(playerProvider);
///     return Scaffold(
///       appBar: AppBar(title: const Text('Oyuncular')),
///       body: /* ... */,
///     );
///   }
/// }
/// ```

/// Örnek 8: Error durumunda SnackBar gösterme
/// ```dart
/// ref.listen<PlayerState>(
///   playerProvider,
///   (previous, next) {
///     if (next.hasError) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(
///           content: Text(next.errorMessage!),
///           backgroundColor: Colors.red,
///         ),
///       );
///     }
///   },
/// );
/// ```

/// Örnek 9: Loading overlay ile kullanım
/// ```dart
/// Widget build(BuildContext context, WidgetRef ref) {
///   final playerState = ref.watch(playerProvider);
///
///   return Stack(
///     children: [
///       PlayerListView(players: playerState.dataList ?? []),
///       if (playerState.isLoading)
///         Container(
///           color: Colors.black26,
///           child: const Center(
///             child: CircularProgressIndicator(),
///           ),
///         ),
///     ],
///   );
/// }
/// ```

/// Örnek 10: Empty state kontrolü
/// ```dart
/// Widget build(BuildContext context, WidgetRef ref) {
///   final playerState = ref.watch(playerProvider);
///
///   if (playerState.isLoading) {
///     return const LoadingWidget();
///   }
///
///   if (playerState.hasError) {
///     return ErrorWidget(message: playerState.errorMessage!);
///   }
///
///   if (playerState.isListEmpty) {
///     return const EmptyStateWidget(
///       icon: Icons.person_off,
///       message: 'Henüz oyuncu yok',
///     );
///   }
///
///   return PlayerListView(players: playerState.dataList!);
/// }
/// ```

/// Örnek 11: Internet bağlantısı geri geldiğinde otomatik retry
/// ```dart
/// // BaseNotifier otomatik hallediyor!
/// // Internet kesildiğinde: state.errorMessage = "İnternet Bağlantısı Yok!"
/// // Internet geri geldiğinde: reloadData() otomatik çağrılır (2 saniye debounce)
///
/// class PlayerListScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final playerState = ref.watch(playerProvider);
///
///     // Offline durumunda özel UI
///     if (playerState.errorMessage == 'İnternet Bağlantısı Yok!') {
///       return Center(
///         child: Column(
///           mainAxisAlignment: MainAxisAlignment.center,
///           children: [
///             const Icon(Icons.wifi_off, size: 64),
///             const Text('Bağlantı bekleniyor...'),
///             const Text('Geri gelince otomatik yüklenecek'),
///           ],
///         ),
///       );
///     }
///
///     return PlayerListView();
///   }
/// }
/// ```

/// Örnek 12: Kendi ViewModel'inizi oluşturma
/// ```dart
/// // 1. State sınıfı
/// class MyState extends LoadableState<MyData, List<MyData>> {
///   const MyState({
///     MyData? data,
///     List<MyData>? dataList,
///     super.isLoading,
///     super.errorMessage,
///   }) : super(dataSingle: data, dataList: dataList);
///
///   @override
///   MyState copyWith({...}) { /* implementation */ }
/// }
///
/// // 2. Notifier sınıfı
/// class MyNotifier extends BaseNotifierWithNetworkChecker<MyState> {
///   @override
///   MyState initialState() => const MyState();
///
///   @override
///   void reloadData() => loadData();
///
///   Future<void> loadData() async {
///     await executeWithInternetCheck(
///       () => ref.read(myUseCaseProvider).call(),
///       onSuccess: (data) => state = state.copyWith(data: data),
///     );
///   }
/// }
///
/// // 3. Provider
/// final myProvider = NotifierProvider<MyNotifier, MyState>(
///   MyNotifier.new,
/// );
/// ```
