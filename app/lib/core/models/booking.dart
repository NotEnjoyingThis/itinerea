// SPDX-License-Identifier: GPL-3.0-or-later

import 'ids.dart';
import 'money.dart';
import 'place.dart';
import 'synced_entity.dart';
import 'time.dart';

/// Kind of a booking (PRD 8.3).
enum BookingType {
  /// A flight.
  flight,

  /// A train journey.
  train,

  /// A bus journey.
  bus,

  /// A ferry crossing.
  ferry,

  /// A place to sleep.
  lodging,

  /// A ticket for an attraction.
  attraction,

  /// A rented car.
  carRental,

  /// A table at a restaurant.
  restaurant,

  /// Anything else.
  other,
}

/// How a booking was created (PRD 8.3, F2.3).
enum BookingSource {
  /// Entered by hand.
  manual,

  /// Read from schema.org data in an e-mail.
  schemaOrg,

  /// Read from the barcode of a boarding pass.
  bcbp,

  /// Read from a PDF with a parsing rule.
  pdfRule,
}

/// Kind of lodging (PRD 8.3).
enum LodgingType {
  /// A hotel or similar.
  hotel,

  /// A campsite.
  camping,

  /// A camper area.
  camperArea,

  /// A night in the car.
  carNight,

  /// Anything else.
  other,
}

/// What an attachment belongs to (PRD 8.3).
enum AttachmentOwnerType {
  /// A stop.
  stop,

  /// A leg.
  leg,

  /// A booking.
  booking,

  /// An expense.
  expense,
}

/// A booking (PRD 8.3).
// TODO(M5 F1.9): manual entry. TODO(Fase 2 F2.3): automatic import.
class Booking extends SyncedEntity {
  /// Creates a booking.
  const Booking({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.tripId,
    required this.type,
    required this.title,
    super.deletedAt,
    this.start,
    this.end,
    this.fromPlace,
    this.toPlace,
    this.confirmationCode,
    this.provider,
    this.cost,
    this.paid = false,
    this.details = const {},
    this.source = BookingSource.manual,
    this.needsReview = false,
    this.attachmentIds = const [],
  });

  /// Trip the booking belongs to.
  final EntityId tripId;

  /// Kind of booking.
  final BookingType type;

  /// Title shown in lists.
  final String title;

  /// Start, local time with its zone.
  final ZonedLocalDateTime? start;

  /// End, local time with its zone.
  final ZonedLocalDateTime? end;

  /// Departure place, for transport.
  final PlaceSnapshot? fromPlace;

  /// Arrival place, for transport.
  final PlaceSnapshot? toPlace;

  /// Confirmation code.
  final String? confirmationCode;

  /// Company the booking was made with, for example an airline.
  final String? provider;

  /// Cost; it enters the budget.
  final Money? cost;

  /// True if already paid.
  final bool paid;

  /// Details that depend on the kind: flight number, terminal, seat…
  final Map<String, Object?> details;

  /// How the booking was created.
  final BookingSource source;

  /// True while the data read from a file still has to be checked (F2.3).
  final bool needsReview;

  /// Attachments of the booking.
  final List<EntityId> attachmentIds;
}

/// A place to sleep for one or more nights (PRD 8.3, F1.2).
///
/// Always optional: a day without a lodging is normal ("to be decided") and
/// never raises a warning. Only the name is required; it can be added by
/// hand in a few taps, without a booking and offline. The times of a day
/// never depend on it.
// TODO(M5 F1.2): adding a lodging by hand and showing it in the day header.
// TODO(M5 F1.9): lodgings created from bookings.
class Lodging extends SyncedEntity {
  /// Creates a lodging.
  const Lodging({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.tripId,
    required this.name,
    required this.firstDayId,
    super.deletedAt,
    this.nights = 1,
    this.type = LodgingType.other,
    this.place,
    this.checkIn,
    this.checkOut,
    this.bookingId,
    this.cost,
  });

  /// Trip the lodging belongs to.
  final EntityId tripId;

  /// Kind of lodging.
  final LodgingType type;

  /// Name of the lodging: the only thing the user must give.
  final String name;

  /// Where it is.
  final PlaceSnapshot? place;

  /// Day of the first night. It refers to a day, not to a date, so that it
  /// also works in a trip without dates.
  final EntityId firstDayId;

  /// Number of consecutive nights, at least one.
  final int nights;

  /// Time of arrival on the first day, if known.
  final LocalTime? checkIn;

  /// Time of departure after the last night, if known.
  final LocalTime? checkOut;

  /// Booking tied to the lodging.
  final EntityId? bookingId;

  /// Cost, only when there is no booking with a cost.
  final Money? cost;
}

/// A file attached to a stop, a leg, a booking or an expense (PRD 8.3).
///
/// The file itself lives in the attachments folder under its SHA-256.
// TODO(M5 F1.8): import with size limits; attachments are untrusted files.
class Attachment extends SyncedEntity {
  /// Creates an attachment.
  const Attachment({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.sha256,
    required this.mimeType,
    required this.fileName,
    required this.sizeBytes,
    required this.ownerType,
    required this.ownerId,
    super.deletedAt,
    this.isTicket = false,
    this.barcode,
  });

  /// SHA-256 of the file, in hexadecimal.
  final String sha256;

  /// Media type of the file.
  final String mimeType;

  /// Original file name.
  final String fileName;

  /// Size in bytes.
  final int sizeBytes;

  /// Kind of entity the attachment belongs to.
  final AttachmentOwnerType ownerType;

  /// Entity the attachment belongs to.
  final EntityId ownerId;

  /// True if it is shown in the full-screen ticket view.
  final bool isTicket;

  /// Data read from a barcode in the file, if any.
  final String? barcode;
}

/// A note (PRD 8.3).
class Note extends SyncedEntity {
  /// Creates a note.
  const Note({
    required super.id,
    required super.createdAt,
    required super.createdBy,
    required this.text,
    super.deletedAt,
  });

  /// Text of the note.
  final String text;
}

/// A saved version of a note (PRD 8.3).
// TODO(Fase 2 F2.1): version history with a configurable maximum.
class NoteVersion {
  /// Creates a version.
  const NoteVersion({
    required this.noteId,
    required this.text,
    required this.author,
    required this.hlc,
  });

  /// Note the version belongs to.
  final EntityId noteId;

  /// Text of the note in this version.
  final String text;

  /// Participant that saved the version.
  final EntityId author;

  /// Clock value of the save.
  final Hlc hlc;
}
