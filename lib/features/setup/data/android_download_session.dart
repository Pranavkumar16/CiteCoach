import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Keeps the existing resumable transfer foreground while Android is minimized.
class AndroidDownloadSession {
  AndroidDownloadSession({bool? android, MethodChannel? channel})
      : _android = android ?? Platform.isAndroid,
        _channel = channel ?? const MethodChannel('com.citecoach/download');
  final bool _android;
  final MethodChannel _channel;
  bool _started = false;
  DateTime? _lastUpdate;

  Future<void> start() async {
    if (!_android || _started) return;
    await _channel.invokeMethod<void>('start').timeout(const Duration(seconds: 5));
    _started = true;
    _lastUpdate = null;
  }

  Future<void> update(double progress, {String? message}) async {
    if (!_android || !_started) return;
    final now = DateTime.now();
    if (message == null && _lastUpdate != null &&
        now.difference(_lastUpdate!).inMilliseconds < 1000) return;
    _lastUpdate = now;
    try {
      final percent = (progress * 100).round().clamp(0, 100);
      await _channel.invokeMethod<void>('update', {
        'percent': percent,
        'message': message ?? '$percent% · Tap to return to CiteCoach',
      }).timeout(const Duration(seconds: 3));
    } on PlatformException {
      // Notification refresh failure must not discard the transfer.
    } on TimeoutException {
    } on MissingPluginException {
    }
  }

  Future<void> stop() async {
    if (!_android || !_started) return;
    _started = false;
    try {
      await _channel.invokeMethod<void>('stop').timeout(const Duration(seconds: 3));
    } on PlatformException {
    } on TimeoutException {
    } on MissingPluginException {
    }
  }
}
