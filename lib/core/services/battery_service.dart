import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the battery service.
final batteryServiceProvider = Provider<BatteryService>((ref) {
  return BatteryService();
});

/// Provider for the low power mode state.
final lowPowerModeProvider = StateNotifierProvider<LowPowerModeNotifier, bool>((ref) {
  final service = ref.watch(batteryServiceProvider);
  return LowPowerModeNotifier(service);
});

/// Service for battery monitoring and low power mode logic.
class BatteryService {
  final Battery _battery = Battery();
  
  /// Check if low power mode should be enabled.
  Future<bool> shouldUseLowPowerMode() async {
    final prefs = await SharedPreferences.getInstance();
    final manuallyEnabled = prefs.getBool('low_power_mode') ?? false;
    
    if (manuallyEnabled) return true;
    
    try {
      final batteryLevel = await _battery.batteryLevel;
      return batteryLevel < 20;
    } catch (e) {
      // If battery status fails (e.g. simulator), assume false
      return false;
    }
  }

  /// Set manual low power mode preference.
  Future<void> setManualLowPowerMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('low_power_mode', enabled);
  }

  /// Get manual low power mode preference.
  Future<bool> getManualLowPowerMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('low_power_mode') ?? false;
  }
}

/// State notifier for low power mode.
class LowPowerModeNotifier extends StateNotifier<bool> {
  LowPowerModeNotifier(this._service) : super(false) {
    _init();
  }

  final BatteryService _service;

  Future<void> _init() async {
    state = await _service.shouldUseLowPowerMode();
  }

  Future<void> toggle(bool enabled) async {
    await _service.setManualLowPowerMode(enabled);
    // Re-evaluate (manual override takes precedence)
    state = await _service.shouldUseLowPowerMode();
  }
  
  Future<void> refresh() async {
    state = await _service.shouldUseLowPowerMode();
  }
}
