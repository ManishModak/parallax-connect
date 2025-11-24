import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Provider for current connectivity status stream
final connectivityStatusProvider = StreamProvider<ConnectivityResult>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

/// Service to monitor network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream of connectivity changes
  Stream<ConnectivityResult> get onConnectivityChanged => _connectivity
      .onConnectivityChanged
      .map((List<ConnectivityResult> results) {
        // Return the first result or none if empty
        return results.isNotEmpty ? results.first : ConnectivityResult.none;
      });

  /// Check current connectivity status
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && results.first != ConnectivityResult.none;
  }

  /// Check if connected and has internet (for cloud mode)
  Future<bool> get hasInternetConnection async {
    final results = await _connectivity.checkConnectivity();
    if (results.isEmpty || results.first == ConnectivityResult.none) {
      return false;
    }

    // Check for mobile or wifi connection
    return results.first == ConnectivityResult.wifi ||
        results.first == ConnectivityResult.mobile;
  }

  /// Get connectivity result type
  Future<ConnectivityResult> get connectivityResult async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty ? results.first : ConnectivityResult.none;
  }
}
