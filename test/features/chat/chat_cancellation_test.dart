import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/chat/data/chat_repository.dart';
import 'package:citecoach/features/chat/data/llm_service.dart';
import 'package:citecoach/features/chat/data/rag_service.dart';
import 'package:citecoach/features/chat/domain/chat_message.dart';
import 'package:citecoach/features/chat/providers/chat_provider.dart';
import 'package:citecoach/features/processing/data/bm25_service.dart';

class DelayedRepository extends ChatRepository {
  DelayedRepository() : super(null);
  final saved = Completer<ChatMessage?>();
  int saveCount = 0;

  @override
  Future<ChatMessage?> saveMessage(ChatMessage message) {
    saveCount++;
    return saved.future;
  }
}

class StoppableLlm extends LlmService {
  int stopCount = 0;
  @override
  Future<void> stopGeneration() async {
    stopCount++;
  }
}

void main() {
  late DelayedRepository repository;
  late StoppableLlm llm;
  late ChatNotifier chat;

  setUp(() async {
    repository = DelayedRepository();
    llm = StoppableLlm();
    chat = ChatNotifier(
      repository: repository,
      ragService: RagService(null, BM25Service()),
      llmService: llm,
    );
    await chat.initialize(1);
  });

  tearDown(() {
    if (chat.mounted) chat.dispose();
  });

  test(
    'cancel while saving ignores the late completion and unlocks input',
    () async {
      final pending = chat.sendMessage('Main topic?');
      expect(chat.state.isGenerating, isTrue);
      chat.cancelGeneration();
      expect(chat.state.isInputDisabled, isFalse);
      repository.saved.complete(
        ChatMessage.user(documentId: 1, content: 'Main topic?'),
      );
      await pending;
      expect(chat.state.messages, isEmpty);
      expect(chat.state.error, isNull);
      expect(llm.stopCount, 1);
    },
  );

  test('rapid duplicate taps save only one question', () async {
    final pending = chat.sendMessage('Main topic?');
    await chat.sendMessage('Main topic?');
    expect(repository.saveCount, 1);
    repository.saved.complete(null);
    await pending;
    expect(chat.state.isGenerating, isFalse);
    expect(chat.state.error, 'Failed to save message');
  });

  test(
    'leaving during a request stops inference and ignores late state',
    () async {
      final pending = chat.sendMessage('Main topic?');
      chat.dispose();
      repository.saved.complete(null);
      await pending;
      expect(llm.stopCount, 1);
    },
  );
}
