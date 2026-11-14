// SPDX-License-Identifier: GPL-3.0-or-later

import 'json_object.dart';

/// An amount of money (PRD 8.1): an integer in minor units plus a currency.
///
/// Amounts are never stored as floating point numbers.
// TODO(M5 F1.10): arithmetic, currency exponents and formatting.
class Money {
  /// Creates an amount of [amountMinor] minor units of [currency].
  const Money({
    required this.amountMinor,
    required this.currency,
    this.unknown = const {},
  });

  /// Reads an amount from its JSON object.
  ///
  /// Throws a [FormatException] if the amount is not an integer: a decimal
  /// number is never accepted.
  factory Money.fromJson(Map<String, Object?> json) {
    final object = JsonObject(json);
    return Money(
      amountMinor: object.read<int>(_amount),
      currency: object.read<String>(_currency),
      unknown: object.unknownExcept(const {_amount, _currency}),
    );
  }

  static const String _amount = 'amountMinor';
  static const String _currency = 'currency';

  /// Amount in minor units (cents, yen…).
  final int amountMinor;

  /// ISO 4217 currency code, for example EUR.
  final String currency;

  /// Keys written by a newer version of the app, kept as they are.
  final Map<String, Object?> unknown;

  /// The amount as a JSON object, unknown keys included.
  Map<String, Object?> toJson() => {
    ...unknown,
    _amount: amountMinor,
    _currency: currency,
  };
}
