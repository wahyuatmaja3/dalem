import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final offlineSummaryServiceProvider = Provider<OfflineSummaryService>((ref) {
  return OfflineSummaryService();
});

class OfflineSummaryService {
  static const Set<String> _stopWords = {
    // Indonesian stop words
    'ada', 'adalah', 'adanya', 'adapun', 'agak', 'agar', 'akan', 'akankah',
    'akhir', 'akhiri', 'akhirnya', 'aku', 'akulah', 'amat', 'amatlah', 'anda',
    'andalah', 'antar', 'antara', 'antaranya', 'apa', 'apaan', 'apabila',
    'apakah', 'apalagi', 'apalah', 'arti', 'artinya', 'asal', 'asalkan',
    'atas', 'atau', 'ataukah', 'ataupun', 'awal', 'awalnya', 'bagai',
    'bagaikan', 'bagaimana', 'bagaimanakah', 'bagaimanapun', 'bagi',
    'bahkan', 'bahwa', 'bahwasanya', 'baik', 'banyak', 'bapak', 'beberapa',
    'begini', 'beginian', 'beginikah', 'beginilah', 'begitu', 'begitukah',
    'begitulah', 'begitupun', 'bekerja', 'belakang', 'belakangan', 'belum',
    'belumlah', 'benar', 'benarkah', 'benarlah', 'berada', 'berakhir',
    'berakhirlah', 'berakhirnya', 'berapa', 'berapakah', 'berapalah',
    'berapapun', 'berarti', 'berawal', 'berbagai', 'berdatangan', 'beri',
    'berikan', 'berikut', 'berikutnya', 'berjumlah', 'berkali-kali', 'berkata',
    'berkehendak', 'berkeinginan', 'berkenaan', 'berlainan', 'berlalu',
    'berlangsung', 'berlebihan', 'bermacam-macam', 'bermaksud', 'bermula',
    'bersama', 'bersama-sama', 'bersiap', 'bersiap-siap', 'bertanya',
    'bertanya-tanya', 'berturut', 'berturut-turut', 'bertutur', 'berujar',
    'berupa', 'besar', 'betul', 'betulkah', 'biasa', 'biasanya', 'bila',
    'bilakah', 'bisa', 'bisakah', 'boleh', 'bolehkah', 'bolehlah', 'buat',
    'bukan', 'bukankah', 'bukanlah', 'bukannya', 'cuma', 'cukup', 'cukupkah',
    'cukuplah', 'dan', 'dapat', 'dari', 'daripada', 'dekat', 'demi',
    'demikian', 'demikianlah', 'dengan', 'depan', 'di', 'dia', 'dialah',
    'dini', 'diri', 'dirinya', 'disini', 'disinilah', 'disitu', 'disitulah',
    'diterangkan', 'diterangkannya', 'ditingkatkan', 'dituangkan', 'dulu',
    'empat', 'enggak', 'gak', 'nggak', 'ia', 'ialah', 'ibarat', 'ibu',
    'ingin', 'inginkah', 'inginkan', 'ini', 'inikah', 'inilah', 'itu',
    'itukah', 'itulah', 'jadi', 'jadilah', 'jadinya', 'jangan', 'jangankan',
    'janganlah', 'jauh', 'jelas', 'jelaslah', 'jelasnya', 'jika', 'jikalau',
    'juga', 'jumlah', 'jumlahnya', 'justru', 'kala', 'kalau', 'kalaulah',
    'kalaupun', 'kalian', 'kami', 'kamilah', 'kamu', 'kamulah', 'kan',
    'kapan', 'kapankah', 'kapanpun', 'karena', 'karenanya', 'ke', 'kecil',
    'kemari', 'kemarin', 'kembali', 'kemudian', 'kemungkinan', 'kenapa',
    'kepada', 'kepadanya', 'keseluruhan', 'keseluruhannya', 'keterlaluan',
    'ketika', 'khususnya', 'kini', 'kinilah', 'kira', 'kira-kira', 'kiranya',
    'kita', 'kitalah', 'kok', 'kurang', 'lagi', 'lagian', 'lah', 'lain',
    'lainnya', 'lalu', 'lama', 'lamanya', 'lanjut', 'lanjutnya', 'lebih',
    'lewat', 'macam', 'maka', 'makanya', 'makin', 'malah', 'malahan',
    'mampu', 'mampukah', 'mana', 'manakala', 'manalagi', 'masa', 'masalah',
    'masalahnya', 'masih', 'masihkah', 'masing', 'masing-masing', 'mau',
    'maupun', 'melainkan', 'melalui', 'melihat', 'melihatnya', 'memang',
    'memastikan', 'memberi', 'memberikan', 'membuat', 'memerlukan',
    'memihak', 'meminta', 'memintakan', 'memisalkan', 'memperbuat',
    'mempergunakan', 'memperkirakan', 'memperlihatkan', 'mempersiapkan',
    'mempersoalkan', 'mempertanyakan', 'mempunyai', 'memulai', 'memungkinkan',
    'menaiki', 'menandaskan', 'menanti', 'menantikan', 'menanya',
    'menanyai', 'menanyakan', 'mendapat', 'mendapatkan', 'mendatang',
    'mendatangi', 'mendatangkan', 'menegaskan', 'mengakhiri', 'mengapa',
    'mengatakan', 'mengatakannya', 'mengenai', 'mengerjakan', 'mengetahui',
    'menggunakan', 'menghendaki', 'mengibaratkan', 'mengibaratkannya',
    'mengingat', 'mengingatkan', 'menginginkan', 'mengira', 'mengucapkan',
    'mengucapkannya', 'mengungkapkan', 'menjadi', 'menjawab', 'menuju',
    'menunjuk', 'menunjuki', 'menunjukkan', 'menunjuknya', 'menurut',
    'menurutnya', 'menyampaikan', 'menyangkut', 'menyatakan', 'menyebutkan',
    'menyeluruh', 'menyiapkan', 'merasa', 'mereka', 'merekalah', 'merupakan',
    'meski', 'meskipun', 'meyakini', 'meyakinkan', 'minta', 'mirip', 'misal',
    'misalkan', 'misalnya', 'mula', 'mulai', 'mulailah', 'mulanya', 'mungkin',
    'mungkinkah', 'nah', 'naik', 'namun', 'nanti', 'nantinya', 'nyaris',
    'nyatanya', 'oleh', 'olehnya', 'pada', 'padahal', 'padanya', 'pak',
    'paling', 'panjang', 'pantas', 'para', 'pasti', 'pastilah', 'penting',
    'pentingnya', 'per', 'pernah', 'persoalan', 'pertama', 'pihak',
    'pihaknya', 'pukul', 'pula', 'pun', 'punya', 'rasa', 'rasanya', 'rata',
    'rupanya', 'saat', 'saatnya', 'saja', 'sajalah', 'saling', 'sama',
    'sama-sama', 'sambil', 'sampai', 'sampai-sampai', 'sana', 'sangat',
    'sangatlah', 'satu', 'saya', 'sayalah', 'se', 'sebab', 'sebabnya',
    'sebagai', 'sebagaimana', 'sebagainya', 'sebagian', 'sebaik',
    'sebaik-baiknya', 'sebaiknya', 'sebaliknya', 'sebanyak', 'sebegini',
    'sebegitu', 'sebelum', 'sebelumnya', 'sebenarnya', 'seberapa',
    'sebesar', 'sebetulnya', 'sebisanya', 'sebuah', 'sebut', 'sebutlah',
    'sebutnya', 'secara', 'secukupnya', 'sedang', 'sedangkan', 'sedemikian',
    'sedikit', 'sedikitnya', 'seenaknya', 'segala', 'segalanya', 'segera',
    'seharusnya', 'sehingga', 'seingat', 'sejak', 'sejauh', 'sejenak',
    'sejumlah', 'sekadar', 'sekadarnya', 'sekali', 'sekalian', 'sekaligus',
    'sekalipun', 'sekarang', 'sekaranglah', 'sekecil', 'seketika', 'sekiranya',
    'sekitar', 'sekitarnya', 'sekurang-kurangnya', 'sela', 'selain', 'selaku',
    'selalu', 'selama', 'selama-lamanya', 'selamanya', 'selanjutnya',
    'seluruh', 'seluruhnya', 'semacam', 'semakin', 'semampu', 'semampunya',
    'semasa', 'semasih', 'semata', 'semata-mata', 'semaunya', 'sementara',
    'semisal', 'semisalnya', 'sempat', 'semua', 'semuanya', 'semula',
    'sendiri', 'sendirian', 'sendirinya', 'seolah', 'seolah-olah', 'seorang',
    'sepanjang', 'sepantasnya', 'sepantasnyalah', 'seperlunya', 'seperti',
    'sepertinya', 'sepihak', 'sering', 'seringnya', 'serta', 'serupa',
    'sesaat', 'sesama', 'sesampai', 'sesegera', 'sesekali', 'seseorang',
    'sesuatu', 'sesuatunya', 'sesudah', 'sesudahnya', 'setelah', 'setempat',
    'setengah', 'seterusnya', 'setiap', 'setiba', 'setibanya', 'setidak-tidaknya',
    'setidaknya', 'setinggi', 'seusai', 'sewaktu', 'siap', 'siapa', 'siapakah',
    'siapapun', 'sih', 'sini', 'sinilah', 'situ', 'situlah', 'suatu', 'sudah',
    'sudahkah', 'sudahlah', 'supaya', 'tadi', 'tadinya', 'tahu', 'tak',
    'tambah', 'tambahnya', 'tampak', 'tampaknya', 'tapi', 'tegas', 'tegasnya',
    'telah', 'tempat', 'tentu', 'tentulah', 'tentunya', 'tepat', 'terakhir',
    'terasa', 'terbanyak', 'terdahulu', 'terdapat', 'terdiri', 'terhadap',
    'terhadapnya', 'teringat', 'terjadi', 'terjadilah', 'terjadinya',
    'terkira', 'terlalu', 'terlebih', 'terlihat', 'termasuk', 'ternyata',
    'tersampaikan', 'tersebut', 'tersebutlah', 'tertentu', 'tertuju', 'terus',
    'terutama', 'tetap', 'tetapi', 'tiap', 'tiba', 'tiba-tiba', 'tidak',
    'tidakkah', 'tidaklah', 'tiga', 'toh', 'tunjuk', 'turut', 'tutur',
    'tuturnya', 'ucap', 'ucapnya', 'ujar', 'ujarnya', 'umum', 'umumnya',
    'ungkap', 'ungkapnya', 'untuk', 'usah', 'waduh', 'wah', 'wahai',
    'waktu', 'waktunya', 'walau', 'walaupun', 'wong', 'ya', 'yaitu', 'yakin',
    'yakni', 'yang',

    // Common English stop words
    'a', 'about', 'above', 'after', 'again', 'against', 'all', 'am', 'an',
    'and', 'any', 'are', 'aren\'t', 'as', 'at', 'be', 'because', 'been',
    'before', 'being', 'below', 'between', 'both', 'but', 'by', 'can',
    'can\'t', 'cannot', 'could', 'couldn\'t', 'did', 'didn\'t', 'do',
    'does', 'doesn\'t', 'doing', 'don\'t', 'down', 'during', 'each',
    'few', 'for', 'from', 'further', 'had', 'hadn\'t', 'has', 'hasn\'t',
    'have', 'haven\'t', 'having', 'he', 'he\'d', 'he\'ll', 'he\'s', 'her',
    'here', 'here\'s', 'hers', 'herself', 'him', 'himself', 'his', 'how',
    'how\'s', 'i', 'i\'d', 'i\'ll', 'i\'m', 'i\'ve', 'if', 'in', 'into',
    'is', 'isn\'t', 'it', 'it\'s', 'its', 'itself', 'let\'s', 'me', 'more',
    'most', 'mustn\'t', 'my', 'myself', 'no', 'nor', 'not', 'of', 'off',
    'on', 'once', 'only', 'or', 'other', 'ought', 'our', 'ours', 'ourselves',
    'out', 'over', 'own', 'same', 'shan\'t', 'she', 'she\'d', 'she\'ll',
    'she\'s', 'should', 'shouldn\'t', 'so', 'some', 'such', 'than', 'that',
    'that\'s', 'the', 'their', 'theirs', 'them', 'themselves', 'then',
    'there', 'there\'s', 'these', 'they', 'they\'d', 'they\'ll', 'they\'re',
    'they\'ve', 'this', 'those', 'through', 'to', 'too', 'under', 'until',
    'up', 'very', 'was', 'wasn\'t', 'we', 'we\'d', 'we\'ll', 'we\'re',
    'we\'ve', 'were', 'weren\'t', 'what', 'what\'s', 'when', 'when\'s',
    'where', 'where\'s', 'which', 'while', 'who', 'who\'s', 'whom', 'why',
    'why\'s', 'with', 'won\'t', 'would', 'wouldn\'t', 'you', 'you\'d',
    'you\'ll', 'you\'re', 'you\'ve', 'your', 'yours', 'yourself', 'yourselves',
  };

