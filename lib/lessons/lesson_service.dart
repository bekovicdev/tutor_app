import 'dart:convert';
import 'dart:io';

/// Where a lesson belongs in the app UI.
class LessonSource {
  static const String schedule = 'schedule';
  static const String journal = 'journal';
}

class LessonRef {
  const LessonRef({
    required this.id,
    required this.name,
    this.color,
  });

  final int id;
  final String name;
  final String? color;

  factory LessonRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const LessonRef(id: 0, name: '');
    }
    return LessonRef(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      color: json['color'] as String?,
    );
  }
}

class LessonStudentNote {
  const LessonStudentNote({
    required this.id,
    required this.studentId,
    required this.notes,
    this.studentName,
  });

  final int id;
  final int studentId;
  final String notes;
  final String? studentName;

  factory LessonStudentNote.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? student =
        json['student'] as Map<String, dynamic>?;
    return LessonStudentNote(
      id: (json['id'] as num?)?.toInt() ?? 0,
      studentId: (json['student_id'] as num?)?.toInt() ?? 0,
      notes: (json['notes'] as String?) ?? '',
      studentName: student?['name'] as String?,
    );
  }
}

class Lesson {
  const Lesson({
    required this.id,
    required this.date,
    required this.startAt,
    required this.durationMinutes,
    required this.status,
    this.tutorId,
    this.studentId,
    this.groupId,
    this.title,
    this.isFree,
    this.isPaidFor,
    this.paymentStatus,
    this.price,
    this.notes,
    this.source,
    this.student,
    this.group,
    this.studentNotes = const <LessonStudentNote>[],
  });

  final int id;
  final int? tutorId;
  final int? studentId;
  final int? groupId;
  final String? title;
  final String date;
  final String startAt;
  final int durationMinutes;
  final bool? isFree;
  final bool? isPaidFor;
  /// One of: unpaid, paid, prepaid.
  final String? paymentStatus;
  final String? price;
  final String status;
  final String? notes;
  /// One of: schedule, journal. Missing/null is treated as journal.
  final String? source;
  final LessonRef? student;
  final LessonRef? group;
  final List<LessonStudentNote> studentNotes;

  bool get isGroup => groupId != null;
  bool get isIndividual => studentId != null;

  String get resolvedSource {
    final String? raw = source;
    // Legacy rows often have null source. Treat them as schedule so that
    // completing one lesson (which sets source=journal) does not hide the
    // rest of the week when client-side source filtering kicks in.
    if (raw == null || raw.isEmpty || raw == LessonSource.schedule) {
      return LessonSource.schedule;
    }
    return LessonSource.journal;
  }

  bool matchesSource(String expected) => resolvedSource == expected;

  String get resolvedPaymentStatus {
    if (paymentStatus != null && paymentStatus!.isNotEmpty) {
      return paymentStatus!;
    }
    if (isPaidFor == true) {
      return 'paid';
    }
    return 'unpaid';
  }

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) {
      return title!.trim();
    }
    if (isGroup && group != null && group!.name.isNotEmpty) {
      return group!.name;
    }
    if (student != null && student!.name.isNotEmpty) {
      return student!.name;
    }
    return 'Lesson';
  }

  String get displaySubtitle {
    if (isGroup) {
      return group?.name.isNotEmpty == true ? group!.name : 'Group lesson';
    }
    return student?.name.isNotEmpty == true ? student!.name : 'Individual';
  }

  String? get accentColor => group?.color ?? student?.color;

  int get startMinutes {
    final List<String> parts = startAt.split(':');
    if (parts.length < 2) {
      return 0;
    }
    final int hour = int.tryParse(parts[0]) ?? 0;
    final int minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  int get endMinutes => startMinutes + durationMinutes;

  static String _normalizeDateKey(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.length >= 10) {
      return trimmed.substring(0, 10);
    }
    return trimmed;
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final List<dynamic> notesJson =
        (json['student_notes'] as List<dynamic>?) ?? <dynamic>[];
    final bool? isPaidFor = json['is_paid_for'] as bool?;
    final String? paymentStatus = json['payment_status'] as String?;
    return Lesson(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tutorId: (json['tutor_id'] as num?)?.toInt(),
      studentId: (json['student_id'] as num?)?.toInt(),
      groupId: (json['group_id'] as num?)?.toInt(),
      title: json['title'] as String?,
      date: _normalizeDateKey((json['date'] as String?) ?? ''),
      startAt: (json['start_at'] as String?) ?? '00:00',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      isFree: json['is_free'] as bool?,
      isPaidFor: isPaidFor,
      paymentStatus: paymentStatus,
      price: json['price']?.toString(),
      status: (json['status'] as String?) ?? 'scheduled',
      notes: json['notes'] as String?,
      source: json['source'] as String?,
      student: json['student'] == null
          ? null
          : LessonRef.fromJson(json['student'] as Map<String, dynamic>?),
      group: json['group'] == null
          ? null
          : LessonRef.fromJson(json['group'] as Map<String, dynamic>?),
      studentNotes: notesJson
          .whereType<Map<String, dynamic>>()
          .map(LessonStudentNote.fromJson)
          .toList(),
    );
  }
}

