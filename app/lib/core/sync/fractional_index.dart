// SPDX-License-Identifier: GPL-3.0-or-later

/// Order keys for lists that several devices can reorder (PRD 4.3, 8.1).
///
/// A key is a text read as a fraction between 0 and 1, written with the
/// digits 0-9, A-Z, a-z (in this order, which is also their order as text).
/// Moving an item only changes the key of that item: [between] returns a key
/// that sorts after one neighbour and before the other.
///
/// Two devices that insert at the same place while offline get the **same**
/// key, because the calculation is deterministic. The order of a list is
/// therefore always given by key and identifier together: see [compare].
abstract final class FractionalIndex {
  static const String _digits =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  static final RegExp _valid = RegExp(r'^[0-9A-Za-z]*[1-9A-Za-z]$');

  /// True if [key] is a well-formed order key: not empty, only the allowed
  /// digits, and not ending with the digit 0 (a key ending with 0 would leave
  /// no room before it).
  static bool isValid(String key) => _valid.hasMatch(key);

  /// Returns a key that sorts after [after] and before [before].
  ///
  /// A null [after] means "before everything", a null [before] means "after
  /// everything". Throws an [ArgumentError] if a key is malformed or if
  /// [after] does not sort before [before]: in particular there is no key
  /// between two equal keys.
  static String between(String? after, String? before) {
    if (after != null && !isValid(after)) {
      throw ArgumentError.value(after, 'after', 'Malformed order key');
    }
    if (before != null && !isValid(before)) {
      throw ArgumentError.value(before, 'before', 'Malformed order key');
    }
    if (after != null && before != null && after.compareTo(before) >= 0) {
      throw ArgumentError('No key exists between "$after" and "$before"');
    }
    return _midpoint(after ?? '', before);
  }

  /// Returns [count] keys in ascending order, all between [after] and
  /// [before]. Used to fill a new list.
  static List<String> spread(int count, {String? after, String? before}) {
    final keys = <String>[];
    var previous = after;
    for (var i = 0; i < count; i++) {
      final key = between(previous, before);
      keys.add(key);
      previous = key;
    }
    return keys;
  }

  /// Works out the key for an item inserted at position [index] of a list
  /// already in order, given as (identifier, key) pairs.
  ///
  /// Normally only the new item gets a key. When the items before and after
  /// the position have the **same** key (two devices inserted at the same
  /// place while offline), no key fits between them: the items that share
  /// that key and come after the position get new keys too, returned in
  /// `rekeyed`. The order of the existing items never changes.
  static ({String key, Map<String, String> rekeyed}) planInsert(
    List<({String id, String key})> ordered,
    int index,
  ) {
    RangeError.checkValueInInterval(index, 0, ordered.length, 'index');
    final before = index > 0 ? ordered[index - 1].key : null;
    final after = index < ordered.length ? ordered[index].key : null;
    if (before == null || after == null || before.compareTo(after) < 0) {
      return (key: between(before, after), rekeyed: const {});
    }
    // The run of items after the position that share the key of [before].
    var end = index;
    while (end < ordered.length && ordered[end].key == before) {
      end++;
    }
    final keys = spread(
      end - index + 1,
      after: before,
      before: end < ordered.length ? ordered[end].key : null,
    );
    return (
      key: keys.first,
      rekeyed: {
        for (var i = index; i < end; i++) ordered[i].id: keys[i - index + 1],
      },
    );
  }

  /// Orders two items of a list: by key, and by identifier when the keys are
  /// equal. Every device uses this rule, so every device shows the same
  /// order even when two of them produced the same key (PRD 9.5).
  static int compare(String keyA, String idA, String keyB, String idB) {
    final byKey = keyA.compareTo(keyB);
    return byKey != 0 ? byKey : idA.compareTo(idB);
  }

  /// Midpoint of the fractions [a] and [b]; an empty [a] is zero and a null
  /// [b] is one. Requires a < b.
  static String _midpoint(String a, String? b) {
    if (b != null) {
      // Shared leading digits are kept; a shorter [a] counts as padded with
      // zeros.
      var n = 0;
      while (n < b.length && (n < a.length ? a[n] : _digits[0]) == b[n]) {
        n++;
      }
      if (n > 0) {
        return b.substring(0, n) +
            _midpoint(n < a.length ? a.substring(n) : '', b.substring(n));
      }
    }
    final digitA = a.isEmpty ? 0 : _digits.indexOf(a[0]);
    final digitB = b == null ? _digits.length : _digits.indexOf(b[0]);
    if (digitB - digitA > 1) {
      return _digits[(digitA + digitB) ~/ 2];
    }
    // The first digits are neighbours.
    if (b != null && b.length > 1) {
      return b.substring(0, 1);
    }
    return _digits[digitA] + _midpoint(a.isEmpty ? '' : a.substring(1), null);
  }
}
