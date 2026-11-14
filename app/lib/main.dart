// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/theme/font_licenses.dart';

void main() {
  registerFontLicenses();
  runApp(const ProviderScope(child: ItinereaApp()));
}
