import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for network status checks.
final networkServiceProvider = Provider<NetworkService>((ref) {
  return const NetworkService();
});

/// Lightweight network helper to detect Wi-Fi connections.
class NetworkService {
  const NetworkService();

  /// Best-effort Wi-Fi detection without extra dependencies.
  Future<bool> isWifiConnected() async {
    if (kIsWeb) return true;

    try {
      final interfaces = await NetworkInterface.list(includeLoopback: false);
      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        if (name.contains('wlan') || name.contains('wifi') || name == 'en0') {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('NetworkService: Unable to detect Wi-Fi: $e');
      return true;
    }
  }
}
