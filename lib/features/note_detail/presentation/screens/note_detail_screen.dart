import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/note_detail_providers.dart';
import '../controllers/note_detail_controller.dart';
import '../widgets/transcript_tab.dart';
import '../widgets/summary_tab.dart';
import '../widgets/chat_tab.dart';
import '../../../../core/widgets/app_error_view.dart';

class NoteDetailScreen extends ConsumerWidget {
  final String noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(noteDetailControllerProvider(noteId));

    return Scaffold(
      appBar: AppBar(
        title: state is NoteDetailLoaded
            ? Text(
                state.note.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
      ),
      body: switch (state) {
        NoteDetailLoading() =>
          const Center(child: CircularProgressIndicator()),
        NoteDetailLoaded(
          note: final note,
          chatHistory: final chat,
          isSendingMessage: final isSending,
          isGeneratingSummary: final isGeneratingSummary,
          isTranscribing: final isTranscribing,
        ) =>
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outline, width: 1),
                    ),
                  ),
                  child: const TabBar(
                    tabs: [
                      Tab(
                        icon: Icon(Icons.description_outlined, size: 18),
                        text: 'Transkrip',
                      ),
                      Tab(
                        icon: Icon(Icons.article_outlined, size: 18),
                        text: 'Ringkasan',
                      ),
                      Tab(
                        icon: Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        text: 'Tanya Catatan',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      TranscriptTab(
                        transcript: note.transcript ?? '',
                        segments: note.transcriptSegments,
                        hasAudio: note.audioPath != null &&
                            note.audioPath!.isNotEmpty,
                        isTranscribing: isTranscribing,
                        onRetryTranscription: () async {
                          try {
                            await ref
                                .read(noteDetailControllerProvider(noteId)
                                    .notifier)
                                .retryTranscription();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Gagal memproses transkripsi: ${e.toString()}'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      SummaryTab(
                        summaryMarkdown: note.summaryMarkdown,
                        isGenerating: isGeneratingSummary,
                        onGenerateSummary: () async {
                          try {
                            await ref
                                .read(noteDetailControllerProvider(noteId)
                                    .notifier)
                                .generateSummary();
                          } catch (e) {
                            if (context.mounted) {
                              final message = e is StateError
                                  ? e.message
                                  : e.toString();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Gagal membuat ringkasan: $message'),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      ChatTab(
                        messages: chat,
                        isSending: isSending,
                        onSendMessage: (message) {
                          ref
                              .read(noteDetailControllerProvider(noteId)
                                  .notifier)
                              .sendMessage(message);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        NoteDetailError(message: final message) => AppErrorView(
            message: message,
            onRetry: () {
              ref
                  .read(noteDetailControllerProvider(noteId).notifier)
                  .loadNote();
            },
          ),
      },
    );
  }
}
