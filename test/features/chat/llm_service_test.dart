import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/chat/data/llm_service.dart';
import 'package:citecoach/features/chat/data/rag_service.dart';

class ReadyLlm extends LlmService {
  ReadyLlm({super.generationTimeout});

  @override
  Future<bool> initialize() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.citecoach/llm');
  const stream = MethodChannel('com.citecoach/llm_stream');
  const retrieval = RetrievalResult(
    context: '[Page 1] Machine learning learns from data.',
    citations: [],
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late ReadyLlm llm;
  final calls = <String>[];

  setUp(() {
    llm = ReadyLlm();
    calls.clear();
    messenger.setMockMethodCallHandler(stream, (_) async => null);
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(stream, null);
    messenger.setMockMethodCallHandler(channel, null);
  });

  // These exercise platform channels, not widgets. Use the real async event loop
  // so EventChannel cancellation replies can settle without another widget pump.
  test(
    'cancel settles a request even if native start never replies',
    () async {
      final started = Completer<void>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'startGeneration') {
          started.complete();
          return Completer<void>().future;
        }
        return null;
      });
      final pending = llm.generate(
        query: 'Main topic?',
        retrievalResult: retrieval,
      );
      await started.future;
      await llm.stopGeneration();
      expect((await pending).isSuccess, isFalse);
      expect(calls, contains('stopGeneration'));
    },
    timeout: const Timeout(Duration(seconds: 5)),
  );

  test(
    'silent native generation times out and requests stop',
    () async {
      llm = ReadyLlm(generationTimeout: const Duration(milliseconds: 50));
      final result = await llm.generate(
        query: 'Main topic?',
        retrievalResult: retrieval,
      );
      expect(result.error, contains('took too long'));
      expect(calls, contains('stopGeneration'));
    },
    timeout: const Timeout(Duration(seconds: 5)),
  );

  test(
    'native context errors become actionable errors',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'startGeneration') {
          throw PlatformException(
            code: 'CONTEXT',
            message: 'Question exceeds model context',
          );
        }
        return null;
      });
      final result = await llm.generate(
        query: 'Main topic?',
        retrievalResult: retrieval,
      );
      expect(result.error, contains('Question exceeds model context'));
    },
    timeout: const Timeout(Duration(seconds: 5)),
  );
}
