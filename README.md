# Smart Task Manager

A cross-platform task management app with a glassmorphism UI, email/password authentication, and an ESP32-based physical OLED display that shows your tasks in real time.

Built with **Flutter**, **Riverpod**, **Firebase Auth**, and **Cloud Firestore**.

---

## Features

- **Task CRUD** — Create, edit, complete, archive, restore, and delete tasks
- **Task types** — Today, Daily, Constant, Weekly, Monthly, Custom Date
- **Priorities** — Critical, High, Medium, Low
- **Categories** — Customizable with color picker
- **ESP32 toggle** — Per-task checkbox to show/hide on the physical display
- **Dashboard** — Auto-generated display model consumed by the ESP32
- **Calendar** — Month grid with per-day task dots
- **Statistics** — Streak counter and completion progress bars
- **Activity log** — Full audit trail of every action
- **Backup/Restore** — JSON export and import
- **Search & filter** — Full-text search by title/description/category, filter by status/type/priority
- **Dark mode** — System-following theme toggle
- **ESP32 display** — Standalone IoT firmware that fetches and renders tasks on an SSD1306 OLED

---

## Screens

| Tab | Screen | Purpose |
|-----|--------|---------|
| 1 | **Task List** | Search, filter, toggle completion, inline ESP32 toggle |
| 2 | **Calendar** | Month view with color-coded task dots |
| 3 | **Statistics** | Streaks and daily/weekly/monthly completion |
| 4 | **Dashboard** | Configure what the ESP32 displays |
| 5 | **Settings** | Categories, activity log, backup, theme |

---

## Architecture

```
lib/
├── core/          # Constants, theme, shared widgets, network
├── data/          # Models, datasources (Firestore + local), repositories
├── domain/        # Entities, abstract repository interfaces
└── presentation/  # Providers (Riverpod), screens, widgets
```

- **Clean Architecture** — domain layer is pure Dart with no framework dependencies
- **Riverpod** — state management (`StateNotifierProvider`, `StreamProvider`, `FutureProvider`)
- **Firebase Auth** — email/password with reactive `authStateChanges()` stream
- **Cloud Firestore** — per-user collections at `users/{uid}/...`
- **Glassmorphism** — frosted glass cards with `BackdropFilter` and Material 3

---

## Setup

### Prerequisites

- Flutter SDK `^3.11.0`
- A Firebase project (or use the pre-configured `buddy-a4902`)
- PlatformIO CLI or VS Code extension (for ESP32)

### Flutter App

```bash
# Clone and install dependencies
git clone <repo-url>
cd iot_task_manager
flutter pub get

# Run on device/emulator
flutter run

# Or target a specific platform
flutter run -d chrome          # Web
flutter run -d windows         # Windows desktop
```

To use your own Firebase project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=your-project-id
```

### Firestore

1. Create a Firestore database in the Firebase console
2. Deploy security rules:

```bash
firebase deploy --only firestore:rules
```

3. Create a user in **Firebase Authentication** (Email/Password)

### ESP32 Display

**Hardware:**

| Component | Details |
|-----------|---------|
| ESP32 | Any variant (DevKit, WROOM, etc.) |
| SSD1306 OLED | 128×64, I2C interface |

**Wiring:**

```
ESP32 GPIO21 (SDA)  →  OLED SDA
ESP32 GPIO22 (SCL)  →  OLED SCL
ESP32 3.3V          →  OLED VCC
ESP32 GND           →  OLED GND
```

**Upload firmware:**

```bash
cd esp32_iot_display

# Build & upload
pio run --target upload

# Monitor serial output
pio device monitor --baud 115200
```

The firmware uses the REST API (not the Firebase SDK). It authenticates once, fetches the dashboard document every 30 seconds, and rotates through sections (Today / Daily / Constant) on the OLED.

**Credentials** are inlined at the top of `esp32_iot_display.ino`:

```cpp
const char* WIFI_SSID       = "...";
const char* WIFI_PASSWORD   = "...";
const char* FIREBASE_API_KEY   = "...";
const char* FIREBASE_PROJECT_ID = "...";
const char* AUTH_EMAIL      = "...";
const char* AUTH_PASSWORD   = "...";
```

---

## Build for Distribution

```bash
flutter build apk         # Android APK
flutter build ios         # iOS (macOS only)
flutter build web         # Web
flutter build windows     # Windows
flutter build macos       # macOS
flutter build linux       # Linux
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Flutter + Material 3 |
| State | Riverpod |
| Auth | Firebase Auth (email/password) |
| Database | Cloud Firestore |
| Local cache | SharedPreferences |
| Notifications | flutter_local_notifications |
| IoT display | ESP32 + SSD1306 (Arduino/PlatformIO) |

---

## Firebase Data Model

All data is scoped per user:

```
users/{uid}/
├── tasks/{taskId}
├── dashboard/current
├── dashboard/settings
├── categories/{categoryId}
└── activityLogs/{logId}
```

Firestore rules enforce user isolation (`request.auth.uid == userId`).

---

## ESP32 REST API Flow

```
┌─────────┐     POST accounts:signInWithPassword     ┌──────────────┐
│  ESP32  │ ──────────────────────────────────────▶   │  Firebase    │
│         │ ◀──────────────────────────────────────   │  Auth        │
│         │         { idToken, localId }              └──────────────┘
│         │
│         │     GET /projects/{id}/databases/...      ┌──────────────┐
│         │ ──────────────────────────────────────▶   │  Firestore   │
│         │ ◀──────────────────────────────────────   │  REST API    │
│         │         Firestore Document JSON           └──────────────┘
│         │
│         │  Parse & render on SSD1306 OLED
└─────────┘
```

---

## License

Private project.