  static const List<String> _actionKeywords = [
    'harus', 'perlu', 'tolong', 'jangan lupa', 'nanti', 'akan', 'jadwal',
    'besok', 'deadline', 'kirim', 'siapkan', 'hubungi', 'buat', 'kerjakan',
    'selesaikan', 'tugaskan', 'tindak lanjut', 'follow up', 'agendakan',
    'need to', 'must', 'should', 'will', 'todo', 'to-do', 'make sure',
    'action item', 'action items', 'please', 'prepare', 'send', 'call',
    'email', 'schedule', 'review', 'assigned to', 'by tomorrow'
  ];

  /// Generates a structured Fireflies-style Markdown summary from [transcript].
  /// Runs 100% offline without API key or external service.
  String generateSummary(String transcript) {
    final cleanText = transcript.trim();
    if (cleanText.isEmpty) {
      return '''## Overview
Tidak ada konten transkrip untuk diringkas.

## Key Points
- Tidak ada poin utama.

## Action Items
- None

## Keywords
`kosong`
''';
    }

    final sentences = _extractSentences(cleanText);
    if (sentences.isEmpty) {
      return '''## Overview
$cleanText

## Key Points
- $cleanText

## Action Items
- None

## Keywords
`catatan`
''';
    }

    // 1. Calculate word frequencies for significance scoring
    final wordFrequencies = _calculateWordFrequencies(cleanText);

    // 2. Score sentences
    final scoredSentences = <_ScoredSentence>[];
    for (int i = 0; i < sentences.length; i++) {
      final s = sentences[i];
      final words = _tokenize(s);
      if (words.isEmpty) continue;

      double score = 0.0;
      for (final w in words) {
        score += wordFrequencies[w] ?? 0;
      }
      // Normalize by word count with sublinear scaling
      score = score / (pow(words.length, 0.7));

      // Position boost for opening context
      if (i == 0) score *= 1.35;
      if (i == 1) score *= 1.15;

      final isAction = _isActionSentence(s);
      scoredSentences.add(_ScoredSentence(
        index: i,
        text: s,
        score: score,
        isAction: isAction,
      ));
    }

    // 3. Form Overview
    String overview;
    if (sentences.length <= 2) {
      overview = sentences.join(' ');
    } else {
      final topOverview = scoredSentences.sublist(
        0,
        min(2, scoredSentences.length),
      );
      overview = topOverview.map((e) => e.text).join(' ');
    }

    // 4. Form Key Points
    final sortedByScore = List<_ScoredSentence>.from(scoredSentences)
      ..sort((a, b) => b.score.compareTo(a.score));

    final keyPointCount = min(max(3, (sentences.length / 3).round()), 6);
    final selectedKeyPoints = sortedByScore.take(keyPointCount).toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final keyPointsMarkdown = selectedKeyPoints.map((s) => '- ${s.text}').join('\n');

    // 5. Form Action Items
    final actionSentences = scoredSentences.where((s) => s.isAction).toList();
    String actionItemsMarkdown;
    if (actionSentences.isEmpty) {
      actionItemsMarkdown = '- None';
    } else {
      actionItemsMarkdown = actionSentences
          .take(5)
          .map((s) => '- [ ] ${_cleanActionText(s.text)}')
          .join('\n');
    }

    // 6. Form Keywords
    final sortedWords = wordFrequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topKeywords = sortedWords
        .take(min(6, sortedWords.length))
        .map((e) => '`${e.key}`')
        .toList();

    final keywordsMarkdown =
        topKeywords.isNotEmpty ? topKeywords.join(', ') : '`catatan`';

    return '''## Overview
$overview

## Key Points
$keyPointsMarkdown

## Action Items
$actionItemsMarkdown

## Keywords
$keywordsMarkdown''';
  }

