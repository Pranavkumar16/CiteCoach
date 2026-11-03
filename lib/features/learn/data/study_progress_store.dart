import 'package:shared_preferences/shared_preferences.dart';

/// Stores only review state, scoped to a document and topic.
/// Users can clear all learning progress without affecting their PDFs.
class StudyProgressStore {
  const StudyProgressStore();

  String _key(int documentId, String topic) =>
      'learn.v1.$documentId.${Uri.encodeComponent(topic.trim().toLowerCase())}';

  Future<Set<String>> load(int documentId, String topic) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(documentId, topic)) ?? <String>[]).toSet();
  }

  Future<void> save(int documentId, String topic, Set<String> known) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(documentId, topic), known.toList());
  }

  Future<void> clear(int documentId, String topic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(documentId, topic));
  }
}
