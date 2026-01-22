import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/setup/data/model_downloader.dart';

/// Provider for model file lookup helpers.
final modelFilesProvider = Provider<ModelFiles>((ref) {
  return const ModelFiles();
});

/// Resolves local paths for model assets.
class ModelFiles {
  const ModelFiles();

  /// Environment key for embedding model filename.
  static const String embeddingModelFileEnvKey = 'EMBEDDING_MODEL_FILE';

  Future<Directory> _getModelsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  Future<String> getLlmModelPath() async {
    final dir = await _getModelsDirectory();
    return '${dir.path}/${ModelDownloader.modelName}';
  }

  Future<String?> getEmbeddingModelPath({String? fileName}) async {
    final resolved = (fileName?.trim().isNotEmpty ?? false)
        ? fileName!.trim()
        : const String.fromEnvironment(embeddingModelFileEnvKey);
    if (resolved.isEmpty) return null;

    final dir = await _getModelsDirectory();
    return '${dir.path}/$resolved';
  }

  Future<bool> hasLlmModel() async {
    final path = await getLlmModelPath();
    final file = File(path);
    if (!await file.exists()) return false;
    final size = await file.length();
    return size > 0;
  }

  Future<bool> hasEmbeddingModel({String? fileName}) async {
    final path = await getEmbeddingModelPath(fileName: fileName);
    if (path == null) return false;

    final file = File(path);
    if (!await file.exists()) return false;
    final size = await file.length();
    return size > 0;
  }

  Future<void> clearModels() async {
    try {
      final dir = await _getModelsDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('ModelFiles: Failed to clear models: $e');
    }
  }
}
