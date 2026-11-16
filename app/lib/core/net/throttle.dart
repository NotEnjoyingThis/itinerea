// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

/// Sends the requests to one service one at a time, at least [interval]
/// apart (PRD 5.4). Public services run by volunteers set such limits: for
/// example "an absolute maximum of 1 request per second" (Nominatim).
class Throttle {
  /// Creates a throttle. [now] and [wait] exist for tests.
  Throttle(
    this.interval, {
    DateTime Function()? now,
    Future<void> Function(Duration)? wait,
  }) : _now = now ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  /// Shortest time between the start of two requests.
  final Duration interval;

  final DateTime Function() _now;
  final Future<void> Function(Duration) _wait;

  // The end of the last request queued: the next one starts after it.
  Future<void> _queue = Future<void>.value();
  DateTime? _lastStart;

  /// Runs [request] when the requests queued before it have finished and
  /// [interval] has passed since the last one started.
  Future<T> run<T>(Future<T> Function() request) {
    final result = _queue.then((_) async {
      final last = _lastStart;
      if (last != null) {
        final remaining = last.add(interval).difference(_now());
        if (remaining > Duration.zero) await _wait(remaining);
      }
      _lastStart = _now();
      return request();
    });
    // A failed request must not stop the ones after it.
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
