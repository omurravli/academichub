import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:studiq/app/app.dart';
import 'package:studiq/data/services/notification_service.dart';
// Run `flutterfire configure` to generate this file
import 'package:studiq/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = themeModeFromPrefs(prefs);
  final savedProfile = userProfileFromPrefs(prefs);
  final onboardingSeen = onboardingSeenFromPrefs(prefs);
  final notificationsEnabled = notificationsEnabledFromPrefs(prefs);

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(
          (ref) => ThemeModeNotifier(savedTheme),
        ),
        userProfileProvider.overrideWith(
          (ref) => UserProfileNotifier(savedProfile),
        ),
        onboardingSeenProvider.overrideWith(
          (ref) => OnboardingSeenNotifier(onboardingSeen),
        ),
        notificationsEnabledProvider.overrideWith(
          (ref) => NotificationsEnabledNotifier(notificationsEnabled),
        ),
      ],
      child: const StudiqApp(),
    ),
  );
}
