import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark }

/// Local app preferences (device-side). Profile fields still come from auth.
class AppSettings {
  AppSettings._();

  static const String _themeKey = 'settings.theme';
  static const String _notificationsKey = 'settings.notifications';
  static const String _individualCostKey = 'settings.individual_lesson_cost';
  static const String _groupCostKey = 'settings.group_lesson_cost';

  static Future<AppThemePreference> themePreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_themeKey)) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
        return AppThemePreference.dark;
      default:
        return AppThemePreference.system;
    }
  }

  static Future<void> setThemePreference(AppThemePreference value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = switch (value) {
      AppThemePreference.light => 'light',
      AppThemePreference.dark => 'dark',
      AppThemePreference.system => 'system',
    };
    await prefs.setString(_themeKey, raw);
  }

  static Future<bool> notificationsEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  static Future<String?> individualLessonCost() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _asWholeNumberText(prefs.getString(_individualCostKey));
  }

  static Future<void> setIndividualLessonCost(String? value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? normalized = _asWholeNumberText(value?.trim());
    if (normalized == null || normalized.isEmpty) {
      await prefs.remove(_individualCostKey);
    } else {
      await prefs.setString(_individualCostKey, normalized);
    }
  }

  static Future<String?> groupLessonCost() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _asWholeNumberText(prefs.getString(_groupCostKey));
  }

  static Future<void> setGroupLessonCost(String? value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? normalized = _asWholeNumberText(value?.trim());
    if (normalized == null || normalized.isEmpty) {
      await prefs.remove(_groupCostKey);
    } else {
      await prefs.setString(_groupCostKey, normalized);
    }
  }

  /// Whole dollar amounts only — strips decimals like `500.0` → `500`.
  static String? _asWholeNumberText(String? raw) {
    if (raw == null) {
      return null;
    }
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final num? value = num.tryParse(trimmed.replaceAll(',', '.'));
    if (value == null || value < 0) {
      return trimmed;
    }
    return value.round().toString();
  }

  static Brightness resolveBrightness(
    AppThemePreference preference,
    Brightness platformBrightness,
  ) {
    return switch (preference) {
      AppThemePreference.light => Brightness.light,
      AppThemePreference.dark => Brightness.dark,
      AppThemePreference.system => platformBrightness,
    };
  }
}
