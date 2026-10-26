# AI Agent Development Guidelines (AGENTS_EN.md)

This document defines the architecture, conventions, design patterns, and quality standards that **every AI agent must respect** when contributing to **IPTV Play**.

---

## 🏛️ Project Architecture

The project follows a decoupled layered architecture:

```text
lib/
├── models/       # Immutable domain entities and JSON / Map serialization.
├── services/     # HTTP clients, disk I/O, decoders, and external APIs.
├── providers/    # Reactive state management via ChangeNotifier (Provider).
└── ui/           # Screens, reusable widgets, and visual themes.
test/
├── models_test.dart         # Unit tests for domain models.
├── m3u_parser_test.dart      # Unit tests for M3U parsing / VOD & series regex.
├── tv_focusable_test.dart    # Widget & Smart TV D-Pad navigation tests.
├── user_activity_test.dart   # Behavioral tests for reactive state and persistence.
└── widget_test.dart          # Application startup smoke test.
```

### Layer Dependency Rules:
1. **`models/`**: Must not import UI packages or services. They are pure Dart classes with `copyWith`, `toMap` / `toJson` methods and factory constructors such as `fromXtreamJson` or `fromMap`.
2. **`services/`**: Must not import `BuildContext` or Flutter widgets. They manage disk I/O (`File`), network (`Dio`), or local storage (`SharedPreferences`).
3. **`providers/`**: Orchestrate services, expose immutable getters for state, and call `notifyListeners()` after mutations.
4. **`ui/`**: 
   - Use `context.watch<T>()` strictly inside `build()` methods to subscribe to state changes.
   - Use `context.read<T>()` inside callbacks (`onPressed`, `onTap`, etc.).

---

## 📋 Core Rules for Agents

### 1. Official Naming and Identifiers
- **Official package name:** `iptv_play` (in `pubspec.yaml`).
- **Application ID / Bundle ID:** `com.iptvplay.app` (on Android, macOS, and iOS).
- **Display name:** `IPTV Play`.
- **Strict Prohibition:** Do not reintroduce references to legacy project or application names.

### 2. Smart TV Support and Remote Navigation (10-Foot UI)
The entire interface must be 100% operable from a couch using a standard remote control (D-Pad):
- **Component `TvFocusable`:** Any interactive element across the main views (movie cards, episodes, channels, sidebar items) must be wrapped in `TvFocusable`.
- **Focus Highlight:** Must feature smooth scaling (`1.05x`), a cyan neon border (`AppTheme.primary`), and a luminous glow (`AppTheme.primaryGlow`).
- **Remote Keys:** Keyboard event listeners in the player must handle:
  - `LogicalKeyboardKey.select`, `enter`, `space`, `gameButtonA`.
  - Media keys: `mediaPlay`, `mediaPause`, `mediaPlayPause`, `mediaFastForward`, `mediaRewind`.
  - Navigation: `escape`, `goBack`, directional arrows.

### 3. Centralized Logging Protocol (`LogService`)
Every significant system event must be recorded in the centralized log service via the `LogService.instance` singleton:
- **Allowed categories:** `LogCategory.network`, `LogCategory.player`, `LogCategory.epg`, `LogCategory.downloads`, `LogCategory.server`, `LogCategory.system`.
- **Levels:** `LogLevel.info`, `LogLevel.warning`, `LogLevel.error`, `LogLevel.success`.
- **Technical details:** When catching exceptions or network errors, always pass the message or stack trace in the `details:` parameter.

```dart
LogService.instance.error(
  LogCategory.network,
  'Failed to download EPG guide',
  details: e.toString(),
);
```

### 4. Offline Downloads and Crash Resilience
- **Local Storage:** Media files must be saved under the path returned by `getApplicationDocumentsDirectory()` in the `iptv_offline/` subdirectory.
- **Resumable HTTP Range:** All VOD downloads (movies and series) must support resumption using the `Range: bytes=<local_bytes>-` header and write in `FileMode.append`. Never restart a download from scratch if a partial file exists.
- **Live Recordings (PVR):** Live streams are captured incrementally into `.ts` files. If the application terminates unexpectedly, on next startup the existing file must be detected and marked as `DownloadStatus.completed` so the recorded segment remains playable.
- **Speed & ETA:** Monitor speed across ~600ms rolling windows and update `speedBytesPerSecond` to feed the reactive UI.

