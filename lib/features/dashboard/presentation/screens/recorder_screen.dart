import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import '../../../../core/services/recorder_service.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/repositories/notes_repository.dart';
import '../widgets/note_edit_sheet.dart';

sealed class RecorderState {
  const RecorderState();
}

class RecorderIdle extends RecorderState {
  const RecorderIdle();
}

class RecorderRecording extends RecorderState {
  const RecorderRecording();
}

class RecorderUploading extends RecorderState {
  const RecorderUploading();
}

class RecorderReview extends RecorderState {
  const RecorderReview();
}

class RecorderScreen extends ConsumerStatefulWidget {
  const RecorderScreen({super.key});

  @override
  ConsumerState<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends ConsumerState<RecorderScreen> {
  RecorderState _state = const RecorderIdle();
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  Future<void> _handleStartStop() async {
    final recorderService = ref.read(recorderServiceProvider);

    if (_state is! RecorderRecording) {
      var hasPermission = await recorderService.hasPermission();
      if (!hasPermission) {
        hasPermission = await recorderService.requestPermission();
      }
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.permissionRequired)),
        );
        return;
      }

      await recorderService.startRecording();
      setState(() {
        _state = const RecorderRecording();
        _elapsed = Duration.zero;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _elapsed = recorderService.getElapsedTime();
        });
      });
    } else {
      _timer?.cancel();
      setState(() {
        _state = const RecorderReview();
      });

      final audioPath = await recorderService.stopRecording();
      await _saveAudioAsNote(audioPath, deleteSourceAfter: true);
    }
  }

  Future<void> _saveAudioAsNote(
    String audioPath, {
    required bool deleteSourceAfter,
  }) async {
    final notesRepository = ref.read(notesRepositoryProvider);

    if (!mounted) return;
    final result = await showNoteEditSheet(
      context,
      initialTitle: '',
      customCategories: notesRepository.getCustomCategories(),
      saveLabel: 'Simpan Catatan',
    );

    if (result == null) {
      if (deleteSourceAfter) {
        await notesRepository.deleteLocalAudio(audioPath);
      }
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() {
      _state = const RecorderUploading();
    });
    final note = await notesRepository.createRecordedNote(
      audioPath,
      title: result.title,
      category: result.category,
    );
    // Only delete audio file if transcription succeeded!
    if (deleteSourceAfter && note.transcript != null) {
      await notesRepository.deleteLocalAudio(audioPath);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            note.transcript != null
                ? 'Catatan dan transkripsi berhasil disimpan.'
                : 'Catatan tersimpan. Transkripsi dapat dijalankan nanti.',
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'wav', 'aac'],
    );

    final path = result?.files.single.path;
    if (path == null) return;

    await _saveAudioAsNote(path, deleteSourceAfter: false);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours > 0) {
      return '$hours:${twoDigits(duration.inMinutes)}:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRecording = _state is RecorderRecording;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        title: isRecording
            ? const _RecordingIndicator()
            : Text(
                'Perekam Catatan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
      ),
      body: SafeArea(
        child: switch (_state) {
          RecorderIdle() => _buildIdleBody(),
          RecorderRecording() => _buildRecordingBody(),
          RecorderReview() => _buildUploadingBody('Menyiapkan catatan...'),
          RecorderUploading() =>
            _buildUploadingBody('Mentranskripsi suara (Offline)...'),
        },
      ),
    );
  }

  Widget _buildIdleBody() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              '00:00',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w300,
                color: colorScheme.secondary,
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Siap Merekam Suara',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tekan tombol rekam untuk mulai menangkap ide atau percakapan Anda.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.secondary,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _RecordButton(
              onPressed: _handleStartStop,
              isRecording: false,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.upload_file_rounded,
                      size: 22, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Punya rekaman audio sebelumnya?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Impor berkas MP3, M4A, atau WAV untuk langsung ditranskripsikan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _handleImport,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Impor'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingBody() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              _formatDuration(_elapsed),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            const _CalmWaveIndicator(),
            const SizedBox(height: 20),
            Text(
              'Mendengarkan & merekam audio...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const Spacer(),
            _RecordButton(
              onPressed: _handleStartStop,
              isRecording: true,
            ),
            const SizedBox(height: 12),
            Text(
              'Tekan untuk menghentikan & menyimpan',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingBody(String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Berkas audio tersimpan aman di perangkat Anda.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isRecording;

  const _RecordButton({
    required this.onPressed,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = isRecording ? colorScheme.error : colorScheme.primary;

    return SizedBox(
      width: 76,
      height: 76,
      child: Material(
        color: activeColor,
        shape: const CircleBorder(),
        elevation: 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: Icon(
              isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordingIndicator extends StatelessWidget {
  const _RecordingIndicator();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colorScheme.error,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Merekam',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _CalmWaveIndicator extends StatefulWidget {
  const _CalmWaveIndicator();

  @override
  State<_CalmWaveIndicator> createState() => _CalmWaveIndicatorState();
}

class _CalmWaveIndicatorState extends State<_CalmWaveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(9, (index) {
            final offset = (index * 0.18);
            final value = (_controller.value + offset) % 1.0;
            final height = 6.0 + 22.0 * (0.3 + 0.7 * sin(value * pi).abs());
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
