// Singleton for Internet Connection
import 'package:internet_connection_checker/internet_connection_checker.dart';

abstract class InternetServiceStream {
  Stream<InternetConnectionStatus> get connectionStream;

  Future<bool> get isConnected;
}

class InternetService implements InternetServiceStream {
  InternetService._();

  static final InternetService instance = InternetService._();

  final InternetConnectionChecker _connectionChecker =
      InternetConnectionChecker.instance;

  @override
  Stream<InternetConnectionStatus> get connectionStream =>
      _connectionChecker.onStatusChange;

  @override
  Future<bool> get isConnected async => _connectionChecker.hasConnection;
}
