// SPDX-License-Identifier: GPL-3.0-or-later

/// Reading and writing amounts of money as text, without ever going through
/// a floating point number (PRD 8.1).
abstract final class MoneyText {
  /// Reads an amount typed by a person and returns it in minor units, for a
  /// currency with [decimalDigits] decimals (2 for the euro, 0 for the yen).
  ///
  /// Both the comma and the dot are accepted as decimal separator, since the
  /// same person may use either. Returns null if the text is not an amount:
  /// empty, negative, with letters, with more decimals than the currency has
  /// or with separators that leave doubt about the value.
  static int? parse(String text, {required int decimalDigits}) {
    final match = _amount.firstMatch(text.trim());
    if (match == null) return null;
    final units = match.group(1)!;
    final decimals = match.group(2) ?? '';
    if (decimals.length > decimalDigits) return null;
    return int.tryParse(units + decimals.padRight(decimalDigits, '0'));
  }

  /// Writes [amountMinor] as plain digits with [separator] before the
  /// decimals, for an edit field. Formatting for display is done with the
  /// locale of the user.
  static String format(
    int amountMinor, {
    required int decimalDigits,
    String separator = '.',
  }) {
    if (decimalDigits == 0) return '$amountMinor';
    final digits = amountMinor.abs().toString().padLeft(decimalDigits + 1, '0');
    final split = digits.length - decimalDigits;
    return '${amountMinor < 0 ? '-' : ''}${digits.substring(0, split)}'
        '$separator${digits.substring(split)}';
  }

  // Digits, then optionally one separator and more digits. No sign, no
  // thousands separators: "1.234" would be read as one and a bit, so grouping
  // is never guessed.
  static final RegExp _amount = RegExp(r'^(\d{1,12})(?:[.,](\d+))?$');
}
