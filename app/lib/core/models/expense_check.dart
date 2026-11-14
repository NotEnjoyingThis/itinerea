// SPDX-License-Identifier: GPL-3.0-or-later

import 'expense.dart';
import 'money.dart';

/// Why the split of an expense needs a person to look at it.
enum SplitProblem {
  /// The exact amounts do not add up to the amount of the expense.
  exactAmountsDoNotAddUp,

  /// The percentages do not add up to 100.
  percentagesDoNotAddUp,

  /// The split names nobody, or every share is zero.
  nobodyToCharge,

  /// A part is negative.
  negativePart,

  /// The expense has no readable amount or split: for example, the kind of
  /// split was written by a newer version of the app.
  unreadable,
}

/// Checks that the fields of an expense still fit together after a sync
/// (PRD 9.3, 9.5).
///
/// The amount and the split of an expense are separate fields: one person
/// can change the amount while another changes the split, and "the last
/// writer wins" keeps both changes. This check looks at the two together.
///
/// It is a calculation and writes nothing: it gives the same answer on
/// every device and creates no further change to synchronise.
abstract final class ExpenseCheck {
  /// One hundred percent, in hundredths of a percent.
  static const int fullPercent = 10000;

  /// Returns the problem of [split] for an expense of [amount], or null if
  /// the two fit together.
  ///
  /// Equal, percentage and share splits follow the amount: the parts are
  /// calculated from it, so they never stop adding up when it changes. A
  /// split in exact amounts carries its own numbers, and must be reviewed
  /// when they no longer add up to the amount.
  static SplitProblem? problemOf({
    required Money amount,
    required Split split,
  }) {
    final values = [for (final entry in split.entries) entry.value];
    if (values.any((value) => value < 0)) return SplitProblem.negativePart;
    final total = values.fold<int>(0, (sum, value) => sum + value);
    return switch (split.type) {
      SplitType.equal => values.isEmpty ? SplitProblem.nobodyToCharge : null,
      SplitType.shares => total == 0 ? SplitProblem.nobodyToCharge : null,
      SplitType.percent =>
        values.isEmpty
            ? SplitProblem.nobodyToCharge
            : (total == fullPercent
                  ? null
                  : SplitProblem.percentagesDoNotAddUp),
      SplitType.exact =>
        values.isEmpty
            ? SplitProblem.nobodyToCharge
            : (total == amount.amountMinor
                  ? null
                  : SplitProblem.exactAmountsDoNotAddUp),
    };
  }

  /// The same check on the stored fields of an expense. Fields that cannot
  /// be read give [SplitProblem.unreadable] instead of an error: the expense
  /// stays, marked for review.
  static SplitProblem? problemOfFields(Map<String, Object?> fields) {
    try {
      final amount = fields['amount'];
      final split = fields['split'];
      if (amount is! Map || split is! Map) return SplitProblem.unreadable;
      return problemOf(
        amount: Money.fromJson(amount.cast<String, Object?>()),
        split: Split.fromJson(split.cast<String, Object?>()),
      );
    } on FormatException {
      return SplitProblem.unreadable;
    }
  }

  /// True if the expense must be marked "to be reviewed" and left out of the
  /// settlement until someone fixes it.
  static bool needsReview(Map<String, Object?> fields) =>
      problemOfFields(fields) != null;
}
