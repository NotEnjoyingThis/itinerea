// SPDX-License-Identifier: GPL-3.0-or-later

/// An amount of money (PRD 8.1): an integer in minor units plus a currency.
///
/// Amounts are never stored as floating point numbers.
// TODO(M5 F1.10): arithmetic, currency exponents and formatting.
class Money {
  /// Creates an amount of [amountMinor] minor units of [currency].
  const Money({required this.amountMinor, required this.currency});

  /// Amount in minor units (cents, yen…).
  final int amountMinor;

  /// ISO 4217 currency code, for example EUR.
  final String currency;
}
