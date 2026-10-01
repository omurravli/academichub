import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studiq/data/services/notification_service.dart';

enum TimerMode { focus, shortBreak, longBreak }

enum TimerStatus { idle, running, paused }

class PomodoroState {
  final TimerMode mode;
  final TimerStatus status;
  final int secondsRemaining;
  final int pomodorosCompleted;
  final int todaySessions;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int pomodorosUntilLong;

  const PomodoroState({
    this.mode = TimerMode.focus,
    this.status = TimerStatus.idle,
    this.secondsRemaining = 25 * 60,
    this.pomodorosCompleted = 0,
    this.todaySessions = 0,
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.pomodorosUntilLong = 4,
  });

  int get totalSeconds => switch (mode) {
        TimerMode.focus => focusMinutes * 60,
        TimerMode.shortBreak => shortBreakMinutes * 60,
        TimerMode.longBreak => longBreakMinutes * 60,
      };

  double get progress =>
      totalSeconds > 0 ? secondsRemaining / totalSeconds : 1.0;

  String get timeString {
    final m = secondsRemaining ~/ 60;
    final s = secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get modeLabel => switch (mode) {
        TimerMode.focus => 'FOCUS SESSION',
        TimerMode.shortBreak => 'SHORT BREAK',
        TimerMode.longBreak => 'LONG BREAK',
      };

  PomodoroState copyWith({
    TimerMode? mode,
    TimerStatus? status,
    int? secondsRemaining,
    int? pomodorosCompleted,
    int? todaySessions,
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? pomodorosUntilLong,
  }) =>
      PomodoroState(
        mode: mode ?? this.mode,
        status: status ?? this.status,
        secondsRemaining: secondsRemaining ?? this.secondsRemaining,
        pomodorosCompleted: pomodorosCompleted ?? this.pomodorosCompleted,
        todaySessions: todaySessions ?? this.todaySessions,
        focusMinutes: focusMinutes ?? this.focusMinutes,
        shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
        longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
        pomodorosUntilLong: pomodorosUntilLong ?? this.pomodorosUntilLong,
      );
}

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  PomodoroNotifier() : super(const PomodoroState()) {
    _loadSettings();
  }

  Timer? _ticker;

  // ── Playback controls ──────────────────────────────────────────────────────

  void start() {
    if (state.status == TimerStatus.running) return;
    state = state.copyWith(status: TimerStatus.running);
    _schedulePushNotification();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    _ticker?.cancel();
    _ticker = null;
    NotificationService.instance.cancelTimerNotification();
    state = state.copyWith(status: TimerStatus.paused);
  }

  void reset() {
    _ticker?.cancel();
    _ticker = null;
    NotificationService.instance.cancelTimerNotification();
    state = state.copyWith(
      status: TimerStatus.idle,
      secondsRemaining: state.totalSeconds,
    );
  }

  void switchMode(TimerMode mode) {
    _ticker?.cancel();
    _ticker = null;
    NotificationService.instance.cancelTimerNotification();
    final seconds = switch (mode) {
      TimerMode.focus => state.focusMinutes * 60,
      TimerMode.shortBreak => state.shortBreakMinutes * 60,
      TimerMode.longBreak => state.longBreakMinutes * 60,
    };
    state = state.copyWith(
      mode: mode,
      status: TimerStatus.idle,
      secondsRemaining: seconds,
    );
  }

