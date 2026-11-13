import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

final recorderServiceProvider = Provider<RecorderService>((ref) {
  return RecorderService();
});

class RecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _recordingStartTime;
  String? _currentRecordingPath;

  /// Checks whether microphone permission is already granted.
  Future<bool> hasPermission() async {
    return _recorder.hasPermission(request: false);
  }

  /// Requests microphone permission and reports whether it was granted.
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> startRecording() async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );

    _recordingStartTime = DateTime.now();
    _currentRecordingPath = path;
    return path;
  }

  Future<String> stopRecording() async {
    final path = await _recorder.stop();
    _recordingStartTime = null;
    _currentRecordingPath = null;

    if (path == null || path.isEmpty) {
      throw Exception('No active recording');
    }
    return path;
  }

  Duration getElapsedTime() {
    if (_recordingStartTime == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(_recordingStartTime!);
  }

  bool get isRecording => _currentRecordingPath != null;

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
