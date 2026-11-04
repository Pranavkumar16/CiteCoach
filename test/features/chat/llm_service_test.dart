import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/chat/data/llm_service.dart';
import 'package:citecoach/features/chat/data/rag_service.dart';

class ReadyLlm extends LlmService {
  ReadyLlm() : super(generationTimeout: const Duration(milliseconds: 50));
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

  test('Qwen3 prompt disables thinking and retains grounded evidence', () {
    final prompt = llm.buildGroundedPrompt(
      query: 'Main topic?',
      context: retrieval.context,
      citations: [],
      history: [],
    );
    expect(prompt, startsWith('<|im_start|>user\n'));
    expect(prompt, endsWith('<|im_start|>assistant\n<think>\n\n</think>\n\n'));
    expect(prompt, contains('/no_think'));
    expect(prompt, contains('Machine learning learns from data.'));
    expect(prompt, contains('Cite every claim using [Page X]'));
    expect(prompt, isNot(contains('<start_of_turn>')));
  });

  test('cancel settles a request even if native start never replies', () async {
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
    await started.future.timeout(const Duration(seconds: 2));
    await llm.stopGeneration();
    expect(
      (await pending.timeout(const Duration(seconds: 3))).isSuccess,
      isFalse,
    );
    expect(calls, contains('stopGeneration'));
  });

  test('disposing a tool cancels its own task and releases the model', () async {
    final started = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'startGeneration' && !started.isCompleted) started.complete();
      return null;
    });
    final cancellation = GenerationCancellation();
    final pending = llm.generate(
      query: 'Create cards', retrievalResult: retrieval, cancellation: cancellation);
    await started.future;
    cancellation.cancel();
    expect((await pending).isSuccess, isFalse);
    final next = await llm.generate(query: 'Next question', retrievalResult: retrieval);
    expect(next.error, isNot(contains('Another answer')));
    expect(calls.where((c) => c == 'startGeneration'), hasLength(2));
  });

  test('cancelled retrieval cannot start a stale inference task', () async {
    final cancellation = GenerationCancellation()..cancel();
    final result = await llm.generate(
      query: 'Stale question', retrievalResult: retrieval, cancellation: cancellation);
    expect(result.isSuccess, isFalse);
    expect(calls, isNot(contains('startGeneration')));
  });

  test('cancelling an unrelated task does not stop the active model', () async {
    final unrelated = GenerationCancellation()..cancel();
    expect(unrelated.isCancelled, isTrue);
    expect(calls, isNot(contains('stopGeneration')));
  });

  test('silent native generation times out and requests stop', () async {
    final pending = llm.generate(
      query: 'Main topic?',
      retrievalResult: retrieval,
    );
    expect(
      (await pending.timeout(const Duration(seconds: 3))).error,
      contains('took too long'),
    );
    expect(calls, contains('stopGeneration'));
  });

  test('native context errors become actionable errors', () async {
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
    expect(
      (await pending.timeout(const Duration(seconds: 3))).error,
      contains('Try a shorter question'),
    );
  });
}
