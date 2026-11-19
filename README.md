# Chatterleaf

Smart greenhouse app — plants text you what they need. Flutter + (mock) Firebase structure for instructor review.

**Mock mode is ON by default** (`ChatterleafApp(useMock: true)` in `lib/main.dart`). No Firebase project or secrets required for a live demo.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Screens (lib/screens/)                                 │
│  Login · Dashboard · Control · History · Chat · Settings│
└──────────────────────────┬──────────────────────────────┘
                           │ call repository only
┌──────────────────────────▼──────────────────────────────┐
│  GreenhouseRepository  (lib/data/greenhouse_repository) │
│  + AuthService · AutomationService · AlertService       │
│  + PersonaEngine · ConnectivityService                  │
└──────────────────────────┬──────────────────────────────┘
                           │
          ┌────────────────┴────────────────┐
          ▼                                 ▼
   MockFirestore                     (optional) Firebase
   lib/data/mock/                   Auth + Firestore
```

Firestore security rules live at repo root: `firestore.rules` (owner-only access).

## Run (mock demo)

```bash
flutter pub get
flutter run -d chrome          # or -d android / -d ios
```

Demo accounts:

| Email | Password |
|-------|----------|
| `demo@chatterleaf.app` | `password123` |
| `grower2@chatterleaf.app` | `password123` |

Each account has its own greenhouse (M1 isolation).

## Demo steps M1–M8

1. **M1 Login** — Sign in as `demo@…`. Try a wrong password → clear error. Log out, sign in as `grower2@…` → empty/separate greenhouse (no shared data).
2. **M2 Dashboard** — Home shows 4 live reading cards (temp, humidity, soil, light) with green/yellow/red status, last update, and the plant message bubble on top.
3. **M3 Control** — Open Control, toggle Irrigation → switch updates and the plant confirms in Chat.
4. **M4 Modes** — Tap the Auto/Manual chip. In Auto, use Settings → **Simulate 18% soil** → irrigation turns on by itself.
5. **M5 Alerts** — Settings → **Simulate 45°C spike** → plant-voice alert appears; open Alerts (bell) and tap one → returns to dashboard.
6. **M6 History** — Settings → **Create demo data** (7 days, includes 45°C and 18% soil). History → Day/Week + parameter tabs show line charts.
7. **M7 Settings** — Change thresholds / persona / °C·°F. Invalid min≥max or % outside 0–100 is rejected. Saved thresholds apply immediately to Auto.
8. **M8 No internet** — Settings → **Mock offline** → red “No connection” bar; last values marked offline; no crash. Toggle back → bar hides.

## Folder map

```
lib/
  main.dart
  models/          persona, readings, devices, alerts, chat…
  data/            repository + services (+ mock/)
  screens/         UI (repository only)
  widgets/         offline_banner, reading_card, …
  theme/           app_colors, app_theme (Nunito / Inter)
firestore.rules
```

## Roles

Individual project — design, Flutter, Firebase setup, testing, presentation: **Zhaolu**.

## Firebase (optional, later)

When you create a real Firebase project: enable Email/Password Auth, paste `firestore.rules`, run `flutterfire configure`, set `useMock: false`, and keep `google-services.json` / `firebase_options.dart` out of git (already in `.gitignore`).
