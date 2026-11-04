import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/voice/data/stt_service.dart';
import 'package:citecoach/features/voice/data/tts_service.dart';
import 'package:citecoach/features/voice/providers/voice_provider.dart';

class DelayedSpeech extends SttService {
  final ready = Completer<bool>();
  int starts = 0;
  @override
  Future<bool> initialize() => ready.future;
  @override
  Future<bool> startListening({
    required SttResultCallback onResult,
    SttErrorCallback? onError,
    SttSoundLevelCallback? onSoundLevel,
    String? localeId,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    starts++;
    return true;
  }

  @override
  void dispose() {}
}

class SilentTts extends TtsService {
  @override
  Future<bool> initialize() async => true;
  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'first microphone tap waits for initialization instead of reporting unavailable',
    () async {
      final speech = DelayedSpeech();
      final voice = VoiceNotifier(sttService: speech, ttsService: SilentTts());
      final pending = voice.startListening();
      expect(voice.state.error, isNull);
      speech.ready.complete(true);
      await pending.timeout(const Duration(seconds: 2));
      expect(speech.starts, 1);
      expect(voice.state.isListening, isTrue);
      voice.dispose();
    },
  );
  test(
    'closing voice during initialization ignores late service results',
    () async {
      final speech = DelayedSpeech();
      final voice = VoiceNotifier(sttService: speech, ttsService: SilentTts());
      final pending = voice.startListening();
      voice.dispose();
      speech.ready.complete(true);
      await pending.timeout(const Duration(seconds: 2));
      expect(speech.starts, 0);
    },
  );
}