class LessonCreateRequest {
  const LessonCreateRequest({
    required this.date,
    required this.startAt,
    required this.durationMinutes,
    this.studentId,
    this.groupId,
    this.title,
    this.isFree,
    this.isPaidFor,
    this.paymentStatus,
    this.price,
    this.status,
    this.notes,
    this.source,
  });

  final int? studentId;
  final int? groupId;
  final String? title;
  final String date;
  final String startAt;
  final int durationMinutes;
  final bool? isFree;
  final bool? isPaidFor;
  final String? paymentStatus;
  final String? price;
  final String? status;
  final String? notes;
  final String? source;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = <String, dynamic>{
      'date': date,
      'start_at': startAt,
      'duration_minutes': durationMinutes,
    };
    if (studentId != null) {
      payload['student_id'] = studentId;
    }
    if (groupId != null) {
      payload['group_id'] = groupId;
    }
    if (title != null && title!.isNotEmpty) {
      payload['title'] = title;
    }
    if (isFree != null) {
      payload['is_free'] = isFree;
    }
    if (paymentStatus != null && paymentStatus!.isNotEmpty) {
      payload['payment_status'] = paymentStatus;
    } else if (isPaidFor != null) {
      payload['is_paid_for'] = isPaidFor;
    }
    if (price != null && price!.isNotEmpty) {
      payload['price'] = price;
    }
    if (status != null && status!.isNotEmpty) {
      payload['status'] = status;
    }
    if (notes != null && notes!.isNotEmpty) {
      payload['notes'] = notes;
    }
    if (source != null && source!.isNotEmpty) {
      payload['source'] = source;
    }
    return payload;
  }
}

