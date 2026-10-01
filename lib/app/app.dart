import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studiq/app/router/app_router.dart';
import 'package:studiq/app/theme/app_theme.dart';

const _themePrefKey = 'theme_mode';
const _profileNameKey = 'profile_name';
const _profileRoleKey = 'profile_role';
const _profilePhotoUrlKey = 'profile_photo_url';
const _onboardingSeenKey = 'onboarding_seen';
const _notificationsEnabledKey = 'notifications_enabled';
const _photoUrlSentinel = Object();

class UserProfile {
  final String name;
  final String role;
  final String? photoUrl;

  const UserProfile({required this.name, required this.role, this.photoUrl});

  UserProfile copyWith({
    String? name,
    String? role,
    Object? photoUrl = _photoUrlSentinel,
  }) =>
      UserProfile(
        name: name ?? this.name,
        role: role ?? this.role,
        photoUrl: identical(photoUrl, _photoUrlSentinel)
            ? this.photoUrl
            : photoUrl as String?,
      );
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier(UserProfile initial) : super(initial);

  Future<void> update({
    String? name,
    String? role,
    Object? photoUrl = _photoUrlSentinel,
  }) async {
    state = state.copyWith(name: name, role: role, photoUrl: photoUrl);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileNameKey, state.name);
    await prefs.setString(_profileRoleKey, state.role);
    if (state.photoUrl != null) {
      await prefs.setString(_profilePhotoUrlKey, state.photoUrl!);
    } else {
      await prefs.remove(_profilePhotoUrlKey);
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'name': state.name,
          'role': state.role,
          if (!identical(photoUrl, _photoUrlSentinel))
            'photoUrl': state.photoUrl,
        },
        SetOptions(merge: true),
      );
    }
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  throw UnimplementedError('Override in main with saved preference');
});

UserProfile userProfileFromPrefs(SharedPreferences prefs) {
  return UserProfile(
    name: prefs.getString(_profileNameKey) ?? 'Student',
    role: prefs.getString(_profileRoleKey) ?? 'Student',
    photoUrl: prefs.getString(_profilePhotoUrlKey),
  );
}

class OnboardingSeenNotifier extends StateNotifier<bool> {
  OnboardingSeenNotifier(bool initial) : super(initial);

  Future<void> markSeen() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }
}

final onboardingSeenProvider =
    StateNotifierProvider<OnboardingSeenNotifier, bool>((ref) {
  throw UnimplementedError('Override in main with saved preference');
});

bool onboardingSeenFromPrefs(SharedPreferences prefs) =>
    prefs.getBool(_onboardingSeenKey) ?? false;

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  NotificationsEnabledNotifier(bool initial) : super(initial);

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
  }
}

final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsEnabledNotifier, bool>((ref) {
  throw UnimplementedError('Override in main with saved preference');
});

bool notificationsEnabledFromPrefs(SharedPreferences prefs) =>
    prefs.getBool(_notificationsEnabledKey) ?? true;

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(ThemeMode initial) : super(initial);

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  throw UnimplementedError('Override in main with saved preference');
});

ThemeMode themeModeFromPrefs(SharedPreferences prefs) {
  final saved = prefs.getString(_themePrefKey);
  if (saved == 'dark') return ThemeMode.dark;
  return ThemeMode.light;
}

class StudiqApp extends ConsumerWidget {
  const StudiqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Studiq',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
