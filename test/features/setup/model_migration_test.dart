import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:citecoach/core/services/storage_service.dart';
import 'package:citecoach/features/setup/data/setup_repository.dart';
import 'package:citecoach/features/setup/data/model_downloader.dart';
import 'package:citecoach/features/setup/domain/setup_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final version in ['3.0.0', ModelDownloader.modelVersion]) {
    test('package readiness for version $version', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.setupCompleted: true,
        StorageKeys.privacyAccepted: true,
        StorageKeys.modelDownloaded: true,
        StorageKeys.modelDownloadProgress: 1.0,
        StorageKeys.modelVersion: version,
      });
      final prefs = await SharedPreferences.getInstance();
      final state = SetupRepository(StorageService(prefs)).loadSetupState();
      expect(state.currentStep, SetupStep.done);
      expect(state.isModelDownloaded, version == ModelDownloader.modelVersion);
      expect(state.downloadProgress, version == ModelDownloader.modelVersion ? 1.0 : 0.0);
    });
  }
}
