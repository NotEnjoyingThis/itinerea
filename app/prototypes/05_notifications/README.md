# Prototype 5 — Scheduled notifications on Windows and Linux

Questions (PRD R5, 10.3): with `flutter_local_notifications`, does a notification scheduled for later appear on Windows and Linux when the app is open, minimised, closed, and after a reboot? Can it be cancelled?

A small Flutter app with one button per call and a log on screen. Every step is also appended to `itinerea_notif_probe.log` in the system temp folder (or in `PROTO_OUT`), so what happened while the app was closed can be read afterwards. It makes no network requests.

## Build

```sh
flutter pub get
flutter build windows --release   # or: flutter build linux --release
```

On Windows the plugin needs the **C++ ATL** component of the Visual Studio Build Tools ("C++ ATL for latest v143 build tools"): without it the build stops at `atlbase.h`.

## Start menu shortcut (Windows)

Windows shows the notifications of an unpackaged app only if the app has a Start menu shortcut that carries its AppUserModelID. Without it every call succeeds and nothing appears. Create it once (and delete the `.lnk` file when done):

```powershell
.\tool\make_shortcut.ps1 -Target "$PWD\build\windows\x64\runner\Release\notif_probe.exe" -Aumid io.github.notenjoyingthis.itinerea.notifprobe -LinkPath "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Itinerea notification probe.lnk"
```

## Run

Start `build/windows/x64/runner/Release/notif_probe.exe` (or `build/linux/x64/release/bundle/notif_probe`) and use the buttons.

Unattended, as the CI does:

```sh
PROTO_AUTORUN=1 PROTO_OUT=out build/linux/x64/release/bundle/notif_probe
```

It calls each method once, writes `out/report.json` and exits after about 20 seconds.

## What it found

See PRD 10.3 and 16.3, and `docs/DECISIONS.md`.
