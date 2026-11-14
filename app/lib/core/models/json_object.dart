// SPDX-License-Identifier: GPL-3.0-or-later

/// Reading helpers for the embedded objects of PRD 8.3 (a place, a split, an
/// amount…), which are stored and synchronised as one JSON object each.
///
/// An embedded object counts as a single field: whoever writes it writes the
/// whole object (PRD 8.1). So that an older version of the app never deletes
/// what a newer one wrote, every embedded class keeps the keys it does not
/// know in an `unknown` map and writes them back unchanged.
extension type const JsonObject(Map<String, Object?> json) {
  /// Reads the required value of [key], which must be a [T].
  ///
  /// Throws a [FormatException] if it is missing or of another type.
  T read<T extends Object>(String key) {
    final value = json[key];
    if (value is T) return value;
    throw FormatException('Missing or invalid "$key"', json);
  }

  /// Reads the optional value of [key]: null if missing or null.
  ///
  /// Throws a [FormatException] if it is present with another type.
  T? readOptional<T extends Object>(String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is T) return value;
    throw FormatException('Invalid "$key"', json);
  }

  /// Reads the required JSON object under [key].
  JsonObject object(String key) =>
      JsonObject(read<Map<Object?, Object?>>(key).cast<String, Object?>());

  /// Reads the required list of JSON objects under [key].
  List<JsonObject> objects(String key) => [
    for (final item in read<List<Object?>>(key))
      if (item is Map<Object?, Object?>)
        JsonObject(item.cast<String, Object?>())
      else
        throw FormatException('Invalid item in "$key"', json),
  ];

  /// The keys of the object that are not in [known], with their values: the
  /// part written by a newer version of the app.
  Map<String, Object?> unknownExcept(Set<String> known) => {
    for (final MapEntry(:key, :value) in json.entries)
      if (!known.contains(key)) key: value,
  };
}
