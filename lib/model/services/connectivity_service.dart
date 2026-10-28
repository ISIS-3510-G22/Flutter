import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _connectivity = Connectivity();

  Future<bool> isOnline() async =>
      _hasNetwork(await _connectivity.checkConnectivity());

  Stream<bool> get onChange =>
      _connectivity.onConnectivityChanged.map(_hasNetwork);

  bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
