import 'dart:convert';
import 'dart:io';

num? _asNum(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value;
  }
  if (value is String) {
    return num.tryParse(value.replaceAll(',', '.').trim());
  }
  return null;
}

int? _asInt(dynamic value) => _asNum(value)?.toInt();

String? _asString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  return value.toString();
}

/// Lesson settlement status: unpaid | paid | prepaid
class PaymentStatus {
  static const String unpaid = 'unpaid';
  static const String paid = 'paid';
  static const String prepaid = 'prepaid';
}

/// Cash movement kind: lesson | prepaid | refund
class PaymentKind {
  static const String lesson = 'lesson';
  static const String prepaid = 'prepaid';
  static const String refund = 'refund';
}

/// Payment method: cash | transfer | card | other
class PaymentMethod {
  static const String cash = 'cash';
  static const String transfer = 'transfer';
  static const String card = 'card';
  static const String other = 'other';
}

class PaymentRef {
  const PaymentRef({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory PaymentRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PaymentRef(id: 0, name: '');
    }
    return PaymentRef(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
    );
  }
}

class Payment {
  const Payment({
    required this.id,
    required this.amount,
    required this.kind,
    this.method,
    this.paidAt,
    this.notes,
    this.studentId,
    this.groupId,
    this.lessonId,
    this.student,
    this.group,
  });

  final int id;
  final num amount;
  final String kind;
  final String? method;
  final String? paidAt;
  final String? notes;
  final int? studentId;
  final int? groupId;
  final int? lessonId;
  final PaymentRef? student;
  final PaymentRef? group;

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: _asInt(json['id']) ?? 0,
      amount: _asNum(json['amount']) ?? 0,
      kind: _asString(json['kind']) ?? PaymentKind.lesson,
      method: _asString(json['method']),
      paidAt: _asString(json['paid_at']),
      notes: _asString(json['notes']),
      studentId: _asInt(json['student_id']),
      groupId: _asInt(json['group_id']),
      lessonId: _asInt(json['lesson_id']),
      student: json['student'] == null
          ? null
          : PaymentRef.fromJson(
              json['student'] is Map<String, dynamic>
                  ? json['student'] as Map<String, dynamic>
                  : null,
            ),
      group: json['group'] == null
          ? null
          : PaymentRef.fromJson(
              json['group'] is Map<String, dynamic>
                  ? json['group'] as Map<String, dynamic>
                  : null,
            ),
    );
  }
}

class PaymentCreateRequest {
  const PaymentCreateRequest({
    required this.amount,
    required this.kind,
    this.studentId,
    this.groupId,
    this.lessonId,
    this.method,
    this.paidAt,
    this.notes,
    this.applyToLesson = true,
  });

  final num amount;
  final String kind;
  final int? studentId;
  final int? groupId;
  final int? lessonId;
  final String? method;
  final String? paidAt;
  final String? notes;
  final bool applyToLesson;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = <String, dynamic>{
      'amount': amount,
      'kind': kind,
      'apply_to_lesson': applyToLesson,
    };
    if (studentId != null) {
      payload['student_id'] = studentId;
    }
    if (groupId != null) {
      payload['group_id'] = groupId;
    }
    if (lessonId != null) {
      payload['lesson_id'] = lessonId;
    }
    if (method != null && method!.isNotEmpty) {
      payload['method'] = method;
    }
    if (paidAt != null && paidAt!.isNotEmpty) {
      payload['paid_at'] = paidAt;
    }
    if (notes != null && notes!.isNotEmpty) {
      payload['notes'] = notes;
    }
    return payload;
  }
}

class LessonPaymentRequest {
  const LessonPaymentRequest({
    required this.paymentStatus,
    this.amount,
    this.method,
    this.paidAt,
    this.notes,
    this.recordPayment,
  });

  final String paymentStatus;
  final num? amount;
  final String? method;
  final String? paidAt;
  final String? notes;
  final bool? recordPayment;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = <String, dynamic>{
      'payment_status': paymentStatus,
    };
    if (amount != null) {
      payload['amount'] = amount;
    }
    if (method != null && method!.isNotEmpty) {
      payload['method'] = method;
    }
    if (paidAt != null && paidAt!.isNotEmpty) {
      payload['paid_at'] = paidAt;
    }
    if (notes != null && notes!.isNotEmpty) {
      payload['notes'] = notes;
    }
    if (recordPayment != null) {
      payload['record_payment'] = recordPayment;
    }
    return payload;
  }
}

class StatusAmountBucket {
  const StatusAmountBucket({
    required this.count,
    required this.amount,
  });

  final int count;
  final num amount;

  factory StatusAmountBucket.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const StatusAmountBucket(count: 0, amount: 0);
    }
    return StatusAmountBucket(
      count: _asInt(json['count']) ?? 0,
      amount: _asNum(json['amount']) ?? 0,
    );
  }
}

