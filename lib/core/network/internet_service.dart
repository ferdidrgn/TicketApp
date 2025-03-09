// Singleton for Internet Connection
import 'package:internet_connection_checker/internet_connection_checker.dart';

class InternetService {
  InternetService._();

  static final InternetService instance = InternetService._();

  final InternetConnectionChecker _connectionChecker =
      InternetConnectionChecker.instance;

  Stream<InternetConnectionStatus> get connectionStream =>
      _connectionChecker.onStatusChange;

  Future<bool> get isConnected async => _connectionChecker.hasConnection;
}
