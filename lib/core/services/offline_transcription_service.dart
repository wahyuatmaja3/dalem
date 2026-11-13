import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';

class OfflineTranscriptionSegment {
  final double startSeconds;
  final double endSeconds;
  final String? speaker;
  final String text;

  const OfflineTranscriptionSegment({
    required this.startSeconds,
    required this.endSeconds,
    this.speaker,
    required this.text,
  });
}

class OfflineTranscriptionResult {
  final String text;
  final List<OfflineTranscriptionSegment> segments;

  const OfflineTranscriptionResult({
    required this.text,
    required this.segments,
  });
}

abstract class OfflineTranscriptionService {
  Future<OfflineTranscriptionResult> transcribe({
    required String filePath,
    String language = 'id',
  });

  Future<bool> isModelDownloaded();
}

final offlineTranscriptionServiceProvider =
    Provider<OfflineTranscriptionService>((ref) {
  return WhisperOfflineTranscriptionService();
});

class WhisperOfflineTranscriptionService
    implements OfflineTranscriptionService {
  final WhisperModel model;
  final String? customModelDir;

  WhisperOfflineTranscriptionService({
    this.model = WhisperModel.base,
    this.customModelDir,
  });

  Future<String> _getModelDir() async {
    if (customModelDir != null) return customModelDir!;
    if (Platform.isAndroid) {
      final dir = await getApplicationSupportDirectory();
      return dir.path;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
  }

  @override
  Future<bool> isModelDownloaded() async {
    try {
      final dir = await _getModelDir();
      final file = File(model.getPath(dir));
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<OfflineTranscriptionResult> transcribe({
    required String filePath,
    String language = 'id',
  }) async {
    final audioFile = File(filePath);
    if (!await audioFile.exists()) {
      throw StateError('Berkas audio tidak ditemukan di: $filePath');
    }

    final modelDir = await _getModelDir();
    final whisper = Whisper(
      model: model,
      modelDir: modelDir,
    );

    final response = await whisper.transcribe(
      transcribeRequest: TranscribeRequest(
        audio: filePath,
        language: language,
        isTranslate: false,
        isVerbose: false,
        threads: 4,
      ),
    );

    final rawSegments = response.segments ?? [];
    final segments = rawSegments.map((s) {
      final start = s.fromTs.inMilliseconds / 1000.0;
      final end = s.toTs.inMilliseconds / 1000.0;
      return OfflineTranscriptionSegment(
        startSeconds: start,
        endSeconds: end,
        text: s.text.trim(),
      );
    }).where((s) => s.text.isNotEmpty).toList();

    return OfflineTranscriptionResult(
      text: response.text.trim(),
      segments: segments,
    );
  }
}
