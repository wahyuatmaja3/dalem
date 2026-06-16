import 'package:flutter_test/flutter_test.dart';
import 'package:dalem/features/dashboard/data/category_constants.dart';

void main() {
  group('mergeCategories', () {
    test('presets come first', () {
      final result = mergeCategories(['Custom A']);
      expect(result.take(kPresetCategories.length).toList(), kPresetCategories);
      expect(result.last, 'Custom A');
    });

    test('dedupes custom that matches a preset', () {
      final result = mergeCategories(['Work', 'Custom B']);
      expect(result.where((c) => c == 'Work').length, 1);
      expect(result.contains('Custom B'), true);
    });

    test('empty custom returns presets only', () {
      expect(mergeCategories([]), kPresetCategories);
    });
  });
}
