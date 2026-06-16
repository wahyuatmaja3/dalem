import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/note_detail_providers.dart';
import '../controllers/note_detail_controller.dart';
import '../widgets/transcript_tab.dart';
import '../widgets/summary_tab.dart';
import '../widgets/chat_tab.dart';
import '../../../../core/constants/app_colors.dart';

class NoteDetailScreen extends ConsumerWidget {
  final String noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noteDetailControllerProvider(noteId));

    return Scaffold(
      appBar: AppBar(
        title: state is NoteDetailLoaded
            ? Text(
                state.note.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              )
            : null,
        backgroundColor: AppColors.surface,
      ),
      body: switch (state) {
        NoteDetailLoading() =>
          const Center(child: CircularProgressIndicator()),
        NoteDetailLoaded(
          note: final note,
          chatHistory: final chat,
          isSendingMessage: final isSending
        ) =>
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  color: AppColors.surface,
                  child: const TabBar(
                    tabs: [
                      Tab(
                        icon: Icon(Icons.description_outlined, size: 18),
                        text: 'Transcript',
                      ),
                      Tab(
                        icon: Icon(Icons.summarize_outlined, size: 18),
                        text: 'Summary',
                      ),
                      Tab(
                        icon: Icon(Icons.chat_bubble_outline_rounded,
                            size: 18),
                        text: 'AI Chat',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: TabBarView(
                    children: [
                      TranscriptTab(transcript: note.transcript ?? ''),
                      SummaryTab(
                          summaryMarkdown: note.summaryMarkdown ?? ''),
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
        NoteDetailError(message: final message) =>
          Center(child: Text(message)),
      },
    );
  }
}
