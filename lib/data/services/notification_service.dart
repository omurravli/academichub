import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:studiq/core/navigation/navigator_key.dart';
import 'package:studiq/features/planner/domain/entities/planner_item.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _timerNotifId = 999998;

  static const _timerChannel = AndroidNotificationDetails(
    'timer',
    'Study Timer',
    channelDescription: 'Study timer completion alerts',
    importance: Importance.max,
    priority: Priority.max,
    icon: '@mipmap/ic_launcher',
    playSound: true,
    enableVibration: true,
  );

  static const _timerDetails = NotificationDetails(
    android: _timerChannel,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
    ),
  );

  static const _androidChannel = AndroidNotificationDetails(
    'reminders',
    'Reminders',
    channelDescription: 'Planner item reminders',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const _notifDetails = NotificationDetails(
    android: _androidChannel,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  // ── Item scheduling ───────────────────────────────────────────────────────

  Future<void> scheduleItemReminder(PlannerItem item) async {
    await cancelItemReminder(item.id);

    final reminder = item.reminder;
    if (reminder == null || !reminder.enabled) return;

    final targetDate = item.startDateTime ?? item.dueDate;
    if (targetDate == null) return;

    final scheduledDate =
        targetDate.subtract(Duration(minutes: reminder.minutesBefore));
    if (scheduledDate.isBefore(DateTime.now())) return;

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      await _plugin.zonedSchedule(
        _notifId(item.id),
        _typeLabel(item.type),
        item.title,
        tzDate,
        _notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: item.id,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        await _plugin.zonedSchedule(
          _notifId(item.id),
          _typeLabel(item.type),
          item.title,
          tzDate,
          _notifDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: item.id,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelItemReminder(String itemId) =>
      _plugin.cancel(_notifId(itemId));

  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Timer notifications ───────────────────────────────────────────────────

  Future<void> scheduleTimerEnd({
    required int secondsFromNow,
    required String title,
    required String body,
  }) async {
    await cancelTimerNotification();
    if (secondsFromNow <= 0) return;
    final fireAt = DateTime.now().add(Duration(seconds: secondsFromNow));
    final tzDate = tz.TZDateTime.from(fireAt, tz.local);
    try {
      await _plugin.zonedSchedule(
        _timerNotifId,
        title,
        body,
        tzDate,
        _timerDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        await _plugin.zonedSchedule(
          _timerNotifId,
          title,
          body,
          tzDate,
          _timerDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelTimerNotification() => _plugin.cancel(_timerNotifId);

  Future<void> showTimerComplete(String title, String body) =>
      _plugin.show(_timerNotifId, title, body, _timerDetails);

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Stable int ID from UUID (first 7 hex chars → fits in signed int32).
  int _notifId(String id) {
    final hex = id.replaceAll('-', '').substring(0, 7);
    return int.parse(hex, radix: 16);
  }

  String _typeLabel(PlannerItemType type) {
    switch (type) {
      case PlannerItemType.exam:
        return 'Exam Reminder';
      case PlannerItemType.meeting:
        return 'Meeting Reminder';
      case PlannerItemType.deadline:
        return 'Deadline Reminder';
      case PlannerItemType.event:
        return 'Event Reminder';
      default:
        return 'Reminder';
    }
  }

  void _onTap(NotificationResponse response) {
    final itemId = response.payload;
    if (itemId == null || itemId.isEmpty) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) {
      GoRouter.of(ctx).push('/planner/$itemId');
    }
  }
}
