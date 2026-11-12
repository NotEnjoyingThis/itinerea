// SPDX-License-Identifier: GPL-3.0-or-later

// Checks that every Dart source file starts with the SPDX licence header.
// Run from the app/ folder: dart run tool/check_spdx.dart

import 'dart:io';

const String _header = '// SPDX-License-Identifier: GPL-3.0-or-later';
const List<String> _roots = ['lib', 'test', 'tool'];

void main() {
  final missing = <String>[];
  var checked = 0;

  for (final root in _roots) {
    final directory = Directory(root);
    if (!directory.existsSync()) {
      continue;
    }
    final files = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      checked++;
      final lines = file.readAsLinesSync();
      if (lines.isEmpty || lines.first.trimRight() != _header) {
        missing.add(file.path);
      }
    }
  }

  if (missing.isEmpty) {
    stdout.writeln('SPDX header found in all $checked Dart files.');
    return;
  }

  stderr.writeln('Missing "$_header" on the first line of:');
  for (final path in missing..sort()) {
    stderr.writeln('  $path');
  }
  exitCode = 1;
}
