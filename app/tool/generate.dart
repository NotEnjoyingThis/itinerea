// SPDX-License-Identifier: GPL-3.0-or-later

// Creates every generated file the app and its tests need. None of them is
// committed. Run from the app/ folder, after `flutter pub get`:
//
//   dart run tool/generate.dart
//
// 1. translations, from lib/l10n/*.arb (flutter gen-l10n);
// 2. drift database code, the *.g.dart files (build_runner);
// 3. helpers of the migration tests, from the schema snapshots committed in
//    drift_schemas/ (drift_dev schema generate).
//
// After changing a table, also write a new snapshot (see CONTRIBUTING.md).

import 'dart:io';

/// Databases with schema snapshots: name of the folder under drift_schemas/.
const List<String> _databases = ['data', 'cache'];

Future<void> main() async {
  await _run('flutter', ['gen-l10n']);
  await _run('dart', [
    'run',
    'build_runner',
    'build',
    '--delete-conflicting-outputs',
  ]);
  for (final database in _databases) {
    final output = 'test/generated_migrations/$database/';
    Directory(output).createSync(recursive: true);
    await _run('dart', [
      'run',
      'drift_dev',
      'schema',
      'generate',
      'drift_schemas/$database/',
      output,
    ]);
  }
}

Future<void> _run(String executable, List<String> arguments) async {
  stdout.writeln('> $executable ${arguments.join(' ')}');
  // runInShell: on Windows, flutter and dart are batch files.
  final process = await Process.start(
    executable,
    arguments,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await process.exitCode;
  if (code != 0) {
    stderr.writeln('"$executable ${arguments.join(' ')}" failed ($code).');
    exit(code);
  }
}
