// SPDX-License-Identifier: GPL-3.0-or-later

import 'ids.dart';
import 'json_object.dart';
import 'money.dart';
import 'synced_entity.dart';
import 'time.dart';

/// Category of an expense (PRD 8.3).
enum ExpenseCategory {
  /// Places to sleep.
  lodging,

  /// Tickets and transport.
  transport,

  /// Food and drink.
  food,

  /// Activities and attractions.
  activities,

  /// Fuel and charging.
  fuel,

  /// Tolls and vignettes.
  tolls,

  /// Shopping.
  shopping,

  /// Anything else.
  other,
}

/// How an expense is divided among participants (PRD 8.3, F2.2).
enum SplitType {
  /// Equal parts.
  equal,

  /// Percentages that add up to 100.
  percent,

  /// Shares, for example 2 and 1.
  shares,

  /// Exact amounts that add up to the total.
  exact,
}

/// The part of one participant in a split (PRD 8.3).
class SplitEntry {
  /// Creates the part of [participantId].
  const SplitEntry({
    required this.participantId,
    required this.value,
    this.unknown = const {},
  });

  /// Reads the part of one participant from its JSON object.
  factory SplitEntry.fromJson(Map<String, Object?> json) {
    final object = JsonObject(json);
    return SplitEntry(
      participantId: EntityId(object.read<String>(_participantId)),
      value: object.read<int>(_value),
      unknown: object.unknownExcept(const {_participantId, _value}),
    );
  }

  static const String _participantId = 'participantId';
  static const String _value = 'value';

  /// Participant the part belongs to.
  final EntityId participantId;

  /// Percentage in hundredths, number of shares, or amount in minor units,
  /// depending on the split type. Always an integer.
  final int value;

  /// Keys written by a newer version of the app, kept as they are.
  final Map<String, Object?> unknown;

  /// The part as a JSON object, unknown keys included.
  Map<String, Object?> toJson() => {
    ...unknown,
    _participantId: participantId.value,
    _value: value,
  };
}

/// How an expense is divided, embedded in the expense (PRD 8.3).
///
/// Whether a split still fits the amount of its expense is checked by
/// `ExpenseCheck`, after every sync.
// TODO(Fase 2 F2.2): the amount each participant owes, with rounding.
class Split {
  /// Creates a split.
  const Split({
    required this.type,
    this.entries = const [],
    this.unknown = const {},
  });

  /// Reads a split from its JSON object.
  ///
  /// Throws a [FormatException] if the kind of split is one this version of
  /// the app does not know.
  factory Split.fromJson(Map<String, Object?> json) {
    final object = JsonObject(json);
    final type = SplitType.values.asNameMap()[object.read<String>(_type)];
    if (type == null) throw FormatException('Unknown kind of split', json);
    return Split(
      type: type,
      entries: [
        for (final entry in object.objects(_entries))
          SplitEntry.fromJson(entry.json),
      ],
      unknown: object.unknownExcept(const {_type, _entries}),
    );
  }

  static const String _type = 'type';
  static const String _entries = 'entries';

  /// Kind of split.
  final SplitType type;

  /// Part of each participant.
  final List<SplitEntry> entries;

  /// Keys written by a newer version of the app, kept as they are.
  final Map<String, Object?> unknown;

  /// The split as a JSON object, unknown keys included.
  Map<String, Object?> toJson() => {
    ...unknown,
    _type: type.name,
    _entries: [for (final entry in entries) entry.toJson()],
  };
}

/// An expense (PRD 8.3).
// TODO(M5 F1.10): entry, currency conversion and budget totals.
class Expense extends SyncedEntity {
  /// Creates an expense.
  const Expense({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.tripId,
    required this.date,
    required this.amount,
    required this.amountTripCurrency,
    required this.category,
    required this.paidBy,
    required this.split,
    super.deletedAt,
    this.dayId,
    this.fxRate,
    this.fxDate,
    this.fxPending = false,
    this.bookingId,
    this.receiptAttachmentId,
  });

  /// Trip the expense belongs to.
  final EntityId tripId;

  /// Date of the expense; it decides the exchange rate used.
  final LocalDate date;

  /// Day the expense belongs to.
  final EntityId? dayId;

  /// Amount in the original currency.
  final Money amount;

  /// Exchange rate to the trip currency, as a decimal string.
  final String? fxRate;

  /// Date of the exchange rate.
  final LocalDate? fxDate;

  /// True while the rate is provisional because the app was offline (F1.10).
  final bool fxPending;

  /// Amount in the trip currency; calculated.
  final Money amountTripCurrency;

  /// Category of the expense.
  final ExpenseCategory category;

  /// Participant that paid.
  final EntityId paidBy;

  /// How the expense is divided.
  final Split split;

  /// Booking the expense was generated from.
  final EntityId? bookingId;

  /// Photo of the receipt.
  final EntityId? receiptAttachmentId;
}

/// Money lent by one participant to another (PRD 8.3).
// TODO(Fase 2 F2.2): loans enter the settlement.
class Loan extends SyncedEntity {
  /// Creates a loan.
  const Loan({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.tripId,
    required this.from,
    required this.to,
    required this.amount,
    required this.date,
    super.deletedAt,
    this.noteId,
  });

  /// Trip the loan belongs to.
  final EntityId tripId;

  /// Participant that lent the money.
  final EntityId from;

  /// Participant that received the money.
  final EntityId to;

  /// Amount lent.
  final Money amount;

  /// Date of the loan.
  final LocalDate date;

  /// Note attached to the loan.
  final EntityId? noteId;
}

/// A debt that was paid back (PRD 8.3).
///
/// The settlement itself is never stored: it is calculated every time from
/// expenses, loans and repayments.
// TODO(Fase 2 F2.2): settlement with few payments.
class Repayment extends SyncedEntity {
  /// Creates a repayment.
  const Repayment({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.tripId,
    required this.from,
    required this.to,
    required this.amount,
    required this.date,
    super.deletedAt,
  });

  /// Trip the repayment belongs to.
  final EntityId tripId;

  /// Participant that paid back.
  final EntityId from;

  /// Participant that was paid back.
  final EntityId to;

  /// Amount paid back.
  final Money amount;

  /// Date of the repayment.
  final LocalDate date;
}
