import 'package:flutter_test/flutter_test.dart';
import 'package:dalem/core/services/offline_summary_service.dart';

void main() {
  group('OfflineSummaryService', () {
    late OfflineSummaryService service;

    setUp(() {
      service = OfflineSummaryService();
    });

    test('generateSummary handles empty transcript gracefully', () {
      final summary = service.generateSummary('');
      expect(summary, contains('## Overview'));
      expect(summary, contains('## Key Points'));
      expect(summary, contains('## Action Items'));
      expect(summary, contains('## Keywords'));
      expect(summary, contains('- None'));
    });

    test('generateSummary produces all 4 Fireflies-style sections', () {
      const transcript =
          'Rapat hari ini membahas peluncuran fitur transkripsi offline untuk aplikasi mobile. '
          'Tim engineering telah menyelesaikan integrasi Whisper cpp di Android. '
          'Kita harus menyelesaikan pengujian sebelum hari Jumat. '
          'Tolong kirimkan laporan bug kepada lead developer.';

      final summary = service.generateSummary(transcript);

      expect(summary, contains('## Overview'));
      expect(summary, contains('## Key Points'));
      expect(summary, contains('## Action Items'));
      expect(summary, contains('## Keywords'));

      // Check action items detection
      expect(summary, contains('- [ ]'));
      expect(summary, contains('harus'));
      expect(summary, contains('Tolong'));
    });

    test('generateSummary writes "- None" when no action cues present', () {
      const transcript =
          'Cuaca hari ini cukup cerah di Jakarta. '
          'Banyak orang berjalan santai di sekitar taman kota.';

      final summary = service.generateSummary(transcript);
      expect(summary, contains('## Action Items\n- None'));
    });
  });
}
