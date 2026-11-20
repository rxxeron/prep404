/// Universal Ascending Natural Sorter for Prep404
/// Enforces consistent ordering across all dropdowns, catalogs, and lists:
/// 1. Letters A - Z (case-insensitive) come FIRST
/// 2. Followed by Numbers 0 - 9
/// 3. Natural numerical chunk comparison (e.g. "HSC '23" < "HSC '24" < "HSC '26")
class AppSorter {
  AppSorter._();

  /// Compares two strings using the "A-Z then 0-9" ascending rule.
  static int compareAZ09(String a, String b) {
    final cleanA = a.trim();
    final cleanB = b.trim();
    if (cleanA.isEmpty && cleanB.isEmpty) return 0;
    if (cleanA.isEmpty) return 1;
    if (cleanB.isEmpty) return -1;

    final isLetterA = RegExp(r'^[a-zA-Z]').hasMatch(cleanA);
    final isLetterB = RegExp(r'^[a-zA-Z]').hasMatch(cleanB);
    final isDigitA = RegExp(r'^[0-9]').hasMatch(cleanA);
    final isDigitB = RegExp(r'^[0-9]').hasMatch(cleanB);

    // Rule: Letters A-Z come first, followed by digits 0-9
    if (isLetterA && isDigitB) return -1;
    if (isDigitA && isLetterB) return 1;

    // Natural alphanumeric chunk comparison
    return _naturalCompare(cleanA, cleanB);
  }

  static int _naturalCompare(String a, String b) {
    final aLower = a.toLowerCase();
    final bLower = b.toLowerCase();

    final reg = RegExp(r'(\d+|\D+)');
    final aMatches = reg.allMatches(aLower).map((m) => m.group(0)!).toList();
    final bMatches = reg.allMatches(bLower).map((m) => m.group(0)!).toList();

    final minLen =
        aMatches.length < bMatches.length ? aMatches.length : bMatches.length;

    for (int i = 0; i < minLen; i++) {
      final aChunk = aMatches[i];
      final bChunk = bMatches[i];

      final aNum = int.tryParse(aChunk);
      final bNum = int.tryParse(bChunk);

      if (aNum != null && bNum != null) {
        final diff = aNum.compareTo(bNum);
        if (diff != 0) return diff;
      } else {
        final diff = aChunk.compareTo(bChunk);
        if (diff != 0) return diff;
      }
    }

    return aMatches.length.compareTo(bMatches.length);
  }

  /// Returns a new list sorted in Ascending order (A - Z, then 0 - 9)
  static List<String> sortStrings(List<String> list) {
    final copy = List<String>.from(list);
    copy.sort(compareAZ09);
    return copy;
  }

  /// Sorts models in Ascending order using a string key extractor
  static List<T> sortBy<T>(List<T> list, String Function(T) keySelector) {
    final copy = List<T>.from(list);
    copy.sort((a, b) => compareAZ09(keySelector(a), keySelector(b)));
    return copy;
  }
}
