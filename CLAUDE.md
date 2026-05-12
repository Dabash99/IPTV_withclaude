# IPTV Player - Project Context

> ⚠️ **مهم لـ Claude**: متفتحش الملفات كلها في البداية. اقرا الـ context ده الأول، وافتح بس الملف اللي محتاجه للـ task المحدد. اتبع الـ rules في آخر الملف.

---

## 1. Project Overview

**Type:** Flutter IPTV Player App
**Protocol:** Xtream Codes API
**State Management:** Cubit (flutter_bloc)
**Architecture:** Clean Architecture (Data / Domain / Presentation)
**Locale:** Arabic RTL (default) + English
**Design:** Dark theme — Primary `#3D5AFF`, Accent `#00F2FF`
**Sizing:** flutter_screenutil — base `390 × 844`
**Min SDK:** Flutter 3.16+, Dart 3.0+, Android API 21+, iOS 12+

---

## 2. Folder Structure

```
lib/
├── core/
│   ├── constants/        # Colors, API endpoints, storage keys
│   ├── errors/           # Failures + Exceptions
│   └── network/          # DioHelper + interceptors
│
├── data/
│   ├── models/           # JSON serializable models
│   ├── datasources/
│   │   ├── iptv_remote_datasource.dart
│   │   ├── downloads_datasource.dart
│   │   ├── favorites_datasource.dart
│   │   └── watch_history_datasource.dart
│   └── repositories/     # Repository implementations
│
├── domain/
│   ├── entities/         # Pure business entities
│   ├── repositories/     # Abstract contracts
│   └── usecases/         # Single-responsibility use cases
│
├── presentation/
│   ├── cubits/
│   │   ├── auth_cubit.dart
│   │   ├── live_cubit.dart
│   │   ├── movies_cubit.dart
│   │   ├── series_cubit.dart
│   │   ├── favorites_cubit.dart
│   │   ├── downloads_cubit.dart
│   │   └── watch_history_cubit.dart
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   ├── search_screen.dart
│   │   ├── statistics_screen.dart
│   │   ├── movie_details_screen.dart
│   │   ├── series_screen.dart
│   │   ├── video_player_screen.dart
│   │   ├── downloads_screen.dart
│   │   └── favorites_screen.dart
│   └── widgets/          # Reusable widgets
│
├── injector.dart         # DI setup
└── main.dart
```

---

## 3. Key Packages

| Package | Purpose |
| --- | --- |
| `flutter_bloc` | State management (Cubit) |
| `dio` | HTTP + file download with progress |
| `dartz` | `Either<Failure, Success>` |
| `equatable` | Value equality |
| `better_player_plus` | Video player + PiP |
| `flutter_secure_storage` | Encrypted credentials |
| `shared_preferences` | Favorites / downloads / history |
| `path_provider` | Local download directory |
| `screen_brightness` | Gesture brightness control |
| `volume_controller` | Gesture volume control |
| `flutter_screenutil` | Responsive sizing |
| `cached_network_image` | Image caching |
| `intl` + `flutter_localizations` | Arabic RTL + i18n |

---

## 4. Xtream Codes API Reference

**Auth:** `GET {url}/player_api.php?username=X&password=Y`

**Endpoints (all use `?action=` query):**
- `get_live_categories` / `get_live_streams&category_id=X`
- `get_vod_categories` / `get_vod_streams` / `get_vod_info&vod_id=X`
- `get_series_categories` / `get_series` / `get_series_info&series_id=X`
- `get_short_epg&stream_id=X`

**Stream URL Builders:**
```
Live:   {url}/live/{user}/{pass}/{stream_id}.m3u8
Movie:  {url}/movie/{user}/{pass}/{stream_id}.{ext}
Series: {url}/series/{user}/{pass}/{episode_id}.{ext}
```

---

## 5. Conventions & Patterns

### Error Handling
- Every repository method returns `Future<Either<Failure, T>>`
- Failure types: `NetworkFailure`, `AuthFailure`, `ServerFailure`, `CacheFailure`
- Cubits handle `Either.fold((failure) => emit(Error), (data) => emit(Success))`

