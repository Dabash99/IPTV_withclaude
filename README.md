# 📺 IPTV Player - Flutter App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![BLoC](https://img.shields.io/badge/BLoC-Cubit-0074D9?style=for-the-badge)
![Clean Architecture](https://img.shields.io/badge/Architecture-Clean-success?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

**A production-grade IPTV player built with Flutter, supporting Xtream Codes API with full Live TV, Movies, Series, and EPG support.**

[Features](#-features) • [Screenshots](#-screenshots) • [Architecture](#%EF%B8%8F-architecture) • [Getting Started](#-getting-started) • [API](#-xtream-codes-api) • [Contributing](#-contributing)

</div>

---

## ✨ Features

### 🎬 Content Support
- **📡 Live TV** — Stream live channels with category filtering and real-time search
- **🎞️ Movies (VOD)** — Browse movie library with posters, ratings, cast, plot, and full metadata
- **📺 Series** — Watch series organized by seasons with episode details
- **📅 EPG (Electronic Program Guide)** — View current and upcoming programs per channel
- **❤️ Favorites** — Save your favorite channels, movies, and series locally

### 🎨 UI/UX
- **🌙 Modern Dark Theme** with purple accent (`#6C3BE4`)
- **🌐 Full Arabic RTL Support** with proper localization delegates
- **📱 Responsive Design** using `flutter_screenutil`
- **⚡ Smooth Animations** and transitions
- **🎯 Bottom Navigation** with 5 main sections

### 🔐 Security & Storage
- **🔒 Secure Credentials** stored via `flutter_secure_storage` (encrypted)
- **💾 Favorites Persistence** using `SharedPreferences`
- **🔑 Auto-login** on app restart

### 🎥 Video Playback
- **▶️ better_player_plus** with HLS/m3u8 support
- **🖥️ Fullscreen Mode** with auto-rotation
- **⚙️ Quality Selection** and playback speed controls
- **📺 Live Indicator** badge for live streams
- **🔄 Error Recovery** with retry mechanism

---

## 🏗️ Architecture

Built with **Clean Architecture** principles for maintainability and testability:

```
lib/
├── core/                      # Cross-cutting concerns
│   ├── constants/             # Colors, API endpoints, storage keys
│   ├── errors/                # Failures + Exceptions
│   └── network/               # DioHelper with interceptors
│
├── data/                      # Data layer
│   ├── models/                # JSON serializable models
│   ├── datasources/           # Remote (Dio) + Local (SecureStorage + SharedPrefs)
│   └── repositories/          # Repository implementations
│
├── domain/                    # Business logic layer
│   ├── entities/              # Pure business entities
│   ├── repositories/          # Abstract contracts
│   └── usecases/              # Single-responsibility use cases
│
├── presentation/              # UI layer
│   ├── cubits/                # State management (Auth, Live, Movies, Series, Favorites)
│   ├── screens/               # App screens
│   └── widgets/               # Reusable widgets
│
├── injector.dart              # Dependency injection
└── main.dart                  # App entry point
```

### 📦 Key Packages

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management with Cubit pattern |
| `dio` | HTTP client with interceptors |
| `dartz` | Functional error handling (`Either<Failure, Success>`) |
| `equatable` | Value equality for entities |
| `better_player_plus` | Advanced video player |
| `flutter_secure_storage` | Encrypted credential storage |
| `shared_preferences` | Favorites persistence |
| `flutter_screenutil` | Responsive design |
| `cached_network_image` | Image caching |
| `flutter_localizations` | Arabic RTL support |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.16 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code
- Android device or emulator (API 21+)
- iOS 12+ (for iOS builds)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/iptv-flutter-app.git
   cd iptv-flutter-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### 🔧 Configuration

#### Android Setup

The app requires cleartext HTTP traffic (most IPTV servers use HTTP). This is already configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<application
    android:usesCleartextTraffic="true"
    android:networkSecurityConfig="@xml/network_security_config">
```

#### iOS Setup

HTTP traffic is enabled in `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## 🔌 Xtream Codes API

The app uses the standard **Xtream Codes API** protocol. You'll need three credentials from your IPTV provider:

- **Server URL** (e.g., `http://example.com:8080`)
- **Username**
- **Password**

### Supported Endpoints

| Action | Endpoint |
|--------|----------|
| Authentication | `GET {url}/player_api.php?username=X&password=Y` |
| Live Categories | `action=get_live_categories` |
| Live Streams | `action=get_live_streams&category_id=X` |
| VOD Categories | `action=get_vod_categories` |
| Movies | `action=get_vod_streams` |
| Movie Info | `action=get_vod_info&vod_id=X` |
| Series Categories | `action=get_series_categories` |
| Series List | `action=get_series` |
| Series Info (Episodes) | `action=get_series_info&series_id=X` |
| Short EPG | `action=get_short_epg&stream_id=X` |

### Stream URL Builders

```
Live:   {url}/live/{user}/{pass}/{stream_id}.m3u8
Movie:  {url}/movie/{user}/{pass}/{stream_id}.{ext}
Series: {url}/series/{user}/{pass}/{episode_id}.{ext}
```

---

## 📸 Screenshots

<!-- Add your screenshots here -->

| Login | Live TV | Movies | Player |
|-------|---------|--------|--------|
| _Add screenshot_ | _Add screenshot_ | _Add screenshot_ | _Add screenshot_ |

---

## 🎯 Roadmap

- [x] Xtream Codes authentication
- [x] Live TV with categories & search
- [x] VOD Movies with details page
- [x] Series with seasons & episodes
- [x] EPG (Electronic Program Guide)
- [x] Favorites system
- [x] Arabic RTL support
- [ ] Continue Watching (resume playback)
- [ ] External player integration (VLC, MX Player)
- [ ] M3U playlist parser (fallback)
- [ ] Parental controls
- [ ] Multi-profile support
- [ ] Download for offline viewing
- [ ] Chromecast support

---

## 🧪 Project Structure in Detail

### State Management (Cubit)

The app uses **Cubit** (a lightweight BLoC) for state management:

- `AuthCubit` — Login, logout, session persistence
- `LiveCubit` — Live channels, categories, EPG caching
- `MoviesCubit` — Movie catalog with filtering
- `SeriesCubit` — Series list + `SeriesDetailsCubit` for episodes
- `FavoritesCubit` — Favorites across all content types

### Error Handling

Uses `dartz`'s `Either<Failure, Success>` pattern:

```dart
Future<Either<Failure, UserCredentials>> login({...});
```

Failures are typed:
- `NetworkFailure` — Connection issues
- `AuthFailure` — Invalid credentials
- `ServerFailure` — Server errors
- `CacheFailure` — Local storage issues

### Localization

The app supports Arabic (RTL) and English:

```dart
locale: const Locale('ar'),
supportedLocales: const [Locale('ar'), Locale('en')],
localizationsDelegates: const [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## ⚠️ Disclaimer

This project is for **educational purposes only**. The app itself does not provide any IPTV content — users must provide their own legally-obtained Xtream Codes credentials. The developers are not responsible for any misuse of this application.

---

## 📧 Contact

**Your Name** — [@Ahmed Dabash](https://github.com/Dabash99)


---

<div align="center">

### ⭐ If you found this project helpful, please give it a star!

Made with ❤️ using Flutter

</div>