class PaymentsOverview {
  const PaymentsOverview({
    required this.currency,
    required this.billableCount,
    required this.freeCount,
    required this.unpaid,
    required this.paid,
    required this.prepaid,
    required this.cashCollected,
    required this.cashRefunded,
    required this.cashNet,
    required this.receivablesAmount,
    required this.receivablesLessonCount,
    required this.prepaidAmount,
    required this.prepaidLessonCount,
    required this.paidAmount,
    required this.prepaidEarnedAmount,
    required this.settledAmount,
    required this.collectionRatePercent,
  });

  final String currency;
  final int billableCount;
  final int freeCount;
  final StatusAmountBucket unpaid;
  final StatusAmountBucket paid;
  final StatusAmountBucket prepaid;
  final num cashCollected;
  final num cashRefunded;
  final num cashNet;
  final num receivablesAmount;
  final int receivablesLessonCount;
  final num prepaidAmount;
  final int prepaidLessonCount;
  final num paidAmount;
  final num prepaidEarnedAmount;
  final num settledAmount;
  final num collectionRatePercent;

  factory PaymentsOverview.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> lessons =
        (json['lessons'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> byStatus =
        (lessons['by_payment_status'] as Map<String, dynamic>?) ??
            <String, dynamic>{};
    final Map<String, dynamic> cashflow =
        (json['cashflow'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> receivables =
        (json['receivables'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> prepaid =
        (json['prepaid'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> earned =
        (json['earned'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return PaymentsOverview(
      currency: (json['currency'] as String?) ?? 'USD',
      billableCount: _asInt(lessons['billable_count']) ?? 0,
      freeCount: _asInt(lessons['free_count']) ?? 0,
      unpaid: StatusAmountBucket.fromJson(
        byStatus['unpaid'] as Map<String, dynamic>?,
      ),
      paid: StatusAmountBucket.fromJson(
        byStatus['paid'] as Map<String, dynamic>?,
      ),
      prepaid: StatusAmountBucket.fromJson(
        byStatus['prepaid'] as Map<String, dynamic>?,
      ),
      cashCollected: _asNum(cashflow['collected']) ?? 0,
      cashRefunded: _asNum(cashflow['refunded']) ?? 0,
      cashNet: _asNum(cashflow['net_collected']) ?? 0,
      receivablesAmount: _asNum(receivables['amount']) ?? 0,
      receivablesLessonCount: _asInt(receivables['lesson_count']) ?? 0,
      prepaidAmount: _asNum(prepaid['amount']) ?? 0,
      prepaidLessonCount: _asInt(prepaid['lesson_count']) ?? 0,
      paidAmount: _asNum(earned['paid_amount']) ?? 0,
      prepaidEarnedAmount: _asNum(earned['prepaid_amount']) ?? 0,
      settledAmount: _asNum(earned['settled_amount']) ?? 0,
      collectionRatePercent: _asNum(json['collection_rate_percent']) ?? 0,
    );
  }
}

class MonthlyAnalyticsPoint {
  const MonthlyAnalyticsPoint({
    required this.month,
    this.paidAmount = 0,
    this.prepaidAmount = 0,
    this.unpaidAmount = 0,
    this.settledAmount = 0,
    this.collected = 0,
    this.refunded = 0,
    this.net = 0,
  });

  final String month;
  final num paidAmount;
  final num prepaidAmount;
  final num unpaidAmount;
  final num settledAmount;
  final num collected;
  final num refunded;
  final num net;

  factory MonthlyAnalyticsPoint.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> lessonBased =
        (json['lesson_based'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> cashBased =
        (json['cash_based'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return MonthlyAnalyticsPoint(
      month: (json['month'] as String?) ?? '',
      paidAmount: _asNum(lessonBased['paid']) ??
          _asNum(lessonBased['paid_amount']) ??
          0,
      prepaidAmount: _asNum(lessonBased['prepaid']) ??
          _asNum(lessonBased['prepaid_amount']) ??
          0,
      unpaidAmount: _asNum(lessonBased['unpaid']) ??
          _asNum(lessonBased['unpaid_amount']) ??
          0,
      settledAmount: _asNum(lessonBased['settled']) ??
          _asNum(lessonBased['settled_amount']) ??
          0,
      collected: _asNum(cashBased['collected']) ?? 0,
      refunded: _asNum(cashBased['refunded']) ?? 0,
      net: _asNum(cashBased['net']) ??
          _asNum(cashBased['net_collected']) ??
          0,
    );
  }
}

class ReceivablesBreakdownItem {
  const ReceivablesBreakdownItem({
    required this.name,
    required this.amount,
    required this.lessonCount,
    this.oldestLessonDate,
    this.id,
  });

  final int? id;
  final String name;
  final num amount;
  final int lessonCount;
  final String? oldestLessonDate;

  factory ReceivablesBreakdownItem.fromJson(Map<String, dynamic> json) {
    return ReceivablesBreakdownItem(
      id: _asInt(json['id']) ??
          _asInt(json['student_id']) ??
          _asInt(json['group_id']),
      name: (json['name'] as String?) ??
          (json['student_name'] as String?) ??
          (json['group_name'] as String?) ??
          '',
      amount: _asNum(json['amount']) ?? 0,
      lessonCount: _asInt(json['lesson_count']) ?? 0,
      oldestLessonDate: json['oldest_lesson_date'] as String?,
    );
  }
}

class ReceivableLesson {
  const ReceivableLesson({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    this.studentName,
    this.groupName,
  });

  final int id;
  final String title;
  final String date;
  final num amount;
  final String? studentName;
  final String? groupName;

  factory ReceivableLesson.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? student =
        json['student'] as Map<String, dynamic>?;
    final Map<String, dynamic>? group =
        json['group'] as Map<String, dynamic>?;
    return ReceivableLesson(
      id: _asInt(json['id']) ?? 0,
      title: (json['title'] as String?) ?? 'Lesson',
      date: (json['date'] as String?) ?? '',
      amount: _asNum(json['price']) ?? _asNum(json['amount']) ?? 0,
      studentName: student?['name'] as String?,
      groupName: group?['name'] as String?,
    );
  }
}

class ReceivablesAnalytics {
  const ReceivablesAnalytics({
    required this.totalAmount,
    required this.lessonCount,
    required this.byStudent,
    required this.byGroup,
    required this.lessons,
  });

  final num totalAmount;
  final int lessonCount;
  final List<ReceivablesBreakdownItem> byStudent;
  final List<ReceivablesBreakdownItem> byGroup;
  final List<ReceivableLesson> lessons;

  factory ReceivablesAnalytics.fromJson(Map<String, dynamic> json) {
    return ReceivablesAnalytics(
      totalAmount: _asNum(json['total_amount']) ?? _asNum(json['amount']) ?? 0,
      lessonCount: _asInt(json['lesson_count']) ?? 0,
      byStudent: _parseBreakdown(json['by_student'] ?? json['students']),
      byGroup: _parseBreakdown(json['by_group'] ?? json['groups']),
      lessons: _parseLessons(json['lessons']),
    );
  }

  static List<ReceivablesBreakdownItem> _parseBreakdown(dynamic data) {
    if (data is! List<dynamic>) {
      return <ReceivablesBreakdownItem>[];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(ReceivablesBreakdownItem.fromJson)
        .toList();
  }

  static List<ReceivableLesson> _parseLessons(dynamic data) {
    if (data is! List<dynamic>) {
      return <ReceivableLesson>[];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(ReceivableLesson.fromJson)
        .toList();
  }
}

class PrepaidAnalytics {
  const PrepaidAnalytics({
    required this.scheduledCount,
    required this.completedCount,
    required this.unallocatedCredits,
  });

  final int scheduledCount;
  final int completedCount;
  final List<Payment> unallocatedCredits;

  factory PrepaidAnalytics.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> lessons =
        (json['lessons'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final dynamic credits =
        json['unallocated_credits'] ?? json['unallocated_prepaid'];
    final List<dynamic> creditRows;
    if (credits is List<dynamic>) {
      creditRows = credits;
    } else {
      creditRows = <dynamic>[];
    }
    return PrepaidAnalytics(
      scheduledCount: _asInt(lessons['scheduled']) ??
          _asInt(lessons['scheduled_count']) ??
          0,
      completedCount: _asInt(lessons['completed']) ??
          _asInt(lessons['completed_count']) ??
          0,
      unallocatedCredits: creditRows
          .whereType<Map<String, dynamic>>()
          .map(Payment.fromJson)
          .toList(),
    );
  }
}

class PaymentService {
  PaymentService({
    required this.token,
    String? baseUrl,
  }) : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:8000/api',
            );

  final String token;
  final String _baseUrl;

  Future<List<Payment>> listPayments({
    String? kind,
    String? method,
    int? studentId,
    int? groupId,
    int? lessonId,
    String? from,
    String? to,
    String sortBy = 'paid_at',
    String sortDirection = 'desc',
    int perPage = 20,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/payments').replace(
      queryParameters: <String, String>{
        'sort_by': sortBy,
        'sort_direction': sortDirection,
        'per_page': '$perPage',
        if (kind != null && kind.isNotEmpty) 'kind': kind,
        if (method != null && method.isNotEmpty) 'method': method,
        if (studentId != null) 'student_id': '$studentId',
        if (groupId != null) 'group_id': '$groupId',
        if (lessonId != null) 'lesson_id': '$lessonId',
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
    );
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    return _parsePayments(json['data']);
  }

  Future<Payment> createPayment(PaymentCreateRequest request) async {
    final Uri uri = Uri.parse('$_baseUrl/payments');
    final Map<String, dynamic> json = await _request(
      method: 'POST',
      uri: uri,
      body: request.toJson(),
    );
    return Payment.fromJson(_unwrapPayment(json['data']));
  }

  Future<Payment> getPayment(int id) async {
    final Uri uri = Uri.parse('$_baseUrl/payments/$id');
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    return Payment.fromJson(_unwrapPayment(json['data']));
  }

  Future<void> deletePayment(int id) async {
    final Uri uri = Uri.parse('$_baseUrl/payments/$id');
    await _request(method: 'DELETE', uri: uri);
  }

  Future<void> markLessonPayment({
    required int lessonId,
    required LessonPaymentRequest request,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/lessons/$lessonId/payment');
    await _request(
      method: 'POST',
      uri: uri,
      body: request.toJson(),
    );
  }

  Future<PaymentsOverview> overview({String? from, String? to}) async {
    final Uri uri = Uri.parse('$_baseUrl/payments/analytics/overview').replace(
      queryParameters: <String, String>{
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
    );
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const PaymentServiceException('Overview data is missing.');
    }
    return PaymentsOverview.fromJson(data);
  }

  Future<List<MonthlyAnalyticsPoint>> monthly({int months = 12}) async {
    final Uri uri = Uri.parse('$_baseUrl/payments/analytics/monthly').replace(
      queryParameters: <String, String>{'months': '$months'},
    );
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    final List<dynamic> rows = _extractList(
      json['data'],
      keys: const <String>['months', 'data', 'series', 'items', 'points'],
    );
    return rows
        .whereType<Map<String, dynamic>>()
        .map(MonthlyAnalyticsPoint.fromJson)
        .toList();
  }

  /// Prefer list payloads; if [data] is a map, try [keys] in order for a list.
  /// Skips non-list values (e.g. `months: 6` as an int).
  List<dynamic> _extractList(
    dynamic data, {
    List<String> keys = const <String>['data'],
  }) {
    if (data is List<dynamic>) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      for (final String key in keys) {
        final dynamic value = data[key];
        if (value is List<dynamic>) {
          return value;
        }
      }
      // Some APIs nest the series under a single object-shaped month map.
      final List<dynamic> asValues = data.values
          .whereType<Map<String, dynamic>>()
          .toList();
      if (asValues.isNotEmpty && asValues.length == data.length) {
        return asValues;
      }
    }
    return <dynamic>[];
  }

  Future<ReceivablesAnalytics> receivables() async {
    final Uri uri = Uri.parse('$_baseUrl/payments/analytics/receivables');
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    return ReceivablesAnalytics.fromJson(
      (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  Future<PrepaidAnalytics> prepaidAnalytics() async {
    final Uri uri = Uri.parse('$_baseUrl/payments/analytics/prepaid');
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    return PrepaidAnalytics.fromJson(
      (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  List<Payment> _parsePayments(dynamic data) {
    return _extractList(data)
        .whereType<Map<String, dynamic>>()
        .map(Payment.fromJson)
        .toList();
  }

  Map<String, dynamic> _unwrapPayment(dynamic data) {
    if (data is Map<String, dynamic>) {
      final dynamic nested = data['payment'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return data;
    }
    throw const PaymentServiceException('Payment data is missing.');
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required Uri uri,
    Map<String, dynamic>? body,
  }) async {
    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      late final HttpClientRequest request;
      if (method == 'GET') {
        request = await client.getUrl(uri);
      } else if (method == 'POST') {
        request = await client.postUrl(uri);
      } else if (method == 'PUT') {
        request = await client.putUrl(uri);
      } else if (method == 'DELETE') {
        request = await client.deleteUrl(uri);
      } else {
        throw const PaymentServiceException('Unsupported request method.');
      }

      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const PaymentServiceException('Invalid server response format.');
      }
      final Map<String, dynamic> json = decoded;

      if (json['success'] != true) {
        throw PaymentServiceException(_extractErrorMessage(json));
      }
      return json;
    } on SocketException {
      throw const PaymentServiceException('Cannot connect to server.');
    } on FormatException {
      throw const PaymentServiceException('Invalid server response format.');
    } on TypeError {
      throw const PaymentServiceException('Invalid server response format.');
    } finally {
      client.close(force: true);
    }
  }

  String _extractErrorMessage(Map<String, dynamic> json) {
    final dynamic errors = json['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final dynamic firstValue = errors.values.first;
      if (firstValue is List && firstValue.isNotEmpty) {
        return firstValue.first.toString();
      }
      return firstValue.toString();
    }
    return (json['message'] as String?) ?? 'Payment request failed.';
  }
}

class PaymentServiceException implements Exception {
  const PaymentServiceException(this.message);

  final String message;
}
