# Studiq — Handoff Summary

## What We Built Today

### App Rename
- Renamed everything from `academic_hub` / `Academic Hub` / `Study Sanctuary` → `studiq` / `Studiq`
- Updated: pubspec.yaml, all Dart imports, AndroidManifest, iOS Info.plist, web manifest

### Firebase iOS Fix
- `firebase_options.dart` previously threw `UnsupportedError` on iOS
- Re-ran `flutterfire configure` → iOS now properly registered
- **Remaining**: `xcodeproj` Ruby gem was missing during configure — install with `sudo gem install xcodeproj` then re-run `flutterfire configure` to fully complete iOS setup

### Splash Screen Cleanup
- Removed Flutter logo from iOS `LaunchScreen.storyboard`
- Added `values-v31/styles.xml` and `values-night-v31/styles.xml` for Android 12+ to suppress system splash icon
- Created `splash_icon_light.xml` / `splash_icon_dark.xml` (invisible same-color icons)

### App Icon
- Added `flutter_launcher_icons` package
- Source icon: `assets/icon/app_icon.png`
- Generated all Android mipmap + iOS AppIcon sizes via `dart run flutter_launcher_icons`

### Focus Report Screen (`Settings → Focus Report`)
- Day / Week / Month tabs with segmented control
- Summary cards: sessions count + focus time
- Day tab: 🔥 streak card + session dots
- Week tab: 7-bar animated chart (Mo–Su) + best day
- Month tab: 30-bar chart + daily average
- **AI Insights** card at bottom — "Coming Soon" placeholder ready to wire up
- History stored in SharedPreferences as `pomo_history_YYYY-MM-DD`

---

## Current APK
```
build/app/outputs/flutter-apk/app-release.apk  (61.2 MB)
```

---

## Known Issues / TODO

- [ ] Complete iOS Firebase setup: `sudo gem install xcodeproj` → `flutterfire configure`
- [ ] Android 12+ splash still flickers slightly on first cold launch — may need further tuning
- [ ] AI Insights feature (future): wire up Claude/Gemini API to analyze `pomo_history_*` keys
- [ ] App icon: if dark-mode adaptive icon background looks wrong, change `adaptive_icon_background` in pubspec.yaml and re-run icons

---

## Key File Locations

| File | Purpose |
|------|---------|
| `lib/features/stats/presentation/screens/focus_stats_screen.dart` | Focus Report screen |
| `lib/features/stats/presentation/providers/focus_stats_provider.dart` | Stats + streak providers |
| `lib/features/timer/presentation/providers/pomodoro_provider.dart` | Pomodoro + history persistence |
| `lib/features/today/presentation/screens/today_screen.dart` | Notification center |
| `lib/app/router/app_router.dart` | All routes |
| `assets/icon/app_icon.png` | App icon source |

---

## Important Commands

```bash
# Run app
flutter run

# Build release APK
flutter build apk --release

# After changing app icon
dart run flutter_launcher_icons

# Fix iOS Firebase (run once)
sudo gem install xcodeproj
flutterfire configure

# Clean build (if something looks wrong)
flutter clean && flutter run

# Analyze for errors
flutter analyze --no-fatal-infos
```
