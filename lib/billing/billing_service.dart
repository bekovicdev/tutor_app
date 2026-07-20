import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tutor_app/config/api_config.dart';

class BillingStatus {
  const BillingStatus({
    required this.isPremium,
    this.premiumStartAt,
    this.premiumEndAt,
    required this.studentsUsed,
    this.studentsLimit,
    required this.scheduleLessonsUsed,
    this.scheduleLessonsLimit,
    required this.journalLessonsUsed,
    this.journalLessonsLimit,
  });

  final bool isPremium;
  final DateTime? premiumStartAt;
  final DateTime? premiumEndAt;
  final int studentsUsed;
  final int? studentsLimit;
  final int scheduleLessonsUsed;
  final int? scheduleLessonsLimit;
  final int journalLessonsUsed;
  final int? journalLessonsLimit;

  factory BillingStatus.fromJson(Map<String, dynamic> json) {
    return BillingStatus(
      isPremium: json['is_premium'] == true,
      premiumStartAt: _parseDate(json['premium_start_at']),
      premiumEndAt: _parseDate(json['premium_end_at']),
      studentsUsed: (json['students_used'] as num?)?.toInt() ?? 0,
      studentsLimit: (json['students_limit'] as num?)?.toInt(),
      scheduleLessonsUsed:
          (json['schedule_lessons_used'] as num?)?.toInt() ?? 0,
      scheduleLessonsLimit: (json['schedule_lessons_limit'] as num?)?.toInt(),
      journalLessonsUsed: (json['journal_lessons_used'] as num?)?.toInt() ?? 0,
      journalLessonsLimit: (json['journal_lessons_limit'] as num?)?.toInt(),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}

class BillingService {
  BillingService({String? baseUrl}) : _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String _baseUrl;

  static const String entitlementId = 'premium';
  static const String weeklyProductId = 'tutor_premium_weekly';
  static const String monthlyProductId = 'tutor_premium_monthly';
  static const String yearlyProductId = 'tutor_premium_yearly';

  static const String _iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
    defaultValue: '',
  );
  static const String _androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
    defaultValue: '',
  );

  static bool _configured = false;

  static Future<void> configure({required String appUserId}) async {
    if (_configured) {
      try {
        await Purchases.logIn(appUserId);
      } catch (error) {
        debugPrint('RevenueCat logIn failed: $error');
      }
      return;
    }

    final String apiKey = Platform.isIOS
        ? _iosApiKey
        : (Platform.isAndroid ? _androidApiKey : '');
    if (apiKey.isEmpty) {
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
      await Purchases.configure(
        PurchasesConfiguration(apiKey)..appUserID = appUserId,
      );
      _configured = true;
    } on PlatformException catch (error) {
      debugPrint('RevenueCat configure failed: $error');
    }
  }

  Future<BillingStatus> fetchStatus(String token) async {
    final Map<String, dynamic> json = await _request(
      method: 'GET',
      endpoint: '/billing/status',
      token: token,
    );
    final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const BillingException('Billing status is missing.');
    }
    return BillingStatus.fromJson(data);
  }

  Future<BillingStatus> syncFromStore(String token) async {
    if (!_configured) {
      return fetchStatus(token);
    }

    final CustomerInfo info = await Purchases.getCustomerInfo();
    final EntitlementInfo? premium = info.entitlements.all[entitlementId];
    final bool isPremium = premium?.isActive == true;

    DateTime? start;
    DateTime? end;
    if (premium != null) {
      start = DateTime.tryParse(premium.latestPurchaseDate);
      end = DateTime.tryParse(premium.expirationDate ?? '');
    }

    final Map<String, dynamic> json = await _request(
      method: 'POST',
      endpoint: '/billing/sync',
      token: token,
      body: <String, dynamic>{
        'is_premium': isPremium,
        'premium_start_at': start?.toUtc().toIso8601String(),
        'premium_end_at': end?.toUtc().toIso8601String(),
      },
    );
    final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const BillingException('Billing sync response is missing.');
    }
    return BillingStatus.fromJson(data);
  }

  Future<Offerings?> loadOfferings() async {
    if (!_configured) {
      return null;
    }
    try {
      return await Purchases.getOfferings();
    } catch (error) {
      debugPrint('RevenueCat offerings failed: $error');
      return null;
    }
  }

  Future<BillingStatus> purchasePackage({
    required String token,
    required Package package,
  }) async {
    await Purchases.purchase(PurchaseParams.package(package));
    return syncFromStore(token);
  }

  Future<BillingStatus> restore(String token) async {
    if (_configured) {
      await Purchases.restorePurchases();
    }
    return syncFromStore(token);
  }

  Package? packageForProduct(Offerings? offerings, String productId) {
    final Offering? current = offerings?.current;
    if (current == null) {
      return null;
    }
    for (final Package package in current.availablePackages) {
      if (package.storeProduct.identifier == productId) {
        return package;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String endpoint,
    required String token,
    Map<String, dynamic>? body,
  }) async {
    final HttpClient client = HttpClient();
    try {
      final Uri uri = Uri.parse('$_baseUrl$endpoint');
      late final HttpClientRequest request;
      if (method == 'GET') {
        request = await client.getUrl(uri);
      } else if (method == 'POST') {
        request = await client.postUrl(uri);
      } else {
        throw const BillingException('Unsupported request method.');
      }
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> json =
          jsonDecode(responseBody) as Map<String, dynamic>;
      if (json['success'] != true) {
        throw BillingException(
          (json['message'] as String?) ?? 'Billing request failed.',
        );
      }
      return json;
    } on SocketException {
      throw const BillingException('Cannot connect to server.');
    } on FormatException {
      throw const BillingException('Invalid server response format.');
    } finally {
      client.close(force: true);
    }
  }
}

class BillingException implements Exception {
  const BillingException(this.message);

  final String message;

  @override
  String toString() => message;
}
