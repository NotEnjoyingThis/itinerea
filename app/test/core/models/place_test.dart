// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/models/place.dart';
import 'package:itinerea/core/models/web_address.dart';

void main() {
  group('PlaceSnapshot', () {
    test('phone and website go through JSON with the unknown keys', () {
      final json = {
        'name': 'Galleria degli Uffizi',
        'coordinates': {'lat': 43.7683, 'lon': 11.2558},
        'osmId': 'W477279033',
        'openingHours': 'Tu-Su 08:15-18:30',
        'phone': '+39 055 294883',
        'website': 'https://www.uffizi.it',
        'fromANewerVersion': true,
      };

      final place = PlaceSnapshot.fromJson(json);

      expect(place.phone, '+39 055 294883');
      expect(place.website, 'https://www.uffizi.it');
      expect(place.toJson(), json);
    });

    test('copyWith replaces, clears with null and keeps the rest', () {
      const place = PlaceSnapshot(
        name: 'Uffizi',
        osmId: 'W477279033',
        phone: '+39 055 294883',
        website: 'https://www.uffizi.it',
        unknown: {'x': 1},
      );

      final changed = place.copyWith(phone: '055 1', website: null);

      expect(changed.phone, '055 1');
      expect(changed.website, isNull);
      expect(changed.name, 'Uffizi');
      expect(changed.osmId, 'W477279033');
      expect(changed.unknown, {'x': 1});
      expect(changed.toJson().containsKey('website'), isFalse);
    });
  });

  group('PlaceDetails', () {
    final downloaded = PlaceDetails(
      fetchedAt: DateTime.utc(2026, 11, 16, 10),
      openingHours: 'Tu-Su 08:15-18:30; Mo off',
      phone: '+39 055 294883',
      website: 'https://www.uffizi.it',
      wikidataId: 'Q51252',
    );

    test('go through the JSON of the cache', () {
      final read = PlaceDetails.fromJson(downloaded.toJson());

      expect(read.fetchedAt, downloaded.fetchedAt);
      expect(read.openingHours, downloaded.openingHours);
      expect(read.phone, downloaded.phone);
      expect(read.website, downloaded.website);
      expect(read.wikidataId, downloaded.wikidataId);
    });

    test('wrong values in the cache are ignored', () {
      final read = PlaceDetails.fromJson({
        'fetchedAt': 'yesterday',
        'phone': 3,
        'website': '',
      });

      expect(
        read.fetchedAt,
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
      expect(read.phone, isNull);
      expect(read.website, isNull);
    });

    group('applyTo', () {
      const place = PlaceSnapshot(name: 'Uffizi', osmId: 'W477279033');

      test('fills the empty values', () {
        final filled = downloaded.applyTo(place);

        expect(filled.openingHours, 'Tu-Su 08:15-18:30; Mo off');
        expect(filled.phone, '+39 055 294883');
        expect(filled.website, 'https://www.uffizi.it');
        expect(filled.wikidataId, 'Q51252');
        expect(filled.name, 'Uffizi');
      });

      test('keeps what the user wrote', () {
        final written = place.copyWith(phone: '+39 333 1234567');

        final after = PlaceDetails(
          fetchedAt: DateTime.utc(2026, 12, 20),
          phone: '+39 055 000000',
        ).applyTo(written, previous: downloaded);

        expect(after.phone, '+39 333 1234567');
      });

      test('replaces a value the user left as it came', () {
        final before = downloaded.applyTo(place);

        final after = PlaceDetails(
          fetchedAt: DateTime.utc(2026, 12, 20),
          openingHours: 'Tu-Su 08:15-19:00',
          website: 'https://www.uffizi.it',
          wikidataId: 'Q51252',
        ).applyTo(before, previous: downloaded);

        expect(after.openingHours, 'Tu-Su 08:15-19:00');
        expect(after.phone, isNull, reason: 'gone from OpenStreetMap');
        expect(after.website, 'https://www.uffizi.it');
      });

      test('without the details of last time only empty values change', () {
        final written = place.copyWith(phone: '+39 055 111111');

        final after = downloaded.applyTo(written);

        expect(after.phone, '+39 055 111111');
        expect(after.website, 'https://www.uffizi.it');
      });
    });
  });

  group('parseWebAddress', () {
    test('adds https to an address without a scheme', () {
      expect(
        parseWebAddress('  www.uffizi.it '),
        Uri.parse('https://www.uffizi.it'),
      );
      expect(
        parseWebAddress('http://www.uffizi.it/en'),
        Uri.parse('http://www.uffizi.it/en'),
      );
    });

    test('refuses what is not a web page, or hides where it goes', () {
      for (final text in [
        '',
        'uffizi',
        'www.uffizi .it',
        'ftp://uffizi.it',
        'file:///etc/passwd',
        'javascript:alert(1)',
        'mailto:info@uffizi.it',
        'https://www.uffizi.it@example.org',
        'www.uffizi.it@example.org',
      ]) {
        expect(parseWebAddress(text), isNull, reason: text);
      }
    });
  });
}
