// SPDX-License-Identifier: GPL-3.0-or-later

// The transport talks to a server on this computer: tests never reach the
// network.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/net/app_info.dart';
import 'package:itinerea/core/net/http_transport.dart';

Matcher _failure(ServiceFailureKind kind) => throwsA(
  isA<ServiceFailure>().having((failure) => failure.kind, 'kind', kind),
);

void main() {
  test('the User-Agent names the app, its version and its repository', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);

    expect(appVersion, version, reason: 'app_info.dart follows pubspec.yaml');
    expect(
      userAgent,
      'Itinerea/$version (+https://github.com/NotEnjoyingThis/itinerea)',
    );
  });

  group('TransportResponse.json', () {
    test('reads the body of a successful answer', () {
      expect(const TransportResponse(200, '{"a": [1]}').json(), {
        'a': [1],
      });
    });

    test('429 and 503 mean that the service is busy', () {
      for (final status in [429, 503]) {
        expect(
          () => TransportResponse(status, '').json(),
          _failure(ServiceFailureKind.busy),
        );
      }
    });

    test('other errors and bodies that are not JSON are bad answers', () {
      for (final response in [
        const TransportResponse(400, '{}'),
        const TransportResponse(500, '{}'),
        const TransportResponse(200, '<html>'),
      ]) {
        expect(response.json, _failure(ServiceFailureKind.badResponse));
      }
    });
  });

  group('IoHttpTransport', () {
    late HttpServer server;
    late IoHttpTransport transport;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      transport = IoHttpTransport(
        timeout: const Duration(milliseconds: 500),
        maxBodyBytes: 1024,
      );
    });

    tearDown(() async {
      transport.close();
      await server.close(force: true);
    });

    Uri address([String path = '/']) =>
        Uri.parse('http://127.0.0.1:${server.port}$path');

    test('sends the User-Agent of the project and reads the answer', () async {
      server.listen((request) {
        request.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'userAgent': request.headers.value('user-agent'),
              'accept': request.headers.value('accept'),
            }),
          );
        unawaited(request.response.close());
      });

      final answer = await transport.get(address());

      expect(answer.status, 200);
      expect(answer.json(), {
        'userAgent': userAgent,
        'accept': 'application/json',
      });
    });

    test('an answer too large is refused', () async {
      server.listen((request) {
        request.response.write('x' * 2000);
        unawaited(request.response.close());
      });

      await expectLater(
        transport.get(address()),
        _failure(ServiceFailureKind.badResponse),
      );
    });

    test(
      'a server that does not answer in time counts as no connection',
      () async {
        server.listen((request) {});

        await expectLater(
          transport.get(address()),
          _failure(ServiceFailureKind.noConnection),
        );
      },
    );

    test('a server that is not there counts as no connection', () async {
      final closed = address();
      await server.close(force: true);

      await expectLater(
        transport.get(closed),
        _failure(ServiceFailureKind.noConnection),
      );
    });

    test('only web addresses are asked', () async {
      await expectLater(
        transport.get(Uri.parse('file:///etc/passwd')),
        throwsArgumentError,
      );
    });
  });
}
