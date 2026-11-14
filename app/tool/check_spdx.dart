// SPDX-License-Identifier: GPL-3.0-or-later

// Checks that every Dart source file starts with the SPDX licence header.
// Run from the app/ folder: dart run tool/check_spdx.dart
// Generated files without the header are skipped: see _isGenerated.

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
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !_isGenerated(file.path));
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

/// Files written by code generators that cannot add the header themselves:
/// the drift database code and the helpers of the migration tests. They are
/// not committed (see tool/generate.dart).
bool _isGenerated(String path) {
  final normalized = path.replaceAll(r'\', '/');
  return normalized.endsWith('.g.dart') ||
      normalized.contains('test/generated_migrations/');
}
