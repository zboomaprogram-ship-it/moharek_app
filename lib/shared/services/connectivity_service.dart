import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { isConnected, isDisconnected }

class ConnectivityService {
  final _connectivity = Connectivity();
  final _controller = StreamController<ConnectivityStatus>.broadcast();

  Stream<ConnectivityStatus> get connectivityStream => _controller.stream;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((results) {
      // connectivity_plus 6.x returns List<ConnectivityResult>
      if (results.contains(ConnectivityResult.none)) {
        _controller.add(ConnectivityStatus.isDisconnected);
      } else {
        _controller.add(ConnectivityStatus.isConnected);
      }
    });
  }

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  return ref.watch(connectivityServiceProvider).connectivityStream;
});