### 5. User Preferences Persistence
- Global settings (selected sort orders, last active profile, default volume, active language, etc.) must be persisted in `SharedPreferences` with prefixed keys (e.g. `pref_live_sort`, `pref_vod_sort`, `pref_series_sort`, `pref_app_language`).
- Do not block the main thread at launch; load saved values asynchronously in the constructor or `_init()` method of the respective provider.

### 6. Platform Permissions (macOS and Android TV)
- **macOS Entitlements:** When adding features that interact with sockets or files outside the sandbox, update **BOTH** entitlement files (`DebugProfile.entitlements` and `Release.entitlements`):
  - `com.apple.security.network.client`
  - `com.apple.security.network.server` (LAN stream server on port 8088)
  - `com.apple.security.files.user-selected.read-write` (JSON backups)
  - `com.apple.security.files.downloads.read-write`
- **Android TV (`AndroidManifest.xml`):** Keep `android.software.leanback`, `LEANBACK_LAUNCHER`, `touchscreen = false`, and `usesCleartextTraffic = true` declared at all times (essential for IPTV HTTP streams).

### 7. UI Styling & Best Practices
- **Premium Dark Theme:** The entire interface must use constants defined in `AppTheme` (`AppTheme.background`, `AppTheme.surface`, `AppTheme.primary`, `AppTheme.accentRed`, etc.).
- **Material Ink Splash Safety:** If wrapping a `ListTile` inside a `Container` or `DecoratedBox` with borders or colors, always wrap it in `Material(color: Colors.transparent, child: ...)` to prevent Flutter's `_debugCheckHasMaterial` assertion.
- **Modal Dialogs:** Must use `AppTheme.surface` background and subtle borders with `AppTheme.border`.
- **Visual Performance:** Use `ListView.builder` or `ListView.separated` for large collections. Avoid mapping full lists to children of scrolling `Column` or `Row`.

### 8. Security and Privacy
- Never commit passwords, credentials, private URLs with auth tokens, or certificates to source control.
- Maintain `.gitignore` with exclusions for `*.env`, `*.jks`, `*.keystore`, `*.p12`, `iptv_cache/`, and `iptv_offline/`.

### 9. Documentation Synchronization
Any change in features, supported platforms, or workflows must be reflected in:
- [README.md](file:///Users/alejandrorodriguez/APPs/rea/iptvexp/README.md) (English version)
- [README_ES.md](file:///Users/alejandrorodriguez/APPs/rea/iptvexp/README_ES.md) (Spanish version)
- [COMPATIBILITY.md](file:///Users/alejandrorodriguez/APPs/rea/iptvexp/COMPATIBILITY.md) (English hardware support matrix)
- [COMPATIBILIDAD.md](file:///Users/alejandrorodriguez/APPs/rea/iptvexp/COMPATIBILIDAD.md) (Spanish hardware support matrix)
- [USER_MANUAL.md](file:///Users/alejandrorodriguez/APPs/rea/iptvexp/USER_MANUAL.md) (English step-by-step user manual)
- [MANUAL_USUARIO.md](file:///Users/alejandrorodriguez/APPs/rea/iptvexp/MANUAL_USUARIO.md) (Spanish step-by-step user manual)
- [AGENTS_EN.md](file:///Users/alejandrorodriguez/APPs/rea/iptvexp/AGENTS_EN.md) (English AI guidelines)
- [AGENTS.md](file:///Users/alejandrorodriguez/APPs/rea/iptvexp/AGENTS.md) (Spanish AI guidelines)

---

## 🧪 Mandatory Verification Before Completion

Before marking any task complete or delivering changes to the user, the agent **MUST run and verify**:

```bash
# 1. Unit, widget, and behavioral test suite (all tests must pass)
flutter test

# 2. Static analysis (MUST report 0 issues)
flutter analyze
```

If `flutter test` or `flutter analyze` reports any error or warning, fix it immediately before notifying the user.
