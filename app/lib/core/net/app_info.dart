// SPDX-License-Identifier: GPL-3.0-or-later

/// Version of the app. A test keeps it equal to the version in pubspec.yaml.
const String appVersion = '0.0.1';

/// Page of the project, also sent in the User-Agent.
const String repositoryUrl = 'https://github.com/NotEnjoyingThis/itinerea';

/// User-Agent of every request to an external service (PRD 5.4). It names
/// the app and never the user.
const String userAgent = 'Itinerea/$appVersion (+$repositoryUrl)';
