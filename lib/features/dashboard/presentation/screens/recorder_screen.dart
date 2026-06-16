import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';
import '../../../../core/services/recorder_service.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/notes_repository.dart';

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

class RecorderScreen extends ConsumerStatefulWidget {
  const RecorderScreen({super.key});

  @override
  ConsumerState<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends ConsumerState<RecorderScreen> {
  RecorderState _state = const RecorderIdle();
  Duration _elapsed = Duration.zero;
  String _liveTranscript = '';
  Timer? _timer;
  final _scrollController = ScrollController();
  StreamSubscription<String>? _transcriptionSub;

  Future<void> _handleStartStop() async {
    final recorderService = ref.read(recorderServiceProvider);

    if (_state is! RecorderRecording) {
      final hasPermission = await recorderService.hasPermission();
      if (!hasPermission) {
        await recorderService.requestPermission();
      }

      await recorderService.startRecording();
      setState(() {
        _state = const RecorderRecording();
        _elapsed = Duration.zero;
        _liveTranscript = '';
      });

      _transcriptionSub =
          recorderService.transcriptionStream.listen((transcript) {
        if (!mounted) return;
        setState(() {
          _liveTranscript = transcript;
        });
        _scrollToBottom();
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _elapsed = recorderService.getElapsedTime();
        });
      });
    } else {
      _timer?.cancel();
      _transcriptionSub?.cancel();
      setState(() {
        _state = const RecorderUploading();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
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
    _transcriptionSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _state is RecorderRecording
          ? const Color(0xFF1A1A2E)
          : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: _state is RecorderRecording
            ? Colors.white
            : AppColors.textPrimary,
        elevation: 0,
        title: switch (_state) {
          RecorderRecording() => const _RecordingDot(),
          _ => const SizedBox.shrink(),
        },
        actions: switch (_state) {
          RecorderRecording() => [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _TranscriptionLanguageBadge(
                  isDark: _state is RecorderRecording),
            ),
          ],
          _ => [],
        },
      ),
      body: switch (_state) {
        RecorderIdle() => _buildIdleBody(),
        RecorderRecording() => _buildRecordingBody(),
        RecorderUploading() => _buildUploadingBody(),
      },
    );
  }

  Widget _buildIdleBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.mic_rounded,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Ready to record',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the button to start',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 56),
          _RecordButton(
            onPressed: _handleStartStop,
            isRecording: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBody() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          _formatDuration(_elapsed),
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          AppStrings.recording,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 28),
        const _ListeningWaveIndicator(),
        const SizedBox(height: 24),
        Expanded(
          child: _liveTranscript.isNotEmpty
              ? _TranscriptionText(
                  transcript: _liveTranscript,
                  scrollController: _scrollController,
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hearing_rounded,
                          size: 36, color: Colors.white38),
                      SizedBox(height: 12),
                      Text(
                        'Listening...',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: _RecordButton(
            onPressed: _handleStartStop,
            isRecording: true,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadingBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            AppStrings.uploading,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Processing your note...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording ? AppColors.error : AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: (isRecording ? AppColors.error : AppColors.primary)
                  .withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _opacity,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          AppStrings.recording,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ListeningWaveIndicator extends StatefulWidget {
  const _ListeningWaveIndicator();

  @override
  State<_ListeningWaveIndicator> createState() =>
      _ListeningWaveIndicatorState();
}

class _ListeningWaveIndicatorState extends State<_ListeningWaveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final offset = (index * 0.25);
            final value = (_controller.value + offset) % 1.0;
            final height =
                8.0 + 32.0 * (0.5 + 0.5 * sin(value * 2 * pi).abs());
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }
}

class _TranscriptionLanguageBadge extends StatelessWidget {
  final bool isDark;

  const _TranscriptionLanguageBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'EN',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.primaryDark,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _TranscriptionText extends StatelessWidget {
  final String transcript;
  final ScrollController scrollController;

  const _TranscriptionText({
    required this.transcript,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final words = transcript.split(' ');

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.7,
            ),
            children: [
              for (int i = 0; i < words.length; i++)
                TextSpan(
                  text: '${words[i]} ',
                  style: i == words.length - 1
                      ? TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                        )
                      : null,
                ),
              const WidgetSpan(child: _BlinkingCursor()),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 20,
        color: AppColors.primaryLight,
      ),
    );
  }
}