class LessonService {
  LessonService({
    required this.token,
    String? baseUrl,
  }) : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:8000/api',
            );

  final String token;
  final String _baseUrl;

  Future<List<Lesson>> listLessons({
    String? status,
    String? startDate,
    String? endDate,
    String? type,
    String? paymentStatus,
    bool? isPaidFor,
    String? search,
    String? source,
    int? studentId,
    String sortBy = 'date',
    String sortDirection = 'asc',
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/lessons').replace(
      queryParameters: <String, String>{
        'sort_by': sortBy,
        'sort_direction': sortDirection,
        if (status != null && status.isNotEmpty) 'status': status,
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
        if (type != null && type.isNotEmpty) 'type': type,
        if (paymentStatus != null && paymentStatus.isNotEmpty)
          'payment_status': paymentStatus,
        if (isPaidFor != null) 'is_paid_for': '$isPaidFor',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (source != null && source.isNotEmpty) 'source': source,
        if (studentId != null) 'student_id': '$studentId',
      },
    );
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    final List<Lesson> lessons = _parseLessons(json['data']);
    final bool hasSourceValues = lessons.any(
      (Lesson lesson) => lesson.source != null && lesson.source!.isNotEmpty,
    );
    if (!hasSourceValues) {
      return lessons;
    }
    return _filterBySource(lessons, source);
  }

  Future<List<Lesson>> calendar({
    required String startDate,
    required String endDate,
    String? source,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/calendar').replace(
      queryParameters: <String, String>{
        'start_date': startDate,
        'end_date': endDate,
        if (source != null && source.isNotEmpty) 'source': source,
      },
    );
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
    final List<Lesson> lessons = _parseLessons(data?['lessons'] ?? data);
    // Only client-filter when the API actually returns source values.
    // Older backends ignore `source` and would otherwise yield an empty list.
    final bool hasSourceValues = lessons.any(
      (Lesson lesson) => lesson.source != null && lesson.source!.isNotEmpty,
    );
    if (!hasSourceValues) {
      return lessons;
    }
    return _filterBySource(lessons, source);
  }

  Future<Lesson> getLesson(int id) async {
    final Uri uri = Uri.parse('$_baseUrl/lessons/$id');
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    final Map<String, dynamic> lessonJson = _unwrapLesson(json['data']);
    return Lesson.fromJson(lessonJson);
  }

  Future<Lesson> createLesson(LessonCreateRequest request) async {
    final Uri uri = Uri.parse('$_baseUrl/lessons');
    final Map<String, dynamic> json = await _request(
      method: 'POST',
      uri: uri,
      body: request.toJson(),
    );
    final Map<String, dynamic> lessonJson = _unwrapLesson(json['data']);
    return Lesson.fromJson(lessonJson);
  }

  Future<Lesson> updateLesson({
    required int id,
    required Map<String, dynamic> body,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/lessons/$id');
    final Map<String, dynamic> json = await _request(
      method: 'PUT',
      uri: uri,
      body: body,
    );
    final Map<String, dynamic> lessonJson = _unwrapLesson(json['data']);
    return Lesson.fromJson(lessonJson);
  }

  Future<void> deleteLesson(int id) async {
    final Uri uri = Uri.parse('$_baseUrl/lessons/$id');
    await _request(method: 'DELETE', uri: uri);
  }

  /// Moves a schedule slot into the journal as a completed lesson.
  Future<Lesson> completeFromSchedule(int id) async {
    return updateLesson(
      id: id,
      body: <String, dynamic>{
        'source': LessonSource.journal,
        'status': 'completed',
      },
    );
  }

  Future<List<LessonStudentNote>> listStudentNotes(int lessonId) async {
    final Uri uri = Uri.parse('$_baseUrl/lessons/$lessonId/student-notes');
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    final dynamic data = json['data'];
    if (data is! List<dynamic>) {
      return <LessonStudentNote>[];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(LessonStudentNote.fromJson)
        .toList();
  }

  Future<LessonStudentNote> createStudentNote({
    required int lessonId,
    required int studentId,
    required String notes,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/lessons/$lessonId/student-notes');
    final Map<String, dynamic> json = await _request(
      method: 'POST',
      uri: uri,
      body: <String, dynamic>{
        'student_id': studentId,
        'notes': notes,
      },
    );
    final dynamic data = json['data'];
    if (data is Map<String, dynamic>) {
      return LessonStudentNote.fromJson(data);
    }
    throw const LessonServiceException('Student note data is missing.');
  }

  Future<LessonStudentNote> updateStudentNote({
    required int lessonId,
    required int studentId,
    required String notes,
  }) async {
    final Uri uri =
        Uri.parse('$_baseUrl/lessons/$lessonId/student-notes/$studentId');
    final Map<String, dynamic> json = await _request(
      method: 'PUT',
      uri: uri,
      body: <String, dynamic>{'notes': notes},
    );
    final dynamic data = json['data'];
    if (data is Map<String, dynamic>) {
      return LessonStudentNote.fromJson(data);
    }
    throw const LessonServiceException('Student note data is missing.');
  }

  Future<void> deleteStudentNote({
    required int lessonId,
    required int studentId,
  }) async {
    final Uri uri =
        Uri.parse('$_baseUrl/lessons/$lessonId/student-notes/$studentId');
    await _request(method: 'DELETE', uri: uri);
  }

  /// Creates or updates a per-student note for a group lesson.
  Future<LessonStudentNote> upsertStudentNote({
    required int lessonId,
    required int studentId,
    required String notes,
    bool alreadyExists = false,
  }) async {
    if (alreadyExists) {
      return updateStudentNote(
        lessonId: lessonId,
        studentId: studentId,
        notes: notes,
      );
    }
    try {
      return await createStudentNote(
        lessonId: lessonId,
        studentId: studentId,
        notes: notes,
      );
    } on LessonServiceException {
      return updateStudentNote(
        lessonId: lessonId,
        studentId: studentId,
        notes: notes,
      );
    }
  }

  List<Lesson> _filterBySource(List<Lesson> lessons, String? source) {
    if (source == null || source.isEmpty) {
      return lessons;
    }
    return lessons
        .where((Lesson lesson) => lesson.matchesSource(source))
        .toList();
  }

  List<Lesson> _parseLessons(dynamic data) {
    final List<dynamic> rows;
    if (data is List<dynamic>) {
      rows = data;
    } else if (data is Map<String, dynamic>) {
      rows = (data['data'] as List<dynamic>?) ??
          (data['lessons'] as List<dynamic>?) ??
          <dynamic>[];
    } else {
      rows = <dynamic>[];
    }
    return rows.whereType<Map<String, dynamic>>().map(Lesson.fromJson).toList();
  }

  Map<String, dynamic> _unwrapLesson(dynamic data) {
    if (data is Map<String, dynamic>) {
      final dynamic nested = data['lesson'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return data;
    }
    throw const LessonServiceException('Lesson data is missing.');
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required Uri uri,
    Map<String, dynamic>? body,
  }) async {
    final HttpClient client = HttpClient();
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
        throw const LessonServiceException('Unsupported request method.');
      }

      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> json =
          jsonDecode(responseBody) as Map<String, dynamic>;

      if (json['success'] != true) {
        throw LessonServiceException(_extractErrorMessage(json));
      }
      return json;
    } on SocketException {
      throw const LessonServiceException('Cannot connect to server.');
    } on FormatException {
      throw const LessonServiceException('Invalid server response format.');
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
    return (json['message'] as String?) ?? 'Lesson request failed.';
  }
}

class LessonServiceException implements Exception {
  const LessonServiceException(this.message);

  final String message;
}
