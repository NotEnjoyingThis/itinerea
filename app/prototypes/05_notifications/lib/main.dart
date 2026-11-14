// SPDX-License-Identifier: GPL-3.0-or-later

// M1 prototype 5 (PRD R5, 10.3): what do scheduled notifications really do
// on Windows and Linux with flutter_local_notifications? Not production code.
//
// Every step is appended, with a timestamp, to
// <PROTO_OUT or the system temp folder>/itinerea_notif_probe.log, so the
// outcome of a notification that fires while the app is closed can be read
// at the next start.
//
// Environment variables for unattended runs:
//   PROTO_AUTORUN=1   run every call once, write report.json, then exit
//   PROTO_OUT=<dir>   where the log and report.json are written

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final bool autorun =
    Platform.environment['PROTO_AUTORUN'] == '1' ||
    const bool.fromEnvironment('PROTO_AUTORUN');
final String outDir =
    Platform.environment['PROTO_OUT'] ?? Directory.systemTemp.path;
final File logFile = File('$outDir/itinerea_notif_probe.log');

final FlutterLocalNotificationsPlugin plugin =
    FlutterLocalNotificationsPlugin();
final ValueNotifier<List<String>> lines = ValueNotifier(const []);

void log(String message) {
  final line = '${DateTime.now().toIso8601String()} $message';
  lines.value = [...lines.value, line];
  logFile.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  debugPrint('PROTO $line');
}

/// Runs one plugin call and records whether it worked, without stopping.
Future<String> attempt(String name, Future<Object?> Function() call) async {
  try {
    final result = await call();
    final outcome = result == null ? 'ok' : 'ok: $result';
    log('$name -> $outcome');
    return outcome;
  } on Object catch (error) {
    final outcome = 'ERROR ${error.runtimeType}: $error';
    log('$name -> $outcome');
    return outcome;
  }
}

const NotificationDetails details = NotificationDetails(
  linux: LinuxNotificationDetails(),
  windows: WindowsNotificationDetails(),
);

Future<String> initialize() => attempt(
  'initialize',
  () => plugin.initialize(
    settings: InitializationSettings(
      linux: const LinuxInitializationSettings(defaultActionName: 'Open'),
      windows: WindowsInitializationSettings(
        appName: 'Itinerea notification probe',
        appUserModelId: 'io.github.notenjoyingthis.itinerea.notifprobe',
        // Random GUID made for this prototype only.
        guid: '6f1d2c1e-8a57-4c0b-9a3e-5d2b7c4e9f10',
        // PROTO_NO_ICON=1 leaves the icon out, to compare.
        iconPath: Platform.environment['PROTO_NO_ICON'] == '1'
            ? null
            : '${File(Platform.resolvedExecutable).parent.path}'
                  r'\data\flutter_assets\assets\icon.png',
      ),
    ),
    onDidReceiveNotificationResponse: (response) =>
        log('clicked: id ${response.id}, payload ${response.payload}'),
  ),
);

Future<String> showNow(int id) => attempt(
  'show($id)',
  () => plugin.show(
    id: id,
    title: 'Itinerea probe: now',
    body: 'Shown at ${DateTime.now().toIso8601String()}',
    notificationDetails: details,
    payload: 'now-$id',
  ),
);

/// Asks the operating system to show a notification later.
Future<String> schedule(int id, Duration after) {
  final when = tz.TZDateTime.now(tz.UTC).add(after);
  return attempt(
    'zonedSchedule($id, +${after.inSeconds}s, due ${when.toLocal()})',
    () => plugin.zonedSchedule(
      id: id,
      title: 'Itinerea probe: scheduled',
      body: 'Asked +${after.inSeconds}s, due ${when.toLocal()}',
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'scheduled-$id',
    ),
  );
}

/// Plan B: a timer inside the app. Only works while the process is alive.
void scheduleWithTimer(int id, Duration after) {
  log('timer($id, +${after.inSeconds}s) started');
  Timer(after, () => showNow(id));
}

Future<String> pending() => attempt('pendingNotificationRequests', () async {
  final list = await plugin.pendingNotificationRequests();
  return '${list.length} pending ${[for (final p in list) p.id]}';
});

Future<void> runUnattended() async {
  final report = <String, Object?>{
    'os': Platform.operatingSystem,
    'osVersion': Platform.operatingSystemVersion,
    'initialize': await initialize(),
    'launchDetails': await attempt(
      'getNotificationAppLaunchDetails',
      () async => (await plugin.getNotificationAppLaunchDetails())
          ?.didNotificationLaunchApp,
    ),
    'show': await showNow(1),
    'zonedSchedule': await schedule(2, const Duration(seconds: 10)),
    'pendingAfterSchedule': await pending(),
    'cancel': await attempt('cancel(2)', () => plugin.cancel(id: 2)),
    'pendingAfterCancel': await pending(),
    'zonedScheduleAgain': await schedule(3, const Duration(seconds: 10)),
  };
  if (Platform.isLinux) {
    report['linuxCapabilities'] = await attempt(
      'getCapabilities',
      () async =>
          (await plugin
                  .resolvePlatformSpecificImplementation<
                    LinuxFlutterLocalNotificationsPlugin
                  >()
                  ?.getCapabilities())
              ?.toString(),
    );
  }
  scheduleWithTimer(4, const Duration(seconds: 5));
  await Future<void>.delayed(const Duration(seconds: 20));
  report['cancelAll'] = await attempt('cancelAll', plugin.cancelAll);
  File('$outDir/report.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  debugPrint('PROTO_REPORT ${jsonEncode(report)}');
  exit(0);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  log('--- started (pid $pid, autorun $autorun)');
  runApp(const ProbeApp());
  if (autorun) {
    unawaited(runUnattended());
    return;
  }
  await initialize();
  await attempt(
    'getNotificationAppLaunchDetails',
    () async => (await plugin.getNotificationAppLaunchDetails())
        ?.didNotificationLaunchApp,
  );
  await pending();
}

class ProbeApp extends StatelessWidget {
  const ProbeApp({super.key});

  @override
  Widget build(BuildContext context) {
    Widget button(String label, VoidCallback onPressed) => Padding(
      padding: const EdgeInsets.all(4),
      child: FilledButton.tonal(onPressed: onPressed, child: Text(label)),
    );
    return MaterialApp(
      title: 'Itinerea notification probe',
      home: Scaffold(
        appBar: AppBar(title: const Text('Prototype 5: notifications')),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                button('Show now', () => showNow(10)),
                button(
                  'Schedule +30 s (id 20)',
                  () => schedule(20, const Duration(seconds: 30)),
                ),
                button(
                  'Schedule +2 min (id 21)',
                  () => schedule(21, const Duration(minutes: 2)),
                ),
                button(
                  'Schedule +10 min (id 22)',
                  () => schedule(22, const Duration(minutes: 10)),
                ),
                button(
                  'App timer +30 s (id 30)',
                  () => scheduleWithTimer(30, const Duration(seconds: 30)),
                ),
                button('Pending', pending),
                button(
                  'Cancel id 20',
                  () => attempt('cancel(20)', () => plugin.cancel(id: 20)),
                ),
                button(
                  'Cancel all',
                  () => attempt('cancelAll', plugin.cancelAll),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: lines,
                builder: (context, value, _) => ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    for (final line in value.reversed)
                      SelectableText(
                        line,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