  // Called by the screen when the app returns from background.
  void adjustForElapsed(int elapsedSeconds) {
    if (state.status != TimerStatus.running) return;
    final remaining = state.secondsRemaining - elapsedSeconds;
    if (remaining <= 0) {
      _ticker?.cancel();
      _ticker = null;
      _onComplete();
    } else {
      state = state.copyWith(secondsRemaining: remaining);
    }
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  Future<void> updateSettings({
    required int focusMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
    required int pomodorosUntilLong,
  }) async {
    _ticker?.cancel();
    _ticker = null;
    NotificationService.instance.cancelTimerNotification();

    final newSeconds = switch (state.mode) {
      TimerMode.focus => focusMinutes * 60,
      TimerMode.shortBreak => shortBreakMinutes * 60,
      TimerMode.longBreak => longBreakMinutes * 60,
    };

    state = state.copyWith(
      status: TimerStatus.idle,
      focusMinutes: focusMinutes,
      shortBreakMinutes: shortBreakMinutes,
      longBreakMinutes: longBreakMinutes,
      pomodorosUntilLong: pomodorosUntilLong,
      secondsRemaining: newSeconds,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomo_focus', focusMinutes);
    await prefs.setInt('pomo_short', shortBreakMinutes);
    await prefs.setInt('pomo_long', longBreakMinutes);
    await prefs.setInt('pomo_until_long', pomodorosUntilLong);
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _tick() {
    if (state.secondsRemaining <= 1) {
      _ticker?.cancel();
      _ticker = null;
      _onComplete();
      return;
    }
    state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
  }

  Future<void> _onComplete() async {
    final wasPomodoro = state.mode == TimerMode.focus;
    final newCount =
        wasPomodoro ? state.pomodorosCompleted + 1 : state.pomodorosCompleted;

    final nextMode = wasPomodoro
        ? (newCount % state.pomodorosUntilLong == 0
            ? TimerMode.longBreak
            : TimerMode.shortBreak)
        : TimerMode.focus;

    final nextSeconds = switch (nextMode) {
      TimerMode.focus => state.focusMinutes * 60,
      TimerMode.shortBreak => state.shortBreakMinutes * 60,
      TimerMode.longBreak => state.longBreakMinutes * 60,
    };

    NotificationService.instance.showTimerComplete(
      state.mode == TimerMode.focus
          ? 'Focus session complete!'
          : 'Break time is over!',
      state.mode == TimerMode.focus
          ? 'Time for a well-deserved break.'
          : 'Ready to focus? Start your next session.',
    );

    final newTodaySessions =
        wasPomodoro ? state.todaySessions + 1 : state.todaySessions;

    if (wasPomodoro) {
      final prefs = await SharedPreferences.getInstance();
      final today = _todayKey();
      await prefs.setString('pomo_today_date', today);
      await prefs.setInt('pomo_today_sessions', newTodaySessions);
      await prefs.setInt('pomo_history_$today', newTodaySessions);
    }

    state = state.copyWith(
      mode: nextMode,
      status: TimerStatus.idle,
      secondsRemaining: nextSeconds,
      pomodorosCompleted: newCount,
      todaySessions: newTodaySessions,
    );
  }

  void _schedulePushNotification() {
    final title = state.mode == TimerMode.focus
        ? 'Focus session complete!'
        : 'Break time is over!';
    final body = state.mode == TimerMode.focus
        ? 'Time for a well-deserved break.'
        : 'Ready to focus? Start your next session.';
    NotificationService.instance.scheduleTimerEnd(
      secondsFromNow: state.secondsRemaining,
      title: title,
      body: body,
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final focus = prefs.getInt('pomo_focus') ?? 25;
    final short = prefs.getInt('pomo_short') ?? 5;
    final long = prefs.getInt('pomo_long') ?? 15;
    final untilLong = prefs.getInt('pomo_until_long') ?? 4;

    final today = _todayKey();
    final storedDate = prefs.getString('pomo_today_date') ?? '';
    final todaySessions = storedDate == today
        ? (prefs.getInt('pomo_today_sessions') ?? 0)
        : 0;
    if (storedDate != today) {
      await prefs.setString('pomo_today_date', today);
      await prefs.setInt('pomo_today_sessions', 0);
    }

    // Sync today's sessions into per-day history (handles existing data migration)
    if (todaySessions > 0) {
      final histKey = 'pomo_history_$today';
      if ((prefs.getInt(histKey) ?? 0) < todaySessions) {
        await prefs.setInt(histKey, todaySessions);
      }
    }

    state = state.copyWith(
      focusMinutes: focus,
      shortBreakMinutes: short,
      longBreakMinutes: long,
      pomodorosUntilLong: untilLong,
      secondsRemaining: focus * 60,
      todaySessions: todaySessions,
    );
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final pomodoroProvider =
    StateNotifierProvider<PomodoroNotifier, PomodoroState>(
  (_) => PomodoroNotifier(),
);
