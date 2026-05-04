# 📺 IPTV Player - Flutter App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![BLoC](https://img.shields.io/badge/BLoC-Cubit-0074D9?style=for-the-badge)
![Clean Architecture](https://img.shields.io/badge/Architecture-Clean-success?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

**A production-grade IPTV player built with Flutter, supporting Xtream Codes API with full Live TV, Movies, Series, Downloads, Smart Recommendations, and EPG support.**

[Features](#-features) • [Screenshots](#-screenshots) • [Architecture](#%EF%B8%8F-architecture) • [Getting Started](#-getting-started) • [API](#-xtream-codes-api) • [Contributing](#-contributing)

</div>

---

## ✨ Features

### 🎬 Content Support
- **📡 Live TV** — Stream live channels with category filtering and real-time search
- **🎞️ Movies (VOD)** — Browse movie library with posters, ratings, cast, plot, and full metadata
- **📺 Series** — Watch series organized by seasons with per-episode details and downloads
- **📅 EPG (Electronic Program Guide)** — View current and upcoming programs per channel
- **❤️ Favorites** — Save your favorite channels, movies, and series locally

### ⬇️ Downloads
- **📥 Movie Downloads** — Download full movies for offline playback
- **🎬 Episode Downloads** — Download individual series episodes
- **📊 Progress Tracking** — Real-time download progress with percentage indicator
- **✅ Download States** — Not started / Downloading / Completed / Failed with retry
- **🗑️ Manage Downloads** — Delete downloaded files from the downloads screen
- **▶️ Offline Playback** — Plays from local file automatically when downloaded

### 🕐 Watch History & Resume
- **⏯️ Resume Watching** — Continues from where you left off (movies)
- **📋 Watch History** — Keeps track of recently watched content (up to 20 items)
- **🔥 Keep Watching** — Dashboard carousel showing in-progress content with progress bars

### 🤖 Smart Recommendations
- **💡 "Because you watched X"** — Surfaces similar unwatched movies based on your last watched genre
- **📈 Trending Now** — Finds your most-watched genre across all history and shows top-rated unwatched content

### 🔍 Unified Search
- **Single search screen** for Live channels, Movies, and Series
- **Filters** — Genre, Year, and minimum Rating pickers
- **Tab navigation** — switch between Live / Movies / Series results instantly

### 📊 Statistics
- **Watch time this month** and all-time total
- **Streak days** — consecutive days with watch activity
- **Top genre** — computed from your full watch history
- **Content breakdown** — movies vs series count
- **Recently watched** list with progress bars

### 🎮 Player Gestures
- **Swipe up/down on left** → screen brightness
- **Swipe up/down on right** → system volume
- **Double-tap left** → seek −10 seconds
- **Double-tap right** → seek +10 seconds

### 📲 Picture-in-Picture (PiP)
- **PiP button** in the player toolbar for VOD content
- Keeps playing in a floating window while using other apps (Android)

### ⏭️ Auto-Play Next Episode
- When an episode finishes, a **5-second countdown overlay** appears
- Options to **Play Now** or **Cancel**; auto-advances on timeout

### 🎨 UI/UX
- **🌙 Modern Dark Theme** with blue accent (`#3D5AFF`) and cyan highlight (`#00F2FF`)
- **🌐 Full Arabic RTL Support** with proper localization delegates and explicit `Directionality`
- **📱 Responsive Design** using `flutter_screenutil` (390×844 base)
- **⚡ Smooth Animations** and transitions
- **🎯 Bottom Navigation** with 6 main sections (Dashboard, Live TV, Movies, Series, Favorites, Settings)

### 🔐 Security & Storage
- **🔒 Secure Credentials** stored via `flutter_secure_storage` (encrypted)
- **💾 Local Persistence** using `SharedPreferences` (favorites, downloads, watch history)
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
│   │   ├── downloads_datasource.dart    # File download + progress tracking
│   │   ├── favorites_datasource.dart
│   │   ├── watch_history_datasource.dart
│   │   └── iptv_remote_datasource.dart
│   └── repositories/          # Repository implementations
│
├── domain/                    # Business logic layer
│   ├── entities/              # Pure business entities
│   ├── repositories/          # Abstract contracts
│   └── usecases/              # Single-responsibility use cases
│
├── presentation/              # UI layer
│   ├── cubits/                # State management
│   │   ├── auth_cubit.dart
│   │   ├── downloads_cubit.dart
│   │   ├── favorites_cubit.dart
│   │   ├── live_cubit.dart
│   │   ├── movies_cubit.dart
│   │   ├── series_cubit.dart
│   │   └── watch_history_cubit.dart
│   ├── screens/
│   │   ├── dashboard_screen.dart       # Home + recommendations + trending
│   │   ├── search_screen.dart          # Unified search (Live / Movies / Series)
│   │   ├── statistics_screen.dart      # Watch stats + top genre
│   │   ├── movie_details_screen.dart
│   │   ├── series_screen.dart          # Series list + episode details + downloads
│   │   ├── video_player_screen.dart    # Gestures + PiP + auto-play next
│   │   ├── downloads_screen.dart
│   │   ├── favorites_screen.dart
│   │   └── ...
│   └── widgets/               # Reusable widgets
│
├── injector.dart              # Dependency injection
└── main.dart                  # App entry point
```

### 📦 Key Packages

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management with Cubit pattern |
| `dio` | HTTP client + file download with progress |
| `dartz` | Functional error handling (`Either<Failure, Success>`) |
| `equatable` | Value equality for entities |
| `better_player_plus` | Advanced video player with PiP support |
| `flutter_secure_storage` | Encrypted credential storage |
| `shared_preferences` | Favorites, downloads, watch history persistence |
| `path_provider` | App documents directory for downloaded files |
| `screen_brightness` | Gesture-controlled screen brightness |
| `volume_controller` | Gesture-controlled system volume |
| `flutter_screenutil` | Responsive design |
| `cached_network_image` | Image caching |
| `flutter_localizations` | Arabic RTL support |
| `intl` | Internationalization |

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
   git clone https://github.com/Dabash99/IPTV_withclaude
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

The app requires cleartext HTTP traffic (most IPTV servers use HTTP). Already configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<application
    android:usesCleartextTraffic="true"
    android:networkSecurityConfig="@xml/network_security_config">

<activity
    android:supportsPictureInPicture="true"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|...">
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

### Download Storage

Downloaded files are saved to:
```
{appDocumentsDir}/iptv_downloads/{type}_{contentId}_{name}.{ext}
```

Supported download formats: `mp4`, `mkv`, `avi`, `webm` (HLS `.m3u8` streams cannot be downloaded).

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
- [x] Continue Watching (resume playback)
- [x] Watch history (up to 20 items)
- [x] Download movies for offline viewing
- [x] Download individual series episodes
- [x] Dashboard with "Keep Watching" carousel
- [x] Smart Recommendations ("Because you watched X")
- [x] Trending Now rail (genre-based)
- [x] Unified Search (Live + Movies + Series + filters)
- [x] Statistics page (watch time, streak, top genre)
- [x] Player gestures (brightness / volume / seek)
- [x] Picture-in-Picture (PiP) mode
- [x] Auto-play next episode with countdown

---

## 🧪 Project Structure in Detail

### State Management (Cubit)

The app uses **Cubit** (a lightweight BLoC) for state management:

- `AuthCubit` — Login, logout, session persistence
- `LiveCubit` — Live channels, categories, EPG caching
- `MoviesCubit` — Movie catalog with filtering
- `SeriesCubit` — Series list + `SeriesDetailsCubit` for episodes
- `FavoritesCubit` — Favorites across all content types
- `DownloadsCubit` — Download queue, progress tracking, local file management
- `WatchHistoryCubit` — Watch history with resume position

### Player Gestures

The video player overlays a transparent `GestureDetector` on top of `BetterPlayer`:

| Gesture | Action |
|---------|--------|
| Vertical drag — left half | Screen brightness |
| Vertical drag — right half | System volume |
| Double-tap — left half | Seek −10 seconds |
| Double-tap — right half | Seek +10 seconds |

Visual indicators (vertical progress bar + percentage) appear and auto-hide after 1.5 seconds.

### Smart Recommendations

Recommendations are computed at runtime from the loaded catalog and watch history — no backend required:

1. **"Because you watched X"** — matches the most recently watched movie's genre against the full catalog
2. **"Trending [Genre]"** — counts genre frequency across all history items, picks the top genre, then shows the highest-rated unwatched movies in it

### Download System

The download system (`DownloadsDataSource`) uses Dio for file download with real-time progress:

```dart
cubit.startDownload(
  contentId: id,
  name: 'Episode Title',
  image: coverUrl,
  type: 'series', // or 'movie'
  url: streamUrl,
  extension: 'mp4',
);
```

Download state is persisted in `SharedPreferences` and survives app restarts.

### Error Handling

Uses `dartz`'s `Either<Failure, Success>` pattern:

```dart
Future<Either<Failure, UserCredentials>> login({...});
```

Failures are typed: `NetworkFailure`, `AuthFailure`, `ServerFailure`, `CacheFailure`.

### Localization

The app defaults to Arabic (RTL):

```dart
locale: const Locale('ar'),
supportedLocales: const [Locale('ar'), Locale('en')],
localizationsDelegates: const [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
```

RTL is also enforced explicitly on detail screens via `Directionality(textDirection: TextDirection.rtl)`.

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

**Ahmed Dabash** — [@Dabash99](https://github.com/Dabash99)

---

<div align="center">

### ⭐ If you found this project helpful, please give it a star!

Made with ❤️ using Flutter

</div>
