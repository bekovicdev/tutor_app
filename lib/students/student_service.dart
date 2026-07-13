import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class Student {
  const Student({
    required this.id,
    required this.name,
    this.phone,
    this.birthday,
    this.lessonCost,
    this.notes,
    this.status,
    this.color,
    this.profilePicture,
    this.profilePictureUrl,
  });

  final int id;
  final String name;
  final String? phone;
  final String? birthday;
  final String? lessonCost;
  final String? notes;
  final int? status;
  final String? color;
  final String? profilePicture;
  final String? profilePictureUrl;

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      phone: json['phone'] as String?,
      birthday: json['birthday'] as String?,
      lessonCost: json['lesson_cost']?.toString(),
      notes: json['notes'] as String?,
      status: (json['status'] as num?)?.toInt(),
      color: json['color'] as String?,
      profilePicture: json['profile_picture'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
    );
  }

  Student copyWith({
    int? id,
    String? name,
    String? phone,
    String? birthday,
    String? lessonCost,
    String? notes,
    int? status,
    String? color,
    String? profilePicture,
    String? profilePictureUrl,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      lessonCost: lessonCost ?? this.lessonCost,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      color: color ?? this.color,
      profilePicture: profilePicture ?? this.profilePicture,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}

class StudentCreateRequest {
  const StudentCreateRequest({
    required this.name,
    this.phone,
    this.birthday,
    this.lessonCost,
    this.notes,
    this.color,
    this.status,
  });

  final String name;
  final String? phone;
  final String? birthday;
  final String? lessonCost;
  final String? notes;
  final String? color;
  final int? status;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = <String, dynamic>{'name': name};
    if (phone != null && phone!.isNotEmpty) {
      payload['phone'] = phone;
    }
    if (birthday != null && birthday!.isNotEmpty) {
      payload['birthday'] = birthday;
    }
    if (lessonCost != null && lessonCost!.isNotEmpty) {
      payload['lesson_cost'] = lessonCost;
    }
    if (notes != null && notes!.isNotEmpty) {
      payload['notes'] = notes;
    }
    if (color != null && color!.isNotEmpty) {
      payload['color'] = color;
    }
    if (status != null) {
      payload['status'] = status;
    }
    return payload;
  }
}

class StudentService {
  StudentService({
    required this.token,
    String? baseUrl,
  }) : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:8000/api',
            );

  final String token;
  final String _baseUrl;

  Future<List<Student>> listStudents({
    String? search,
    int status = 1,
    String sortBy = 'created_at',
    String sortDirection = 'desc',
    int perPage = 100,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/students').replace(
      queryParameters: <String, String>{
        'status': '$status',
        'sort_by': sortBy,
        'sort_direction': sortDirection,
        'per_page': '$perPage',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final Map<String, dynamic> json = await _request(
      method: 'GET',
      uri: uri,
    );
    final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
    final List<dynamic> rows = (data?['data'] as List<dynamic>?) ?? <dynamic>[];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(Student.fromJson)
        .toList();
  }

  Future<void> createStudent(StudentCreateRequest request) async {
    final Uri uri = Uri.parse('$_baseUrl/students');
    await _request(
      method: 'POST',
      uri: uri,
      body: request.toJson(),
    );
  }

  Future<void> updateStudent({
    required int id,
    required StudentCreateRequest request,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/students/$id');
    await _request(
      method: 'PUT',
      uri: uri,
      body: request.toJson(),
    );
  }

  Future<StudentDetail> getStudentDetail(int id) async {
    final Uri uri = Uri.parse('$_baseUrl/students/$id');
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
    final Map<String, dynamic>? studentJson =
        data?['student'] as Map<String, dynamic>?;
    final Map<String, dynamic>? summaryJson =
        data?['summary'] as Map<String, dynamic>?;
    if (studentJson == null) {
      throw const StudentServiceException('Student detail is missing.');
    }
    return StudentDetail(
      student: Student.fromJson(studentJson),
      summary: StudentSummary.fromJson(summaryJson ?? <String, dynamic>{}),
    );
  }

  Future<void> deleteStudent(int id) async {
    final Uri uri = Uri.parse('$_baseUrl/students/$id');
    await _request(method: 'DELETE', uri: uri);
  }

  Future<StudentBalance> getStudentBalance(int id) async {
    final Uri uri = Uri.parse('$_baseUrl/students/$id/balance');
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const StudentServiceException('Student balance is missing.');
    }
    return StudentBalance.fromJson(data);
  }

  /// Upload or replace profile picture (`multipart/form-data`).
  Future<Student> uploadProfilePicture({
    required int id,
    required File file,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/students/$id/profile-picture');
    final HttpClient client = HttpClient();
    try {
      final List<int> bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw const StudentServiceException(
          'Profile picture must be 5MB or smaller.',
        );
      }

      final String filename = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : 'profile.jpg';
      final String contentType = _imageContentType(filename);
      final String boundary =
          '----TutorBoundary${DateTime.now().millisecondsSinceEpoch}';

      final HttpClientRequest request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      final BytesBuilder body = BytesBuilder();
      void writeString(String value) {
        body.add(utf8.encode(value));
      }

      writeString('--$boundary\r\n');
      writeString(
        'Content-Disposition: form-data; name="profile_picture"; '
        'filename="$filename"\r\n',
      );
      writeString('Content-Type: $contentType\r\n\r\n');
      body.add(bytes);
      writeString('\r\n--$boundary--\r\n');

      final Uint8List payload = body.takeBytes();
      request.contentLength = payload.length;
      request.add(payload);

      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> json =
          jsonDecode(responseBody) as Map<String, dynamic>;

      if (json['success'] != true) {
        throw StudentServiceException(_extractErrorMessage(json));
      }

      final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const StudentServiceException(
          'Profile picture upload response is missing.',
        );
      }
      return Student.fromJson(data);
    } on SocketException {
      throw const StudentServiceException('Cannot connect to server.');
    } on FormatException {
      throw const StudentServiceException('Invalid server response format.');
    } on StudentServiceException {
      rethrow;
    } catch (error) {
      throw StudentServiceException(error.toString());
    } finally {
      client.close(force: true);
    }
  }

  Future<Student> deleteProfilePicture(int id) async {
    final Uri uri = Uri.parse('$_baseUrl/students/$id/profile-picture');
    final Map<String, dynamic> json = await _request(
      method: 'DELETE',
      uri: uri,
    );
    final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const StudentServiceException(
        'Profile picture delete response is missing.',
      );
    }
    return Student.fromJson(data);
  }

  String _imageContentType(String filename) {
    final String lower = filename.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'application/octet-stream';
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
        throw const StudentServiceException('Unsupported request method.');
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
        throw StudentServiceException(_extractErrorMessage(json));
      }
      return json;
    } on SocketException {
      throw const StudentServiceException('Cannot connect to server.');
    } on FormatException {
      throw const StudentServiceException('Invalid server response format.');
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
    }
    return (json['message'] as String?) ?? 'Student request failed.';
  }
}

