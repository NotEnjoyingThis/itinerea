# Prototype 4 — Google Drive sync between two accounts

Questions (PRD R1, R10): with the narrow `drive.file` scope, can a second Google account open a trip folder shared by the first one? Does picking a folder in the Google Picker give access to what it contains? Does each account see the files the other one writes, and how fast?

A plain Dart command-line program for desktop. There is no Android part: Google no longer allows custom URI schemes or loopback redirects for Android clients, and the official path needs Google Play Services, which the project does not use.

## Secrets

Nothing secret is in the repository. The program reads everything from `.secrets/`, which git ignores:

- `client_secret*.json`: the OAuth client of type "Desktop app", downloaded from the Google Cloud Console;
- `config.json`: the two Google addresses, see `config.example.json`;
- `token_A.json`, `token_B.json`, `state.json`: written by the program. The tokens are stored as plain files: acceptable for a throwaway probe only.

The Google Cloud project needs the Google Drive API and the Google Picker API enabled, the `drive.file` scope, and both accounts listed as test users.

## Run

```sh
dart pub get
dart run bin/drive_probe.dart login A          # browser opens: sign in as account A
dart run bin/drive_probe.dart create A         # trip folder and operation files
dart run bin/drive_probe.dart share A writer   # share the trip folder with B
dart run bin/drive_probe.dart login B
dart run bin/drive_probe.dart inspect B        # what B's app sees without the Picker
dart run bin/drive_probe.dart pick B           # Picker opens inside the trip folder
dart run bin/drive_probe.dart write B          # B writes its own operation file
dart run bin/drive_probe.dart wait A           # does A see it? polls for 60 s
dart run bin/drive_probe.dart peek A <id>      # one file or folder by id
dart run bin/drive_probe.dart append B <id>    # rewrite a file with one more line
dart run bin/drive_probe.dart changes A        # Drive "changes" feed
```

Every command prints one JSON line, without e-mail addresses.

## Clean up

Delete the "Itinerea prototype" folder from the Drive of account A, the `deviceB` folder from the Drive of account B, and the `.secrets/` folder.

## What it found

See PRD 5.6 (terms read) and 16.3, and `docs/DECISIONS.md`.
