// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:material_ui/material_ui.dart';

/// Provisional light and dark themes for milestone M0.
// TODO(M3): replace with the style approved in docs/DESIGN.md (PRD D2).
abstract final class AppTheme {
  static const Color _seed = Color(0xFF1F6F6B);

  /// Theme used when the app is in light mode.
  static ThemeData get light => _build(Brightness.light);

  /// Theme used when the app is in dark mode.
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
  );
}
