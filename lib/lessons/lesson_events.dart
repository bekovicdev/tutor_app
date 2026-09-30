import 'package:flutter/foundation.dart';

/// App-wide signal that fires whenever a lesson is created, updated,
/// rescheduled, or deleted anywhere in the app.
///
/// Bottom-nav tabs (Journal, Calendar, Home, Payment, ...) are built once
/// and kept alive for the lifetime of the app by [CupertinoTabScaffold], so
/// switching tabs does NOT automatically re-fetch their data. Without this,
/// a lesson created/edited on one tab (e.g. from a student's detail page)
/// would not appear on another tab (e.g. Journal or Calendar) until the app
/// restarts. Pages that display lesson data should listen to
/// [LessonEvents.listenable] and refresh themselves when it fires.
class LessonEvents {
  LessonEvents._();

  static final ValueNotifier<int> _version = ValueNotifier<int>(0);

  /// Listen to this to be notified when lesson data may have changed
  /// elsewhere in the app.
  static Listenable get listenable => _version;

  /// Call after any successful lesson create/update/delete/reschedule.
  static void notifyChanged() {
    _version.value++;
  }
}
