import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class AuthStorage {
  static const String _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } on MissingPluginException {
      // Ignore when plugin is not yet available.
    }
  }

  Future<String?> readToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> clearToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } on MissingPluginException {
      // Ignore when plugin is not yet available.
    }
  }
}
