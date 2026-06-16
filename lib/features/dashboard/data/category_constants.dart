const List<String> kPresetCategories = [
  'Meeting',
  'Personal',
  'Ideas',
  'Work',
  'Other',
];

/// Presets first, then custom categories not already in presets (order preserved, deduped).
List<String> mergeCategories(List<String> custom) {
  final seen = kPresetCategories.toSet();
  final result = <String>[...kPresetCategories];
  for (final c in custom) {
    if (c.isNotEmpty && !seen.contains(c)) {
      seen.add(c);
      result.add(c);
    }
  }
  return result;
}
