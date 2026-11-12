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
