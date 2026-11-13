import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/note_detail/data/models/chat_message_model.dart';
import 'offline_summary_service.dart';

final offlineChatServiceProvider = Provider<OfflineChatService>((ref) {
  return OfflineChatService(
    summaryService: ref.read(offlineSummaryServiceProvider),
  );
});

class OfflineChatService {
  final OfflineSummaryService summaryService;

  OfflineChatService({required this.summaryService});

  /// Answers a user's question grounded strictly on the [transcript].
  /// Runs completely on-device without internet or API keys.
  Future<String> answerQuestion({
    required String transcript,
    required String question,
    List<ChatMessageModel> history = const [],
  }) async {
    final cleanTranscript = transcript.trim();
    final cleanQuestion = question.trim();

    if (cleanTranscript.isEmpty) {
      return 'Catatan ini belum memiliki transkrip suara. Rekam atau transkripsikan audio terlebih dahulu untuk dapat bertanya.';
    }

    if (cleanQuestion.isEmpty) {
      return 'Silakan ajukan pertanyaan seputar isi catatan ini.';
    }

    final lowerQ = cleanQuestion.toLowerCase();

    // 1. Check for summary / overview request
    if (_isSummaryRequest(lowerQ)) {
      final summary = summaryService.generateSummary(cleanTranscript);
      return 'Berikut ringkasan dari catatan ini:\n\n$summary';
    }

    // 2. Check for action items / tasks request
    if (_isActionRequest(lowerQ)) {
      final sentences = _splitSentences(cleanTranscript);
      final actionItems = sentences.where((s) {
        final l = s.toLowerCase();
        return l.contains('harus') ||
            l.contains('perlu') ||
            l.contains('tolong') ||
            l.contains('jangan lupa') ||
            l.contains('akan') ||
            l.contains('deadline') ||
            l.contains('jadwal') ||
            l.contains('kirim') ||
            l.contains('hubungi') ||
            l.contains('kerjakan') ||
            l.contains('selesaikan') ||
            l.contains('todo') ||
            l.contains('need to') ||
            l.contains('must');
      }).toList();

      if (actionItems.isEmpty) {
        return 'Tidak ditemukan tugas atau tindak lanjut (action items) khusus yang tertera di dalam transkrip catatan ini.';
      }
      final items = actionItems.map((s) => '• $s').join('\n');
      return 'Berikut tugas atau tindak lanjut yang teridentifikasi:\n$items';
    }

    // 3. Keyword / semantic search on transcript sentences
    final queryTokens = _tokenize(lowerQ)
        .where((w) => w.length > 2 && !_queryStopWords.contains(w))
        .toList();

    final sentences = _splitSentences(cleanTranscript);

    if (queryTokens.isEmpty) {
      // General question without specific keywords: return top sentences
      return 'Berdasarkan catatan: "${sentences.take(2).join(' ')}"';
    }

    // Score sentences by matching query tokens
    final matchedSentences = <_MatchResult>[];
    for (int i = 0; i < sentences.length; i++) {
      final s = sentences[i];
      final sentenceTokens = _tokenize(s.toLowerCase());
      int matchCount = 0;

      for (final qt in queryTokens) {
        if (sentenceTokens.contains(qt) || s.toLowerCase().contains(qt)) {
          matchCount++;
        }
      }

      if (matchCount > 0) {
        matchedSentences.add(_MatchResult(
          sentence: s,
          score: matchCount.toDouble() / max(1, sentenceTokens.length),
          matchCount: matchCount,
        ));
      }
    }

    if (matchedSentences.isEmpty) {
      return 'Maaf, informasi tentang "$cleanQuestion" tidak ditemukan dalam transkrip catatan ini.';
    }

    matchedSentences.sort((a, b) {
      if (b.matchCount != a.matchCount) {
        return b.matchCount.compareTo(a.matchCount);
      }
      return b.score.compareTo(a.score);
    });

    final topMatches = matchedSentences.take(3).map((m) => m.sentence).toList();
    if (topMatches.length == 1) {
      return 'Berdasarkan catatan:\n"${topMatches.first}"';
    }

    final list = topMatches.map((s) => '• "$s"').join('\n');
    return 'Berdasarkan catatan, berikut informasi yang terkait:\n$list';
  }

  bool _isSummaryRequest(String q) {
    return q.contains('ringkas') ||
        q.contains('rangkum') ||
        q.contains('summary') ||
        q.contains('kesimpulan') ||
        q.contains('garis besar') ||
        q.contains('poin penting') ||
        q.contains('tentang apa') ||
        q.contains('rekap');
  }

  bool _isActionRequest(String q) {
    return q.contains('tugas') ||
        q.contains('action item') ||
        q.contains('to do') ||
        q.contains('todo') ||
        q.contains('tindak lanjut') ||
        q.contains('pekerjaan') ||
        q.contains('deadline');
  }

  List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.?!;:\n])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 3)
        .toList();
  }

  List<String> _tokenize(String text) {
    return text
        .replaceAll(RegExp(r"[^\w\s]"), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  static const Set<String> _queryStopWords = {
    'apa', 'apakah', 'siapa', 'siapakah', 'kapan', 'kapankah', 'dimana',
    'bagaimana', 'bagaimanakah', 'kenapa', 'mengapa', 'berapa', 'yang',
    'dan', 'di', 'ke', 'dari', 'ini', 'itu', 'adalah', 'ada', 'pada',
    'untuk', 'dengan', 'saya', 'kamu', 'dia', 'mereka', 'kita', 'dalam',
    'catatan', 'transkrip', 'rekaman', 'bisa', 'tolong', 'jelaskan',
    'sebutkan', 'beritahu', 'kasih', 'tahu', 'what', 'who', 'when', 'where',
    'how', 'why', 'is', 'are', 'the', 'in', 'on', 'at', 'about', 'note',
  };
}

class _MatchResult {
  final String sentence;
  final double score;
  final int matchCount;

  const _MatchResult({
    required this.sentence,
    required this.score,
    required this.matchCount,
  });
}
