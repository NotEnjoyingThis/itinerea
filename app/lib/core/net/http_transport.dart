// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'app_info.dart';

/// Why an external service gave no usable answer. The interface turns each
/// kind into a plain sentence, never a technical code (PRD 7.7).
enum ServiceFailureKind {
  /// No network, or the service could not be reached in time.
  noConnection,

  /// The service asks to slow down (HTTP 429 or 503).
  busy,

  /// The service answered with an error or with something unreadable.
  badResponse,
}

/// An external service gave no usable answer.
class ServiceFailure implements Exception {
  /// Creates a failure of [kind]; [detail] is for tests and logs only.
  const ServiceFailure(this.kind, [this.detail]);

  /// What went wrong.
  final ServiceFailureKind kind;

  /// Technical detail, never shown to the user.
  final String? detail;

  @override
  String toString() =>
      'ServiceFailure(${kind.name}${detail == null ? '' : ': $detail'})';
}

/// The answer of a service: status code and text of the body.
class TransportResponse {
  /// Creates an answer.
  const TransportResponse(this.status, this.body);

  /// HTTP status code.
  final int status;

  /// Body, decoded as UTF-8.
  final String body;

  /// The body as JSON, for a successful answer.
  ///
  /// Throws a [ServiceFailure]: [ServiceFailureKind.busy] when the service
  /// asks to slow down, [ServiceFailureKind.badResponse] for any other error
  /// or for a body that is not JSON.
  Object? json() {
    if (status == HttpStatus.tooManyRequests ||
        status == HttpStatus.serviceUnavailable) {
      throw ServiceFailure(ServiceFailureKind.busy, 'HTTP $status');
    }
    if (status != HttpStatus.ok) {
      throw ServiceFailure(ServiceFailureKind.badResponse, 'HTTP $status');
    }
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const ServiceFailure(ServiceFailureKind.badResponse, 'not JSON');
    }
  }
}

/// Sends requests to external services. Tests replace it with a fake: they
/// never reach the network.
abstract interface class HttpTransport {
  /// Sends a GET request to [uri].
  ///
  /// Throws a [ServiceFailure] when the service cannot be reached.
  Future<TransportResponse> get(Uri uri);
}

/// [HttpTransport] on the HTTP client of the system, with the User-Agent of
/// the project, a time limit and a size limit: answers come from outside and
/// are not trusted (PRD 13).
class IoHttpTransport implements HttpTransport {
  /// Creates the transport.
  IoHttpTransport({
    HttpClient? client,
    this.timeout = const Duration(seconds: 15),
    this.maxBodyBytes = 2 * 1024 * 1024,
  }) : _client = client ?? HttpClient() {
    _client
      ..userAgent = userAgent
      ..connectionTimeout = timeout;
  }

  final HttpClient _client;

  /// Longest wait for the connection and for each part of the answer.
  final Duration timeout;

  /// Largest answer accepted, in bytes.
  final int maxBodyBytes;

  @override
  Future<TransportResponse> get(Uri uri) async {
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      throw ArgumentError.value(uri, 'uri', 'Not a web address');
    }
    try {
      final request = await _client.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(timeout);
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(timeout)) {
        bytes.add(chunk);
        if (bytes.length > maxBodyBytes) {
          throw const ServiceFailure(
            ServiceFailureKind.badResponse,
            'answer too large',
          );
        }
      }
      return TransportResponse(
        response.statusCode,
        utf8.decode(bytes.takeBytes(), allowMalformed: true),
      );
    } on SocketException catch (error) {
      throw ServiceFailure(ServiceFailureKind.noConnection, error.message);
    } on HandshakeException catch (error) {
      throw ServiceFailure(ServiceFailureKind.noConnection, error.message);
    } on TimeoutException {
      throw const ServiceFailure(ServiceFailureKind.noConnection, 'timeout');
    } on HttpException catch (error) {
      throw ServiceFailure(ServiceFailureKind.badResponse, error.message);
    }
  }

  /// Releases the connections of the client.
  void close() => _client.close(force: true);
}
