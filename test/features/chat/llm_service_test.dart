import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/chat/data/llm_service.dart';
import 'package:citecoach/features/chat/data/rag_service.dart';

class ReadyLlm extends LlmService {
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

  testWidgets('cancel settles a request even if native start never replies', (
    tester,
  ) async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'startGeneration') return Completer<void>().future;
      return null;
    });
    final pending = llm.generate(
      query: 'Main topic?',
      retrievalResult: retrieval,
    );
    await tester.pump();
    await llm.stopGeneration();
    await tester.pump();
    expect((await pending).isSuccess, isFalse);
    expect(calls, contains('stopGeneration'));
  });

  testWidgets('silent native generation times out and requests stop', (
    tester,
  ) async {
    final pending = llm.generate(
      query: 'Main topic?',
      retrievalResult: retrieval,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 121));
    expect((await pending).error, contains('took too long'));
    expect(calls, contains('stopGeneration'));
  });

  testWidgets('native context errors become actionable errors', (tester) async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'startGeneration') {
        throw PlatformException(
          code: 'CONTEXT',
          message: 'Question exceeds model context',
        );
      }
      return null;
    });
    final pending = llm.generate(
      query: 'Main topic?',
      retrievalResult: retrieval,
    );
    await tester.pump();
    expect((await pending).error, contains('Question exceeds model context'));
  });
}
