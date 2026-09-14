import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;
import '../../features/shared/domain/health_models.dart';

class AppointmentReminderService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialised = false;
  bool _available = false;

  Future<void> initialize() async {
    if (_initialised) return;
    timezone_data.initializeTimeZones();
    try {
      final zoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (_) {
      // UTC remains a safe fallback when platform time-zone lookup is unavailable.
    }
    try {
      await _notifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_period'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _available = true;
    } on MissingPluginException {
      // Widget tests and unsupported targets do not register the native plugin.
      _available = false;
    }
    _initialised = true;
  }

  Future<bool> schedule(PregnancyAppointment appointment) async {
    await initialize();
    if (!_available) return false;
    final reminderAt = appointment.reminderAt;
    if (reminderAt == null) {
      await cancel(appointment.id);
      return true;
    }
    if (!reminderAt.isAfter(DateTime.now())) return true;
    try {
      if (!await requestNotificationPermission()) return false;

      await _notifications.cancel(_idFor(appointment.id));
      final customBody = appointment.reminderMessage?.trim();
      await _notifications.zonedSchedule(
        _idFor(appointment.id),
        'Health reminder',
        customBody == null || customBody.isEmpty
            ? 'You have a health appointment.'
            : customBody,
        tz.TZDateTime.from(reminderAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_reminders',
            'Appointment reminders',
            channelDescription: 'Private health appointment reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_stat_period',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'appointment:${appointment.id}',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestNotificationPermission() async {
    await initialize();
    if (!_available) return false;
    try {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final androidGranted = await android?.requestNotificationsPermission();
      final iosGranted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return androidGranted != false && iosGranted != false;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancel(String appointmentId) async {
    await initialize();
    if (!_available) return;
    try {
      await _notifications.cancel(_idFor(appointmentId));
    } catch (_) {
      // Local deletion still succeeds if the system reminder is unavailable.
    }
  }

  int _idFor(String value) => value.hashCode & 0x7fffffff;
}
