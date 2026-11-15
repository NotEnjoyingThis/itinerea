// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/models/time.dart';
import 'package:itinerea/core/models/trip.dart';
import 'package:itinerea/features/trips/trip_plan.dart';

TripDraft _draft({
  String name = 'Toscana in moto',
  int dayCount = 4,
  SegmentType type = SegmentType.itinerary,
  VehicleKind? vehicleKind,
  LocalDate? startDate,
}) => TripDraft(
  type: type,
  vehicleKind: vehicleKind,
  name: name,
  dayCount: dayCount,
  startDate: startDate,
  timezone: 'Europe/Rome',
  currency: 'EUR',
);

/// Days 1..[count] of a trip that starts on [start], each with the number of
/// stops given in [stops] (by day index).
List<DayInfo> _days(
  int count, {
  LocalDate? start,
  Map<int, int> stops = const {},
}) => [
  for (var index = 1; index <= count; index++)
    DayInfo(
      id: EntityId('day-$index'),
      index: index,
      date: TripDays.dateOf(start, index),
      stopCount: stops[index] ?? 0,
    ),
];

void main() {
  group('dates', () {
    test('exist or are refused', () {
      expect(LocalDate(2028, 2, 29).toIso(), '2028-02-29');
      expect(() => LocalDate(2026, 2, 29), throwsArgumentError);
      expect(() => LocalDate(2026, 13, 1), throwsArgumentError);
      expect(() => LocalDate.parse('2026-02-30'), throwsFormatException);
      expect(() => LocalDate.parse('12/03/2026'), throwsFormatException);
    });

    test('add days across months, years and daylight saving changes', () {
      expect(LocalDate(2026, 12, 30).addDays(3), LocalDate(2027, 1, 2));
      expect(LocalDate(2026, 3, 1).addDays(-1), LocalDate(2026, 2, 28));
      // 29 March 2026 has 23 hours in Italy: still one day.
      expect(LocalDate(2026, 3, 28).addDays(2), LocalDate(2026, 3, 30));
      expect(LocalDate(2026, 3, 28).daysUntil(LocalDate(2026, 3, 30)), 2);
      expect(LocalDate(2026, 10, 24).daysUntil(LocalDate(2026, 10, 26)), 2);
    });

    test('know their day of the week and their order', () {
      expect(LocalDate(2026, 3, 13).weekday, DateTime.friday);
      expect(
        LocalDate(2026, 3, 12).compareTo(LocalDate(2026, 3, 13)),
        isNegative,
      );
      expect(LocalDate.parse('2026-03-12'), LocalDate(2026, 3, 12));
    });

    test('times are read and written as HH:MM', () {
      expect(LocalTime.parse('09:05'), const LocalTime(9, 5));
      expect(const LocalTime(18, 30).toIso(), '18:30');
      expect(const LocalTime(9, 0).minuteOfDay, 540);
      for (final text in ['9:05', '24:00', '12:60', 'noon']) {
        expect(
          () => LocalTime.parse(text),
          throwsFormatException,
          reason: text,
        );
      }
    });
  });

  group('a new trip', () {
    test('needs a name and at least one day', () {
      expect(_draft().problems, isEmpty);
      expect(_draft(name: '  ').problems, [TripDraftProblem.missingName]);
      expect(_draft(dayCount: 0).problems, [TripDraftProblem.noDays]);
      expect(_draft(dayCount: 366).problems, [TripDraftProblem.tooManyDays]);
    });

    test('of kind roadtrip needs a car or a motorbike', () {
      expect(_draft(type: SegmentType.roadtrip).problems, [
        TripDraftProblem.missingVehicle,
      ]);
      expect(
        _draft(
          type: SegmentType.roadtrip,
          vehicleKind: VehicleKind.motorbike,
        ).problems,
        isEmpty,
      );
    });

    test('with dates ends on its last day; without dates has no end', () {
      expect(
        _draft(startDate: LocalDate(2026, 3, 12), dayCount: 4).endDate,
        LocalDate(2026, 3, 15),
      );
      expect(_draft(dayCount: 4).endDate, isNull);
      expect(
        TripDays.countBetween(LocalDate(2026, 3, 12), LocalDate(2026, 3, 15)),
        4,
      );
      expect(
        TripDays.countBetween(LocalDate(2026, 3, 12), LocalDate(2026, 3, 12)),
        1,
      );
    });
  });

  group('changing the dates of a trip (F1.1)', () {
    final start = LocalDate(2026, 3, 12);

    test('a later end adds days at the end', () {
      final plan = TripDays.planChange(
        existing: _days(3, start: start),
        newStart: start,
        newCount: 5,
      );

      expect(plan.redated, isEmpty);
      expect(plan.removed, isEmpty);
      expect(plan.added, [
        (index: 4, date: LocalDate(2026, 3, 15)),
        (index: 5, date: LocalDate(2026, 3, 16)),
      ]);
    });

    test('an earlier end removes days from the end', () {
      final plan = TripDays.planChange(
        existing: _days(5, start: start),
        newStart: start,
        newCount: 3,
      );

      expect(plan.removed.map((day) => day.index), [4, 5]);
      expect(plan.added, isEmpty);
      expect(plan.needsDecision, isFalse);
    });

    test('removing a day that has stops needs a decision first', () {
      final plan = TripDays.planChange(
        existing: _days(5, start: start, stops: {2: 3, 4: 2, 5: 1}),
        newStart: start,
        newCount: 3,
      );

      expect(plan.needsDecision, isTrue);
      expect(plan.stopsInRemovedDays, 3);
    });

    test(
      'a different start gives every day its new date and moves no stop',
      () {
        final plan = TripDays.planChange(
          existing: _days(3, start: start, stops: {1: 2, 3: 4}),
          newStart: LocalDate(2026, 4, 1),
          newCount: 3,
        );

        expect(plan.redated.map((day) => (day.id.value, day.date)), [
          ('day-1', LocalDate(2026, 4, 1)),
          ('day-2', LocalDate(2026, 4, 2)),
          ('day-3', LocalDate(2026, 4, 3)),
        ]);
        expect(plan.added, isEmpty);
        expect(plan.removed, isEmpty);
        expect(plan.needsDecision, isFalse);
      },
    );

    test('a trip with only a number of days gets its dates later', () {
      final plan = TripDays.planChange(
        existing: _days(4, stops: {1: 2, 2: 1}),
        newStart: start,
        newCount: 4,
      );

      expect(plan.redated.map((day) => day.date), [
        LocalDate(2026, 3, 12),
        LocalDate(2026, 3, 13),
        LocalDate(2026, 3, 14),
        LocalDate(2026, 3, 15),
      ]);
      expect(plan.removed, isEmpty);
      expect(plan.needsDecision, isFalse);
    });

    test('taking the dates away leaves "Day 1, Day 2" without dates', () {
      final plan = TripDays.planChange(
        existing: _days(2, start: start),
        newStart: null,
        newCount: 2,
      );

      expect(plan.redated.map((day) => day.date), [null, null]);
    });

    test('the same dates change nothing', () {
      final plan = TripDays.planChange(
        existing: _days(3, start: start),
        newStart: start,
        newCount: 3,
      );

      expect(plan.isEmpty, isTrue);
    });

    test('a number of days out of range is refused', () {
      for (final count in [0, -1, 366]) {
        expect(
          () => TripDays.planChange(
            existing: _days(3),
            newStart: null,
            newCount: count,
          ),
          throwsArgumentError,
        );
      }
    });
  });

  group('segments (F1.1, FL8)', () {
    const itinerary = SegmentInfo(
      id: EntityId('segment-1'),
      type: SegmentType.itinerary,
      startDayIndex: 1,
    );
    const roadtripFrom5 = SegmentInfo(
      id: EntityId('segment-2'),
      type: SegmentType.roadtrip,
      startDayIndex: 5,
      vehicleKind: VehicleKind.car,
    );

    test('a day belongs to the last segment that starts on or before it', () {
      const segments = [roadtripFrom5, itinerary];

      expect(Segments.ofDay(segments, 1).id, itinerary.id);
      expect(Segments.ofDay(segments, 4).id, itinerary.id);
      expect(Segments.ofDay(segments, 5).id, roadtripFrom5.id);
      expect(Segments.ofDay(segments, 9).id, roadtripFrom5.id);
    });

    test(
      'roadtrip functions appear only in the days of a roadtrip segment',
      () {
        const segments = [itinerary, roadtripFrom5];

        expect(
          [
            for (var day = 1; day <= 7; day++)
              Segments.isRoadtripDay(segments, day),
          ],
          [false, false, false, false, true, true, true],
        );
      },
    );

    test('"from day 5: roadtrip" on an itinerary starts a new segment', () {
      final change = Segments.changeFromDay(
        segments: const [itinerary],
        dayIndex: 5,
        type: SegmentType.roadtrip,
        vehicleKind: VehicleKind.motorbike,
      );

      expect(change.create, (
        startDayIndex: 5,
        type: SegmentType.roadtrip,
        vehicleKind: VehicleKind.motorbike,
      ));
      expect(change.update, isNull);
      expect(change.delete, isEmpty);
    });

    test('putting the previous kind back undoes the split', () {
      final change = Segments.changeFromDay(
        segments: const [itinerary, roadtripFrom5],
        dayIndex: 5,
        type: SegmentType.itinerary,
      );

      expect(change.delete, [roadtripFrom5.id]);
      expect(change.create, isNull);
      expect(change.update, isNull);
    });

    test('the same kind as now changes nothing', () {
      for (final day in [1, 3]) {
        expect(
          Segments.changeFromDay(
            segments: const [itinerary, roadtripFrom5],
            dayIndex: day,
            type: SegmentType.itinerary,
          ).isEmpty,
          isTrue,
        );
      }
      expect(
        Segments.changeFromDay(
          segments: const [itinerary, roadtripFrom5],
          dayIndex: 6,
          type: SegmentType.roadtrip,
          vehicleKind: VehicleKind.car,
        ).isEmpty,
        isTrue,
      );
    });

    test('changing the first day changes the first segment, not a new one', () {
      final change = Segments.changeFromDay(
        segments: const [itinerary],
        dayIndex: 1,
        type: SegmentType.roadtrip,
        vehicleKind: VehicleKind.car,
      );

      expect(change.update, (
        id: itinerary.id,
        type: SegmentType.roadtrip,
        vehicleKind: VehicleKind.car,
      ));
      expect(change.create, isNull);
    });

    test('a different vehicle is a different kind of roadtrip', () {
      final change = Segments.changeFromDay(
        segments: const [itinerary, roadtripFrom5],
        dayIndex: 5,
        type: SegmentType.roadtrip,
        vehicleKind: VehicleKind.motorbike,
      );

      expect(change.update?.vehicleKind, VehicleKind.motorbike);
      expect(change.delete, isEmpty);
    });

    test('a change that reaches a segment of the same kind absorbs it', () {
      // Days 1-4 itinerary, 5+ roadtrip by car. "From day 3: roadtrip by car"
      // makes the segment of day 5 redundant.
      final change = Segments.changeFromDay(
        segments: const [itinerary, roadtripFrom5],
        dayIndex: 3,
        type: SegmentType.roadtrip,
        vehicleKind: VehicleKind.car,
      );

      expect(change.create?.startDayIndex, 3);
      expect(change.delete, [roadtripFrom5.id]);
    });

    test('an itinerary never carries a vehicle', () {
      final change = Segments.changeFromDay(
        segments: [roadtripFrom5.copyAsFirst],
        dayIndex: 3,
        type: SegmentType.itinerary,
        vehicleKind: VehicleKind.car,
      );

      expect(change.create?.vehicleKind, isNull);
    });
  });
}

extension on SegmentInfo {
  /// The same segment, starting on day 1.
  SegmentInfo get copyAsFirst => SegmentInfo(
    id: id,
    type: type,
    startDayIndex: 1,
    vehicleKind: vehicleKind,
  );
}
