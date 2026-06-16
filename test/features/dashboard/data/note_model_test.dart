import 'package:flutter_test/flutter_test.dart';
import 'package:dalem/features/dashboard/data/models/note_model.dart';

void main() {
  final base = NoteModel(
    id: 'n1',
    title: 'Hello',
    createdAt: DateTime.parse('2026-06-16T10:00:00.000'),
    status: NoteStatus.processed,
    category: 'Work',
  );

  group('NoteModel category', () {
    test('toJson includes category', () {
      expect(base.toJson()['category'], 'Work');
    });

    test('fromJson reads category', () {
      final note = NoteModel.fromJson(base.toJson());
      expect(note.category, 'Work');
    });

    test('fromJson tolerates missing category', () {
      final json = base.toJson()..remove('category');
      final note = NoteModel.fromJson(json);
      expect(note.category, isNull);
    });

    test('copyWith overrides category', () {
      expect(base.copyWith(category: 'Personal').category, 'Personal');
    });

    test('copyWith keeps category when omitted', () {
      expect(base.copyWith(title: 'New').category, 'Work');
    });
  });
}
