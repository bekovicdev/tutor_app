import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:tutor_app/l10n/app_localizations.dart';
import 'package:tutor_app/lessons/lesson_service.dart';
import 'package:tutor_app/settings/app_settings.dart';

/// Schedules on-device notifications:
/// * a morning summary of how many lessons fall on that day
/// * a reminder 15 minutes before each lesson
///
/// iOS only keeps 64 pending local notifications, so this covers the next
/// 14 days and is refreshed whenever the app opens or lessons change.
class LessonReminders {
  LessonReminders._();

  static final LessonReminders instance = LessonReminders._();

  static const int _leadMinutes = 15;
  static const int _horizonDays = 14;
  static const int _maxLessonReminders = 48;
  static const int _morningIdBase = 42000;
  static const int _lessonIdBase = 43000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool _tzReady = false;
  Future<void> _tail = Future<void>.value();

  Future<void> sync(String token) {
    return _enqueue(() => _sync(token));
  }

  Future<void> cancelAll() {
    return _enqueue(_cancelOurs);
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final Future<void> result = _tail.then((_) => action());
    _tail = result.catchError((Object _) {});
    return result;
  }

  Future<void> _sync(String token) async {
    try {
      await _ensureReady();
    } catch (error) {
      debugPrint('Lesson reminders init failed: $error');
      return;
    }

    final bool enabled = await AppSettings.notificationsEnabled();
    if (!enabled) {
      await _cancelOurs();
      return;
    }

    final bool morningOn = await AppSettings.morningReminderEnabled();
    final int morningMinutes = await AppSettings.morningReminderMinutes();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime horizon = today.add(const Duration(days: _horizonDays - 1));

    List<Lesson> lessons = <Lesson>[];
    try {
      final LessonService service = LessonService(token: token);
      final String start = _dateKey(today);
      final String end = _dateKey(horizon);
      final List<List<Lesson>> batches = await Future.wait(<Future<List<Lesson>>>[
        service.calendar(
          startDate: start,
          endDate: end,
          source: LessonSource.journal,
        ),
        service.calendar(
          startDate: start,
          endDate: end,
          source: LessonSource.schedule,
        ),
      ]);
      final Map<int, Lesson> byId = <int, Lesson>{};
      for (final Lesson lesson in batches.expand((List<Lesson> list) => list)) {
        if (lesson.status == 'cancelled') {
          continue;
        }
        byId[lesson.id] = lesson;
      }
      lessons = byId.values.toList();
    } catch (error) {
      debugPrint('Lesson reminder fetch failed: $error');
      return;
    }

    await _cancelOurs();

    final AppLocalizations l10n = _l10n();
    final NotificationDetails details = _details();

    if (morningOn) {
      final int hour = morningMinutes ~/ 60;
      final int minute = morningMinutes % 60;
      for (int day = 0; day < _horizonDays; day++) {
        final DateTime date = today.add(Duration(days: day));
        final tz.TZDateTime when = tz.TZDateTime(
          tz.local,
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
        if (!when.isAfter(tz.TZDateTime.now(tz.local))) {
          continue;
        }
        final int count = lessons.where((Lesson lesson) {
          return _lessonDate(lesson) == date;
        }).length;
        final String body = count == 0
            ? l10n.morningNotificationNone
            : l10n.morningNotificationCount(count);
        await _schedule(
          id: _morningIdBase + day,
          title: l10n.morningNotificationTitle,
          body: body,
          when: when,
          details: details,
          payload: 'morning-summary:${_dateKey(date)}',
        );
      }
    }

    final List<({Lesson lesson, DateTime start})> upcoming =
        <({Lesson lesson, DateTime start})>[];
    for (final Lesson lesson in lessons) {
      final DateTime? start = _lessonStart(lesson);
      if (start == null) {
        continue;
      }
      final DateTime fire = start.subtract(const Duration(minutes: _leadMinutes));
      if (!fire.isAfter(now)) {
        continue;
      }
      upcoming.add((lesson: lesson, start: start));
    }
    upcoming.sort(
      (({Lesson lesson, DateTime start}) a, ({Lesson lesson, DateTime start}) b) =>
          a.start.compareTo(b.start),
    );

    final int limit = upcoming.length < _maxLessonReminders
        ? upcoming.length
        : _maxLessonReminders;
    for (int i = 0; i < limit; i++) {
      final ({Lesson lesson, DateTime start}) item = upcoming[i];
      final tz.TZDateTime when = tz.TZDateTime.from(
        item.start.subtract(const Duration(minutes: _leadMinutes)),
        tz.local,
      );
      await _schedule(
        id: _lessonIdBase + i,
        title: item.lesson.indexLabel,
        body: l10n.lessonReminderBody(_clock(item.start)),
        when: when,
        details: details,
        payload: 'lesson-reminder:${item.lesson.id}',
      );
    }
  }

  Future<void> _ensureReady() async {
    if (!_tzReady) {
      tzdata.initializeTimeZones();
      try {
        final String name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
      _tzReady = true;
    }
    if (_ready) {
      return;
    }
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'tutor_alerts',
        'Tutor alerts',
        description: 'Lesson reminders and morning summaries',
        importance: Importance.high,
      ),
    );
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    _ready = true;
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      } catch (error) {
        debugPrint('Could not schedule notification $id: $error');
      }
    }
  }

  Future<void> _cancelOurs() async {
    for (int day = 0; day < _horizonDays; day++) {
      await _plugin.cancel(id: _morningIdBase + day);
    }
    for (int i = 0; i < _maxLessonReminders; i++) {
      await _plugin.cancel(id: _lessonIdBase + i);
    }
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'tutor_alerts',
        'Tutor alerts',
        channelDescription: 'Lesson reminders and morning summaries',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  AppLocalizations _l10n() {
    final Locale locale = WidgetsBinding.instance.platformDispatcher.locale;
    try {
      return lookupAppLocalizations(locale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  DateTime? _lessonDate(Lesson lesson) {
    final String raw = lesson.date.length >= 10
        ? lesson.date.substring(0, 10)
        : lesson.date;
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return null;
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  DateTime? _lessonStart(Lesson lesson) {
    final DateTime? date = _lessonDate(lesson);
    if (date == null) {
      return null;
    }
    final List<String> parts = lesson.startAt.split(':');
    final int hour = int.tryParse(parts.isEmpty ? '' : parts[0]) ?? 0;
    final int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _dateKey(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _clock(DateTime time) {
    final String h = time.hour.toString().padLeft(2, '0');
    final String m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
