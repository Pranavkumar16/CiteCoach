import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/model_files.dart';

/// Provider for the model import service.
final modelImportServiceProvider = Provider<ModelImportService>((ref) {
  final modelFiles = ref.watch(modelFilesProvider);
  return ModelImportService(modelFiles);
});

/// Result of a model import operation.
class ModelImportResult {
  const ModelImportResult({
    this.fileName,
    this.fileSize = 0,
    this.error,
    this.cancelled = false,
  });

  final String? fileName;
  final int fileSize;
  final String? error;
  final bool cancelled;

  bool get isSuccess => error == null && !cancelled;
  bool get isError => error != null;

  factory ModelImportResult.success(String fileName, int fileSize) {
    return ModelImportResult(fileName: fileName, fileSize: fileSize);
  }

  factory ModelImportResult.error(String message) {
    return ModelImportResult(error: message);
  }

  factory ModelImportResult.cancelled() {
    return const ModelImportResult(cancelled: true);
  }
}

/// Service for importing local model files.
class ModelImportService {
  ModelImportService(this._modelFiles);

  final ModelFiles _modelFiles;

  Future<ModelImportResult> pickAndImportLlmModel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('ModelImportService: User cancelled file picker');
        return ModelImportResult.cancelled();
      }

      final file = result.files.first;
      final filePath = file.path;
      if (filePath == null || filePath.isEmpty) {
        return ModelImportResult.error('Could not access the selected file');
      }

      return importLlmModelFromPath(filePath);
    } catch (e) {
      debugPrint('ModelImportService: Error selecting model file: $e');
      return ModelImportResult.error('Error selecting model file: $e');
    }
  }

  Future<ModelImportResult> importLlmModelFromPath(String filePath) async {
    try {
      final sourceFile = File(filePath);
      if (!await sourceFile.exists()) {
        return ModelImportResult.error('Model file not found');
      }

      final size = await sourceFile.length();
      if (size <= 0) {
        return ModelImportResult.error('Model file is empty');
      }

      final destPath = await _modelFiles.getLlmModelPath();
      final destFile = File(destPath);
      if (await destFile.exists()) {
        await destFile.delete();
      }

      await sourceFile.copy(destPath);
      final fileName = filePath.split(Platform.pathSeparator).last;

      debugPrint('ModelImportService: Imported model file to $destPath');
      return ModelImportResult.success(fileName, size);
    } catch (e) {
      debugPrint('ModelImportService: Error importing model file: $e');
      return ModelImportResult.error('Failed to import model file: $e');
    }
  }
}
