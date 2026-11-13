import 'package:flutter_test/flutter_test.dart';
import 'package:dalem/core/services/offline_chat_service.dart';
import 'package:dalem/core/services/offline_summary_service.dart';

void main() {
  group('OfflineChatService', () {
    late OfflineChatService service;

    setUp(() {
      service = OfflineChatService(summaryService: OfflineSummaryService());
    });

    test('replies politely when transcript is empty', () async {
      final answer = await service.answerQuestion(
        transcript: '',
        question: 'Tentang apa ini?',
      );
      expect(answer, contains('belum memiliki transkrip'));
    });

    test('handles summary inquiry properly', () async {
      const transcript =
          'Diskusi tentang peluncuran sistem baru. Kami sepakat merilis versi beta minggu depan.';
      final answer = await service.answerQuestion(
        transcript: transcript,
        question: 'Tolong ringkas catatan ini',
      );
      expect(answer, contains('Berikut ringkasan dari catatan ini:'));
      expect(answer, contains('## Overview'));
    });

    test('extracts action items when asked about tasks', () async {
      const transcript =
          'Rapat mingguan divisi produk. Kita harus menyiapkan dokumen spesifikasi besok.';
      final answer = await service.answerQuestion(
        transcript: transcript,
        question: 'Apa tugas yang harus dilakukan?',
      );
      expect(answer, contains('tugas atau tindak lanjut'));
      expect(answer, contains('menyiapkan dokumen'));
    });

    test('finds matching sentence based on topic query', () async {
      const transcript =
          'Anggaran biaya marketing dialokasikan sebesar 50 juta rupiah untuk kuartal pertama. '
          'Tim desain akan fokus memperbarui landing page.';
      final answer = await service.answerQuestion(
        transcript: transcript,
        question: 'Berapa anggaran biaya marketing?',
      );
      expect(answer, contains('50 juta rupiah'));
    });

    test('reports not found when topic is absent', () async {
      const transcript = 'Pembahasan mengenai desain aplikasi dan palet warna.';
      final answer = await service.answerQuestion(
        transcript: transcript,
        question: 'Dimana letak bandara internasional?',
      );
      expect(answer, contains('tidak ditemukan dalam transkrip'));
    });
  });
}
