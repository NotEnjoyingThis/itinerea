# Itinerea Sync Server

**Status: not started. Planned for phase 2.** This folder is a placeholder: it contains no code yet.

## Purpose

An optional, small server that people who want real-time collaboration install **for themselves** (at home, on a NAS or on a VPS). The Itinerea project does not run any public instance, and the app never needs it: without it, trips sync through files in a space chosen by the user (Google Drive, OneDrive, Dropbox, WebDAV or a local folder).

Planned features (PRD 4.7 and 9.4):

- real-time relay of trip operations over WebSocket (changes reach other participants within 2 seconds);
- storage of trips and attachments;
- users and roles (owner, editor, viewer);
- presence ("who is looking") and soft locking of notes.

It will ship as a Docker image and as a single executable, with minimal configuration (address, users, data folder).

## Technology

Proposed: Dart (the same language as the app, with shared models) and SQLite. Alternative: PocketBase. The final choice is made at the start of phase 2 (PRD 4.7).

## Planned layout

Nothing below exists yet. It is the shape the folder will take in phase 2, so that the rest of the repository can refer to it.

| Path | Content |
|---|---|
| `README.md` | This file, then the installation guide (one Docker command, PRD F2.1) |
| `PROTOCOL.md` | The protocol between the app and the server |
| `bin/` | Entry point of the single executable |
| `lib/` | Relay, storage, users and roles, presence |
| `test/` | Tests with several simulated devices (CLAUDE.md, section 5) |
| `Dockerfile` | Image published with the releases |

A Dockerfile is deliberately not included yet: an empty one would look like something that can be installed.

## What the app already assumes

The app side of the contract is scaffolded in `app/lib/core/sync/`:

- `SyncSpace` with `SyncMode.server` and `SyncSpaceKind.syncServer`;
- `SyncOperation`, the same operation format used in file mode (PRD 8.6);
- `SyncEngine`, which queues operations while offline and sends them when the connection is back (PRD 9.4).

See [PROTOCOL.md](PROTOCOL.md) for the outline of the protocol.
