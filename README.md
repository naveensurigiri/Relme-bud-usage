# Realme Buds Tracker (Flutter / Android)

Shows live battery and noise mode (ANC, Transparency, Normal) for Realme Air Buds 7, and counts how often and how long each mode is used.

## How it talks to the buds
Realme Link uses classic Bluetooth (RFCOMM) with a small framed protocol. This app opens the same channel and sends only two read-only queries (battery and mode). It never sends a mode-change command.

## Build the APK on GitHub
Push this folder to the `main` branch. The "Build APK" workflow runs, then download the `realme-buds-tracker-apk` artifact. The tests run first; a failed test does not block the build.

## Use it
1. Pair the buds in the phone's Bluetooth settings.
2. Disable Realme Link (Settings > Apps) so it is not holding the connection.
3. Open the app, allow the Nearby devices permission, pick your buds, tap Connect.

## What works and what does not
- Battery: left and right read from the buds. The case value reads 0 in the capture, so it shows "--".
- Mode: Transparency (01), ANC (02), Normal (08), confirmed from a capture.
- Wearing, firmware and serial are not decoded yet.
- Stats are saved on the phone only.