### State Management
- Each feature has its own Cubit
- States are sealed classes with Equatable
- Use `BlocBuilder` for UI, `BlocListener` for side effects (navigation, snackbars)

### Storage
- **Credentials only:** `flutter_secure_storage` (encrypted)
- **Everything else** (favorites, downloads, watch history): `SharedPreferences`
- Download files: `{appDocumentsDir}/iptv_downloads/{type}_{contentId}_{name}.{ext}`

### UI
- Default `Locale('ar')` — RTL
- Force RTL on detail screens via `Directionality(textDirection: TextDirection.rtl)`
- All sizes via `.w`, `.h`, `.sp` from `flutter_screenutil`
- Colors from `core/constants/colors.dart`

### Downloads
- HLS `.m3u8` cannot be downloaded — supported: `mp4`, `mkv`, `avi`, `webm`
- Progress tracked via Dio's `onReceiveProgress`
- States: NotStarted / Downloading / Completed / Failed

### Player
- Gestures via `GestureDetector` overlay on `BetterPlayer`
- Left half = brightness, Right half = volume
- Double-tap left/right = ±10s seek
- PiP only for VOD (not Live)
- Auto-play next episode: 5s countdown overlay

---

## 6. Android-Specific Notes

`AndroidManifest.xml` requires:
- `INTERNET` permission
- `usesCleartextTraffic="true"` (most IPTV servers are HTTP)
- `networkSecurityConfig="@xml/network_security_config"`
- Activity: `supportsPictureInPicture="true"` + proper `configChanges`

---

## 7. Common Tasks — Where to Look

| لو عايز تعمل... | افتح بس... |
| --- | --- |
| تعديل في الـ login flow | `presentation/cubits/auth_cubit.dart` + `screens/login_screen.dart` |
| إضافة endpoint جديد | `data/datasources/iptv_remote_datasource.dart` + `core/constants/` |
| تغيير شكل الـ player | `screens/video_player_screen.dart` |
| تعديل الـ download logic | `data/datasources/downloads_datasource.dart` + `cubits/downloads_cubit.dart` |
| تعديل الـ recommendations | `screens/dashboard_screen.dart` (logic inline) |
| إضافة لغة / ترجمة | `main.dart` + `flutter_localizations` setup |
| تعديل الـ theme/colors | `core/constants/colors.dart` + `main.dart` ThemeData |

---

## 8. Rules for Claude (مهم جداً)

1. **متفتحش الملفات كلها على بعض.** افتح بس الملف اللي الـ task متعلق بيه. لو محتاج تفهم pattern، افتح ملف واحد كمثال.

2. **اسأل لو الـ task مش واضح** بدل ما تفتح 10 ملفات تحاول تخمن.

3. **استخدم الـ Common Tasks table فوق** لتحديد الملف الصح من أول مرة.

4. **متغيرش الـ architecture** — البروجيكت Clean Architecture، حافظ على فصل الـ layers.

5. **متعملش rewrites كاملة للملفات.** عدّل targeted بس — أحمد بيفضل التعديلات الصغيرة المركزة.

6. **اتكلم عربي مصري** لما ترد على أحمد.

7. **متضيفش packages جديدة من غير ما تسأل** — استخدم اللي موجود.

8. **متعدلش في android/ios إلا لو أحمد طلب صراحة.**

9. **لما تكتب كود، خليه يطابق الـ style الموجود** (نفس naming, نفس structure للـ cubits, نفس error handling).

10. **لو هتعمل feature جديد:** اعمل entity → repository contract → usecase → datasource → repository impl → cubit → screen. اتبع الترتيب ده.

---

## 9. Things to Avoid

- ❌ متستخدمش `setState` في الـ screens الجديدة — استخدم Cubit
- ❌ متعملش HTTP calls مباشرة في الـ presentation layer
- ❌ متستخدمش `MediaQuery.size` — استخدم `flutter_screenutil`
- ❌ متخزنش credentials في `SharedPreferences` — `flutter_secure_storage` بس
- ❌ متفترضش إن الـ stream HLS قابل للتحميل