  List<String> _extractSentences(String text) {
    final rawList = text
        .split(RegExp(r'(?<=[.?!;:\n])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 3)
        .toList();

    // If single long block with no punctuation, break by reasonable length
    if (rawList.length == 1 && rawList.first.length > 120) {
      final words = rawList.first.split(RegExp(r'\s+'));
      final chunks = <String>[];
      for (int i = 0; i < words.length; i += 12) {
        final end = min(i + 12, words.length);
        chunks.add(words.sublist(i, end).join(' '));
      }
      return chunks;
    }

    return rawList;
  }

  Map<String, int> _calculateWordFrequencies(String text) {
    final words = _tokenize(text);
    final frequencies = <String, int>{};
    for (final w in words) {
      if (w.length < 3) continue;
      if (_stopWords.contains(w)) continue;
      frequencies[w] = (frequencies[w] ?? 0) + 1;
    }
    return frequencies;
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[^\w\s]"), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  bool _isActionSentence(String text) {
    final lower = text.toLowerCase();
    for (final kw in _actionKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }

  String _cleanActionText(String text) {
    var cleaned = text.trim();
    if (cleaned.endsWith('.')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }
}

class _ScoredSentence {
  final int index;
  final String text;
  final double score;
  final bool isAction;

  const _ScoredSentence({
    required this.index,
    required this.text,
    required this.score,
    required this.isAction,
  });
}
