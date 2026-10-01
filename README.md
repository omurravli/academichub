# Study Sanctuary — Academic Productivity Hub

A clean, modern academic planner built with Flutter using the **Academic Serenity** design system (Manrope + Inter, serene blue + sage green palette).

---

## Quick Start

```bash
# 1. Install dependencies
flutter pub get

# 2. Run code generation (Drift + Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 3. Run the app
flutter run
```

> Re-run code generation whenever you edit `app_database.dart` or add `@riverpod` annotations.

---

## Fonts

The app uses **Manrope** (headings) and **Inter** (body) via `google_fonts`. No manual font download needed — they stream at runtime. 

The `assets/fonts/` files are placeholder stubs. You can delete them and remove the `fonts:` section from `pubspec.yaml` if using only `google_fonts`.

---

## iOS Permissions

In `ios/Runner/Info.plist` (already added):

```xml
<key>NSLocalNotificationUsageDescription</key>
<string>Study Sanctuary uses notifications to remind you of upcoming tasks, exams, and deadlines.</string>
```

Call `NotificationService.instance.requestPermissions()` at an appropriate point (e.g., after onboarding).

## Android Permissions

In `android/app/src/main/AndroidManifest.xml` (already added):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

On Android 12+ you may also need to direct the user to grant `SCHEDULE_EXACT_ALARM` in system settings.

---

## Project Structure

```
lib/
  main.dart                         ← Entry point
  app/
    app.dart                        ← MaterialApp.router + themeModeProvider
    router/app_router.dart          ← go_router config + AppRoutes constants
    theme/
      app_colors.dart               ← Full Academic Serenity color palette
      app_text_styles.dart          ← Manrope + Inter text styles
      app_spacing.dart              ← 4pt spacing tokens
      app_theme.dart                ← AppTheme.light() / AppTheme.dark()
    widgets/main_shell.dart         ← Bottom nav shell (ShellRoute)
  core/
    providers/repository_providers.dart   ← DB → DataSource → Repository wiring
    utils/mock_data.dart            ← Seed data for UI preview
    widgets/
      app_widgets.dart              ← AppCard, SectionHeader, EmptyState, FilterChip, etc.
      planner_item_tile.dart        ← PlannerItemTile
      project_card.dart             ← ProjectCard
    extensions/datetime_extensions.dart
  data/
    database/app_database.dart      ← Drift DB (tables + provider)
    datasources/
      planner_local_datasource.dart
      project_local_datasource.dart
      planner_remote_datasource.dart  ← abstract interface (TODO: implement)
      project_remote_datasource.dart  ← abstract interface (TODO: implement)
    services/
      notification_service.dart
      recurrence_service.dart
  features/
    splash/           → SplashScreen
    onboarding/       → OnboardingScreen (3 steps)
    today/            → TodayScreen (bento dashboard)
    calendar/         → CalendarScreen (month view + event list)
    planner/          → PlannerScreen + Detail + Add/Edit
    projects/         → ProjectsScreen + Detail + Add/Edit
    settings/         → SettingsScreen (theme toggle, etc.)
```

---

## Where to Continue

**Next screen to build:** Start with `add_edit_planner_item_screen.dart` to wire the form to `PlannerRepositoryImpl.create()`. Then do the same for projects.

**To add real DB persistence:** Remove `mockPlannerItemsProvider` / `mockProjectsProvider` references in screens and replace with the `plannerItemsProvider` / `projectsProvider` stream providers (which read from Drift).

---

## Adding a Remote Backend Later

1. Create a concrete class implementing `PlannerRemoteDataSource` (e.g. `SupabasePlannerDataSource`).
2. In `PlannerRepositoryImpl`, inject both local and remote data sources.
3. Decide on a sync strategy (local-first, remote-first, or conflict resolution).
4. Update `repository_providers.dart` to inject the remote data source — **no UI changes needed**.

The domain layer (`PlannerRepository` interface) and Riverpod providers remain unchanged.

---

## Code Generation

Drift requires generated files (`*.g.dart`). Always run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

If you see "part of" errors, this is why.
