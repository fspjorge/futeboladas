# Futeboladas ⚽

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-Private-red)

**Futeboladas** is a modern, premium mobile application designed to seamlessly organize, manage, and schedule amateur football (soccer) matches amongst friends. Built with Flutter and Firebase, it delivers a stunning Glassmorphism UI with real-time synchronize capabilities.

> **Note:** The application's User Interface (UI) is localized in **Portuguese (PT-PT)** for its target audience, but the entire underlying **codebase, architecture, and database schematic are written in English** to ensure global scalability and standard developer collaboration.

---

## ✨ Key Features

- **🛡️ Secure Authentication**: Google Sign-In and Email/Password authentication.
- **📅 Game Management**: Create, edit, and list active football games. Define dates, locations, max players, and entry prices.
- **🙋‍♂️ Real-Time Attendance**: Opt-in to matches instantly. Capacity limits are enforced in real-time.
- **🌦️ Weather Integration**: Live weather forecasts at the exact game location and time via the OpenWeather API.
- **📍 Smart Location Search**: Integrated autocomplete for finding fields/stadiums using the Photon API (OpenStreetMap) — no credit card needed.
- **🗺️ Interactive Maps**: Jump straight from a game detail into Google Maps or Apple Maps.
- **💎 Premium UI/UX**: Elegant dark theme utilizing authentic Glassmorphism blur effects, micro-animations, and dynamic Floating Action Buttons.

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend/Database**: [Firebase](https://firebase.google.com/) (Authentication & Cloud Firestore)
- **Location Services**: [Photon API](https://photon.komoot.io/) & `url_launcher` for Maps routing.
- **Weather Services**: [OpenWeather API](https://openweathermap.org/)
- **Design System**: Custom constraints, `google_fonts` (Outfit), and blur-backdrop filters.

---

## 📂 Architecture & Structure

The codebase follows a feature-first architectural pattern.
```text
lib/
├── models/             # Data classes (e.g., Game, FilterMode)
├── screens/            # UI Views grouped by feature
│   ├── auth/           # Login and Account creation
│   ├── games/          # Dashboard, Game Creation, Game Details
│   └── profile/        # User Profile Management
├── services/           # External API & Firebase communicators
│   ├── game_service.dart
│   ├── attendance_service.dart
│   └── weather_service.dart
├── utils/              # Formatting and helper utilities
└── widgets/            # Reusable UI components (Buttons, Empty States, Backdrops)
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.10.0 or higher)
- Firebase CLI (`npm i -g firebase-tools`)
- A Firebase project with Authentication and Firestore enabled.

### 1. Clone the repository
```bash
git clone https://github.com/fspjorge/futeboladas.git
cd futeboladas
```

### 2. Configure Firebase (FlutterFire)
1. Ensure you have the `flutterfire_cli` installed: `dart pub global activate flutterfire_cli`
2. Configure your project to generate `lib/firebase_options.dart`:
```bash
flutterfire configure --project=futeboladas-62f15
```
3. Deploy the database rules (See [FIREBASE.md](FIREBASE.md)). 

### 3. OpenWeather API Configuration
The application relies on an OpenWeatherMap API key for accurate forecasts. 
- You must supply your own valid API key inside `lib/services/weather_service.dart` or set it up via your environment configurations.

### 4. Run the Application
```bash
flutter pub get
flutter run
```

---

## 📄 License & Usage

Private and internal use only. No public license has been attributed to this repository. All rights reserved.
