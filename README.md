# Tamyr 🌱

**Tamyr helps a school eco club look after its greenhouse: every plant becomes a character that tells you how it feels, and students control watering, light and ventilation from their phones.**

“Tamyr” means both *root* and *close friend* in Kazakh.

Flutter app · demo backend (no keys) or Firebase (Auth + Cloud Firestore) · Node.js greenhouse simulator.

> This repository used to contain the *Chatterleaf* prototype. Tamyr replaces it (branch `tamyr`); the old code stays in the Git history.

## Signature feature: the talking plant

| Character | Crop | Personality |
|---|---|---|
| Tomi | tomatoes | cheerful optimist |
| Cuke | cucumbers | kind grump |
| Berry | strawberries | gentle and polite |
| Dilly | herbs | joker |

The character's face follows the sensors: happy, hot (sweat drop), thirsty (sad brows), cold (blue, chattering), asleep (no data).
In the chat you can ask “How are you?”, “Thirsty?”, “Why do you need light?”. The plant answers with real numbers and, when it feels bad, shows a button: **Water me**, **Open window**.
All of it is in `lib/logic/plant_talk.dart` — no internet, no paid AI, no keys.

Tracks: **Education** (the plant explains photosynthesis, water, temperature; activity log of students on duty; mood diary) and **Agro-intelligence** (crop profiles with preset thresholds and facts).

## Run

```bash
flutter pub get
flutter run            # demo mode: in-memory database + simulator, no setup
flutter test
```

Demo accounts (demo mode only):

| Email | Password | What you see |
|---|---|---|
| `aigul@tamyr.app` | `password123` | School No. 12 — Tomi, Cuke, Berry, Dilly |
| `school5@tamyr.app` | `password123` | School No. 5 — one bed (shows M1 isolation) |

### Firebase mode

1. Create a Firebase project → enable **Email/Password** auth → create **Cloud Firestore** → paste `firestore.rules` into *Rules*.
2. `dart pub global activate flutterfire_cli && flutterfire configure` (adds `google-services.json` / `GoogleService-Info.plist` — both are in `.gitignore`).
3. Fill the database with test data and start the live simulator:
   ```bash
   cd simulator
   cp .env.example .env        # set SEED_PASSWORD, put serviceAccountKey.json here (never commit it)
   npm install
   npm run seed                # 2 accounts, 5 beds, 7 days of history with out-of-range values
   npm start                   # new readings every 30 s, executes device commands
   ```
4. `flutter run --dart-define=USE_FIREBASE=true`

## Defense steps M1–M8 (demo mode)

1. **M1 Login** — sign in as `aigul@…`; try a wrong password → clear error. Sign out (Settings) and sign in as `school5@…` → only its own bed.
2. **M2 Dashboard** — *Our beds*: 4 characters with mood, temperature and soil bar; black card “2 friends need help”. Values update every 5 s by themselves.
3. **M3 Control** — open Tomi → **Devices** → switch the window: the plant reacts, temperature starts to drop, the log records who did it.
4. **M4 Modes** — tap **Manual mode / Auto mode** on the bed card or the *Auto mode* switch in Devices. Settings → Demo tools → **Dry soil** on Cuke → in Auto, watering turns on by itself.
5. **M5 Alerts** — Settings → Demo tools → **Heat wave** on Tomi (45 °C) → an in-app banner in Tomi’s voice appears; the Alerts tab lists it; tapping opens the bed.
6. **M6 History** — bed → **Mood diary**: Day / Week / Month, charts of soil water and temperature from stored history; the month calendar shows a face for every day (Friday’s drought is visible on Cuke).
7. **M7 Settings** — bed → ⚙: crop profiles, thresholds, light schedule, °C/°F. `-50` or min ≥ max is rejected. New thresholds are used by automation immediately.
8. **M8 No internet** — Settings → Demo tools → **Simulate no internet**: red bar, plants fall asleep after 2 minutes without data, commands are queued; switch back → everything recovers. In Firebase mode the same happens when the phone goes offline or the simulator is stopped.

## Structure

```
lib/
  main.dart                 start, chooses demo or Firebase
  data/                     DATA LAYER — screens never talk to a database directly
    models.dart             Greenhouse (bed), Readings, Device, Settings, History, Alert…
    repositories.dart       interfaces + ConnectivityService (M8)
    mock_backend.dart       demo database + simulator (default)
    firebase_backend.dart   Firebase Auth + Firestore
    automation_service.dart M4 rules
    alert_service.dart      M5 alerts in the plant's voice
  logic/                    pure Dart, covered by tests
    plant_talk.dart         talking plant
    mood.dart, status.dart  mood and thresholds
    crop_profiles.dart      crop presets and facts
  theme/app_theme.dart      design tokens (same as the mockups)
  widgets/plant_avatar.dart kawaii sticker characters, drawn in code
  widgets/common.dart       pill buttons, gauges, chips, offline bar…
  screens/                  login, beds, bed, chat, devices, diary, alerts, settings, log
simulator/                  Node.js seed + live simulator for Firebase mode
design/                     character sheet
firestore.rules             owner-only access
```

### Firestore structure

| Path | Fields |
|---|---|
| `users/{uid}` | `name`, `role` |
| `greenhouses/{id}` | `ownerId`, `name`, `plantName`, `cropKey`, `personality`, `place`, `mode`, `current {airTemp, airHumidity, soilMoisture, light, updatedAt}`, `settings {…}` |
| `greenhouses/{id}/devices/{deviceId}` | `name`, `isOn`, `changedBy`, `changedAt`, `order` |
| `greenhouses/{id}/history/{auto}` | `ts`, `airTemp`, `airHumidity`, `soilMoisture`, `light` (every 30 min, 7+ days) |
| `greenhouses/{id}/events/{auto}` | `ts`, `deviceId`, `isOn`, `by`, `byName` |
| `alerts/{auto}` | `ownerId`, `greenhouseId`, `plantName`, `cropKey`, `param`, `value`, `message`, `ts`, `read` |

## Team

| Member | Role |
|---|---|
| Zhaolu | design, Flutter, Firebase, presentation |
| _add teammates_ | |