class StudentDetail {
  const StudentDetail({
    required this.student,
    required this.summary,
  });

  final Student student;
  final StudentSummary summary;
}

class StudentSummary {
  const StudentSummary({
    required this.lessonsTotal,
    required this.lessonsCompleted,
    required this.lessonsCancelled,
    this.lastLessonDate,
  });

  final int lessonsTotal;
  final int lessonsCompleted;
  final int lessonsCancelled;
  final String? lastLessonDate;

  factory StudentSummary.fromJson(Map<String, dynamic> json) {
    return StudentSummary(
      lessonsTotal: (json['lessons_total'] as num?)?.toInt() ?? 0,
      lessonsCompleted: (json['lessons_completed'] as num?)?.toInt() ?? 0,
      lessonsCancelled: (json['lessons_cancelled'] as num?)?.toInt() ?? 0,
      lastLessonDate: json['last_lesson_date'] as String?,
    );
  }
}

class StudentBalance {
  const StudentBalance({
    required this.studentId,
    required this.studentName,
    required this.currency,
    required this.totalAmount,
    required this.paidAmount,
    required this.prepaidAmount,
    required this.packageCredit,
    required this.unpaidAmount,
    required this.settledAmount,
    required this.cashCollected,
    required this.cashRefunded,
    required this.cashNet,
  });

  final int studentId;
  final String studentName;
  final String currency;
  final num totalAmount;
  final num paidAmount;

  /// Sum of lesson prices with payment_status=prepaid (already applied).
  final num prepaidAmount;

  /// Remaining package wallet: prepaid cash payments minus applied prepaid lessons.
  final num packageCredit;
  final num unpaidAmount;
  final num settledAmount;
  final num cashCollected;
  final num cashRefunded;
  final num cashNet;

  factory StudentBalance.fromJson(Map<String, dynamic> json) {
    final num prepaidAmount = (json['prepaid_amount'] as num?) ?? 0;
    final num? packageCredit = json['package_credit'] as num?;
    return StudentBalance(
      studentId: (json['student_id'] as num?)?.toInt() ?? 0,
      studentName: (json['student_name'] as String?) ?? '',
      currency: (json['currency'] as String?) ?? '',
      totalAmount: (json['total_amount'] as num?) ?? 0,
      paidAmount: (json['paid_amount'] as num?) ?? 0,
      prepaidAmount: prepaidAmount,
      // Older APIs omit package_credit; fall back to prepaid_amount.
      packageCredit: packageCredit ?? prepaidAmount,
      unpaidAmount: (json['unpaid_amount'] as num?) ?? 0,
      settledAmount: (json['settled_amount'] as num?) ?? 0,
      cashCollected: (json['cash_collected'] as num?) ?? 0,
      cashRefunded: (json['cash_refunded'] as num?) ?? 0,
      cashNet: (json['cash_net'] as num?) ?? 0,
    );
  }
}

class StudentServiceException implements Exception {
  const StudentServiceException(this.message);

  final String message;
}
