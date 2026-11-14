// SPDX-License-Identifier: GPL-3.0-or-later

/// The two ways a trip can be synchronised (PRD 4.3).
enum SyncMode {
  /// Files in a folder chosen by the user; changes arrive in seconds or
  /// minutes.
  file,

  /// A self-hosted Itinerea Sync Server; changes arrive within 2 seconds.
  server,
}

/// Kinds of sync space (PRD 3, 4.3).
enum SyncSpaceKind {
  /// A local folder, for example one kept in sync by Syncthing.
  localFolder,

  /// A WebDAV folder (Nextcloud, a NAS…).
  webDav,

  /// Microsoft OneDrive.
  oneDrive,

  /// Dropbox.
  dropbox,

  /// Google Drive: personal sync and backups only, on desktop only
  /// (decision of 2026-11-14, PRD 16.3). Never a space for groups.
  googleDrive,

  /// A self-hosted Itinerea Sync Server.
  syncServer,
}

/// A place where the data of a trip is stored and exchanged (PRD 3, 4.3).
///
/// Paths are relative to the root folder of Itinerea in the space and follow
/// the layout of PRD 8.6.
// TODO(M6 F1.13): local folder and WebDAV for personal sync and backups.
// TODO(Fase 2 F2.1): shared spaces, invitations and roles.
abstract interface class SyncSpace {
  /// Kind of space.
  SyncSpaceKind get kind;

  /// How the space synchronises.
  SyncMode get mode;

  /// True if the space can be shared with other people.
  bool get supportsSharing;

  /// Lists the files directly inside a folder.
  Future<List<String>> list(String folder);

  /// Reads a file.
  Future<List<int>> read(String path);

  /// Writes a file, replacing it if it exists.
  Future<void> write(String path, List<int> bytes);

  /// Deletes a file.
  Future<void> delete(String path);
}
