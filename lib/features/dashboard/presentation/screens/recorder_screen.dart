import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../../core/services/recorder_service.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/repositories/notes_repository.dart';

class RecorderScreen extends ConsumerStatefulWidget {
  const RecorderScreen({super.key});

  @override
  ConsumerState<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends ConsumerState<RecorderScreen> {
  bool _isRecording = false;
  bool _isUploading = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  Future<void> _handleStartStop() async {
    final recorderService = ref.read(recorderServiceProvider);

    if (!_isRecording) {
      final hasPermission = await recorderService.hasPermission();
      if (!hasPermission) {
        await recorderService.requestPermission();
      }

      await recorderService.startRecording();
      setState(() {
        _isRecording = true;
        _elapsed = Duration.zero;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsed = recorderService.getElapsedTime();
        });
      });
    } else {
      _timer?.cancel();
      setState(() {
        _isRecording = false;
        _isUploading = true;
      });

      final audioPath = await recorderService.stopRecording();
      final notesRepository = ref.read(notesRepositoryProvider);
      await notesRepository.createRecordedNote(audioPath);
      await notesRepository.deleteLocalAudio(audioPath);

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRecording ? AppStrings.recording : AppStrings.record),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRecording) ...[
              Text(
                _formatDuration(_elapsed),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.recording,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                    ),
              ),
            ] else if (_isUploading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                AppStrings.uploading,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ] else ...[
              Icon(
                Icons.mic,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Ready to record',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
            const SizedBox(height: 48),
            if (!_isUploading)
              FloatingActionButton.large(
                onPressed: _handleStartStop,
                child: Icon(_isRecording ? Icons.stop : Icons.mic),
              ),
          ],
        ),
      ),
    );
  }
}
