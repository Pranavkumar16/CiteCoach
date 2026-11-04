import 'package:flutter_test/flutter_test.dart';
import 'package:citecoach/features/chat/data/chat_repository.dart';
import 'package:citecoach/features/chat/data/llm_service.dart';
import 'package:citecoach/features/chat/data/rag_service.dart';
import 'package:citecoach/features/chat/domain/chat_message.dart';
import 'package:citecoach/features/chat/providers/chat_provider.dart';
import 'package:citecoach/features/processing/data/bm25_service.dart';

class RecordingRepository extends ChatRepository {
  RecordingRepository() : super(null);
  int saves = 0;
  @override
  Future<ChatMessage?> saveMessage(ChatMessage message) async =>
      message.copyWith(id: ++saves);
}

class EvidenceRag extends RagService {
  EvidenceRag() : super(null, BM25Service());
  @override
  Future<RetrievalResult> retrieve(int documentId, String query) async =>
      const RetrievalResult(context: '[Page 1] Evidence', citations: []);
}

class FailingLlm extends LlmService {
  @override
  Future<GenerationResult> generate({
    required String query,
    required RetrievalResult retrievalResult,
    List<ChatMessage> conversationHistory = const [],
    StreamCallback? onToken,
    String? responseInstructions,
  }) async => GenerationResult.error('Try again');
}

void main() {
  test('flashcard prompt replaces conflicting chat instructions', () {
    final prompt = LlmService().buildGroundedPrompt(
      query: 'Create three cards',
      context: '[Page 1] Evidence',
      citations: [],
      history: [],
      responseInstructions: 'Use Q: | A: | PAGE: format only.',
    );
    expect(prompt, contains('Use Q: | A: | PAGE: format only.'));
    expect(prompt, isNot(contains('Give a short answer with')));
    expect(prompt, isNot(contains('Cite every claim')));
    expect(prompt, contains('[Page 1] Evidence'));
  });
  test(
    'Retry reuses the saved question without duplicate history rows',
    () async {
      final repository = RecordingRepository();
      final notifier = ChatNotifier(
        repository: repository,
        ragService: EvidenceRag(),
        llmService: FailingLlm(),
      );
      await notifier.initialize(1);
      await notifier.sendMessage('What is the topic?');
      await notifier.retryLastMessage();
      expect(repository.saves, 1);
      expect(notifier.state.messages.length, 1);
      expect(notifier.state.isInputDisabled, isFalse);
      notifier.dispose();
    },
  );
}
