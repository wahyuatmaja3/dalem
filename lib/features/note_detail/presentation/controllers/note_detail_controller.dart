import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/data/repositories/notes_repository.dart';
import '../../../dashboard/data/models/note_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/models/chat_message_model.dart';

sealed class NoteDetailState {
  const NoteDetailState();
}

class NoteDetailLoading extends NoteDetailState {
  const NoteDetailLoading();
}

class NoteDetailLoaded extends NoteDetailState {
  final NoteModel note;
  final List<ChatMessageModel> chatHistory;
  final bool isSendingMessage;

  const NoteDetailLoaded({
    required this.note,
    required this.chatHistory,
    this.isSendingMessage = false,
  });

  NoteDetailLoaded copyWith({
    NoteModel? note,
    List<ChatMessageModel>? chatHistory,
    bool? isSendingMessage,
  }) {
    return NoteDetailLoaded(
      note: note ?? this.note,
      chatHistory: chatHistory ?? this.chatHistory,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
    );
  }
}

class NoteDetailError extends NoteDetailState {
  final String message;
  const NoteDetailError(this.message);
}

class NoteDetailController extends StateNotifier<NoteDetailState> {
  final String noteId;
  final NotesRepository notesRepository;
  final ChatRepository chatRepository;

  NoteDetailController({
    required this.noteId,
    required this.notesRepository,
    required this.chatRepository,
  }) : super(const NoteDetailLoading()) {
    loadNote();
  }

  Future<void> loadNote() async {
    state = const NoteDetailLoading();
    try {
      final note = await notesRepository.fetchNoteDetail(noteId);
      final chatHistory = await chatRepository.fetchHistory(noteId);
      state = NoteDetailLoaded(
        note: note,
        chatHistory: chatHistory,
      );
    } catch (e) {
      state = NoteDetailError(e.toString());
    }
  }

  Future<void> sendMessage(String message) async {
    final currentState = state;
    if (currentState is! NoteDetailLoaded) return;

    final userMessage = ChatMessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderType: SenderType.user,
      message: message,
      createdAt: DateTime.now(),
    );

    state = currentState.copyWith(
      chatHistory: [...currentState.chatHistory, userMessage],
      isSendingMessage: true,
    );

    try {
      await chatRepository.sendMessage(noteId, message);
      final updatedHistory = await chatRepository.fetchHistory(noteId);
      
      state = currentState.copyWith(
        chatHistory: updatedHistory,
        isSendingMessage: false,
      );
    } catch (e) {
      state = currentState.copyWith(isSendingMessage: false);
    }
  }
}
