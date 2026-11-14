// SPDX-License-Identifier: GPL-3.0-or-later

/// Names of the kinds of entity, as written in sync operations (PRD 8.6),
/// and the field that links each kind to the entity it hangs from.
abstract final class EntityKinds {
  /// A trip.
  static const String trip = 'Trip';

  /// A participant of a trip.
  static const String participant = 'Participant';

  /// A segment of a trip.
  static const String segment = 'Segment';

  /// A day of a trip.
  static const String day = 'Day';

  /// A position in a day.
  static const String stopSlot = 'StopSlot';

  /// A stop.
  static const String stop = 'Stop';

  /// The link between two positions of a day.
  static const String legSlot = 'LegSlot';

  /// A leg.
  static const String leg = 'Leg';

  /// A booking.
  static const String booking = 'Booking';

  /// A lodging.
  static const String lodging = 'Lodging';

  /// An attachment.
  static const String attachment = 'Attachment';

  /// An expense.
  static const String expense = 'Expense';

  /// A loan between participants.
  static const String loan = 'Loan';

  /// A repayment between participants.
  static const String repayment = 'Repayment';

  /// A note.
  static const String note = 'Note';

  /// Field holding the identifier of the parent, for the kinds that hang
  /// from something other than the trip itself. The database indexes it, so
  /// that the stops of a day or the legs of a leg slot are found quickly.
  static const Map<String, String> parentField = {
    stopSlot: 'dayId',
    stop: 'slotId',
    legSlot: 'dayId',
    leg: 'legSlotId',
    attachment: 'ownerId',
  };

  /// Identifier of the parent of an entity of kind [entity] with the given
  /// [fields], or null if the kind has no parent field or it is not set.
  static String? parentOf(String entity, Map<String, Object?> fields) {
    final value = fields[parentField[entity]];
    return value is String ? value : null;
  }
}
