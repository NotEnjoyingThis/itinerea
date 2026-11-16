// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:convert';

import 'package:itinerea/core/net/http_transport.dart';

/// An [HttpTransport] that never reaches the network: it answers with
/// [handler] and remembers every request. Tests may change [handler] while
/// they run, for example to go offline.
class FakeTransport implements HttpTransport {
  /// Creates a transport that answers with [handler].
  FakeTransport(this.handler);

  /// A transport without network, as a device offline.
  FakeTransport.offline() : handler = _offline;

  static Never _offline(Uri uri) =>
      throw const ServiceFailure(ServiceFailureKind.noConnection, 'offline');

  /// Gives the answer to a request, or throws a ServiceFailure.
  FutureOr<TransportResponse> Function(Uri uri) handler;

  /// Every request sent, in order.
  final List<Uri> requests = [];

  /// Makes the transport offline from now on.
  void goOffline() => handler = _offline;

  @override
  Future<TransportResponse> get(Uri uri) async {
    requests.add(uri);
    return handler(uri);
  }
}

/// A successful answer with [json] as body.
TransportResponse jsonAnswer(Object? json, {int status = 200}) =>
    TransportResponse(status, jsonEncode(json));
