import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citecoach/core/services/storage_service.dart';

void main() {
  late StorageService storageService;

  setUp(() async {
    // Initialize with mock values
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
  });

  group('StorageService - Setup State', () {
    test('initial setup state is incomplete', () {
      expect(storageService.isSetupCompleted, isFalse);
      expect(storageService.isPrivacyAccepted, isFalse);
      expect(storageService.isModelDownloaded, isFalse);
    });

    test('set and get setup completed', () async {
      await storageService.setSetupCompleted(true);
      expect(storageService.isSetupCompleted, isTrue);
    });

    test('set and get privacy accepted', () async {
      await storageService.setPrivacyAccepted(true);
      expect(storageService.isPrivacyAccepted, isTrue);
    });

    test('set and get model downloaded', () async {
      await storageService.setModelDownloaded(true);
      expect(storageService.isModelDownloaded, isTrue);
    });

    test('set and get model download progress', () async {
      await storageService.setModelDownloadProgress(0.5);
      expect(storageService.modelDownloadProgress, equals(0.5));
    });

    test('set and get model version', () async {
      await storageService.setModelVersion('gemma-2b-v1');
      expect(storageService.modelVersion, equals('gemma-2b-v1'));
    });
  });

  group('StorageService - Settings', () {
    test('default low power mode is off', () {
      expect(storageService.isLowPowerMode, isFalse);
    });

    test('set and get low power mode', () async {
      await storageService.setLowPowerMode(true);
      expect(storageService.isLowPowerMode, isTrue);
    });

    test('default speech speed is 1.0', () {
      expect(storageService.speechSpeed, equals(1.0));
    });

    test('set and get speech speed', () async {
      await storageService.setSpeechSpeed(1.5);
      expect(storageService.speechSpeed, equals(1.5));
    });

    test('speech speed is clamped to valid range', () async {
      await storageService.setSpeechSpeed(0.1);
      expect(storageService.speechSpeed, equals(0.5));

      await storageService.setSpeechSpeed(3.0);
      expect(storageService.speechSpeed, equals(2.0));
    });

    test('default haptic feedback is on', () {
      expect(storageService.isHapticFeedback, isTrue);
    });

    test('set and get haptic feedback', () async {
      await storageService.setHapticFeedback(false);
      expect(storageService.isHapticFeedback, isFalse);
    });
  });

  group('StorageService - App State', () {
    test('last opened document ID is null by default', () {
      expect(storageService.lastOpenedDocumentId, isNull);
    });

    test('set and get last opened document ID', () async {
      await storageService.setLastOpenedDocumentId(42);
      expect(storageService.lastOpenedDocumentId, equals(42));
    });

    test('clear last opened document ID', () async {
      await storageService.setLastOpenedDocumentId(42);
      await storageService.setLastOpenedDocumentId(null);
      expect(storageService.lastOpenedDocumentId, isNull);
    });

    test('app launch count starts at 0', () {
      expect(storageService.appLaunchCount, equals(0));
    });

    test('increment app launch count', () async {
      await storageService.incrementAppLaunchCount();
      expect(storageService.appLaunchCount, equals(1));

      await storageService.incrementAppLaunchCount();
      expect(storageService.appLaunchCount, equals(2));
    });

    test('first launch date is null by default', () {
      expect(storageService.firstLaunchDate, isNull);
    });

    test('set first launch date only once', () async {
      await storageService.setFirstLaunchDateIfNeeded();
      final firstDate = storageService.firstLaunchDate;
      expect(firstDate, isNotNull);

      // Wait a moment and try again
      await Future.delayed(const Duration(milliseconds: 10));
      await storageService.setFirstLaunchDateIfNeeded();
      
      // Should still be the same date
      expect(storageService.firstLaunchDate, equals(firstDate));
    });
  });

  group('StorageService - Cache Settings', () {
    test('cache is enabled by default', () {
      expect(storageService.isCacheEnabled, isTrue);
    });

    test('set and get cache enabled', () async {
      await storageService.setCacheEnabled(false);
      expect(storageService.isCacheEnabled, isFalse);
    });

    test('default cache size is 50MB', () {
      expect(storageService.cacheSizeMb, equals(50));
    });

    test('set and get cache size', () async {
      await storageService.setCacheSizeMb(100);
      expect(storageService.cacheSizeMb, equals(100));
    });
  });

  group('StorageService - Setup Step Extension', () {
    test('canAccessLibrary requires privacy accepted', () async {
      expect(storageService.canAccessLibrary, isFalse);
      
      await storageService.setPrivacyAccepted(true);
      expect(storageService.canAccessLibrary, isTrue);
    });

    test('canUseChat requires model downloaded', () async {
      expect(storageService.canUseChat, isFalse);
      
      await storageService.setModelDownloaded(true);
      expect(storageService.canUseChat, isTrue);
    });
  });

  group('StorageService - Utility Methods', () {
    test('containsKey', () async {
      expect(storageService.containsKey(StorageKeys.lowPowerMode), isFalse);
      
      await storageService.setLowPowerMode(true);
      expect(storageService.containsKey(StorageKeys.lowPowerMode), isTrue);
    });

    test('remove key', () async {
      await storageService.setLowPowerMode(true);
      expect(storageService.isLowPowerMode, isTrue);

      await storageService.remove(StorageKeys.lowPowerMode);
      expect(storageService.isLowPowerMode, isFalse);
    });

    test('clear all', () async {
      await storageService.setSetupCompleted(true);
      await storageService.setLowPowerMode(true);
      await storageService.setSpeechSpeed(1.5);

      await storageService.clear();

      expect(storageService.isSetupCompleted, isFalse);
      expect(storageService.isLowPowerMode, isFalse);
      expect(storageService.speechSpeed, equals(1.0));
    });

    test('keys returns all stored keys', () async {
      await storageService.setSetupCompleted(true);
      await storageService.setLowPowerMode(true);

      final keys = storageService.keys;
      expect(keys, contains(StorageKeys.setupCompleted));
      expect(keys, contains(StorageKeys.lowPowerMode));
    });
  });

  group('StorageService - Null Safety', () {
    test('handles null prefs gracefully', () {
      final nullService = StorageService(null);
      
      expect(nullService.isReady, isFalse);
      expect(nullService.isSetupCompleted, isFalse);
      expect(nullService.speechSpeed, equals(1.0));
    });
  });
}
