import 'dart:convert';
import 'dart:io';

import 'package:tutor_app/students/student_service.dart';

class TutorGroup {
  const TutorGroup({
    required this.id,
    required this.name,
    this.status,
    this.color,
  });

  final int id;
  final String name;
  final int? status;
  final String? color;

  factory TutorGroup.fromJson(Map<String, dynamic> json) {
    return TutorGroup(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      status: (json['status'] as num?)?.toInt(),
      color: json['color'] as String?,
    );
  }
}

class GroupCreateRequest {
  const GroupCreateRequest({
    required this.name,
    this.color,
    this.status,
  });

  final String name;
  final String? color;
  final int? status;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = <String, dynamic>{'name': name};
    if (color != null && color!.isNotEmpty) {
      payload['color'] = color;
    }
    if (status != null) {
      payload['status'] = status;
    }
    return payload;
  }
}

class GroupStudent {
  const GroupStudent({
    required this.student,
    this.pivotStatus,
  });

  final Student student;
  final int? pivotStatus;

  factory GroupStudent.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? pivot =
        json['pivot'] as Map<String, dynamic>?;
    return GroupStudent(
      student: Student.fromJson(json),
      pivotStatus: (pivot?['status'] as num?)?.toInt(),
    );
  }
}

class GroupService {
  GroupService({
    required this.token,
    String? baseUrl,
  }) : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:8000/api',
            );

  final String token;
  final String _baseUrl;

  Future<List<TutorGroup>> listGroups({
    String? search,
    int status = 1,
    int? memberStatus,
    String sortBy = 'created_at',
    String sortDirection = 'desc',
    int perPage = 100,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/groups').replace(
      queryParameters: <String, String>{
        'status': '$status',
        'sort_by': sortBy,
        'sort_direction': sortDirection,
        'per_page': '$perPage',
        if (memberStatus != null) 'member_status': '$memberStatus',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    return _parseGroups(json['data']);
  }

  Future<TutorGroup> getGroup(int id) async {
    final Uri uri = Uri.parse('$_baseUrl/groups/$id');
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    final Map<String, dynamic> groupJson = _unwrapGroup(json['data']);
    return TutorGroup.fromJson(groupJson);
  }

  Future<void> createGroup(GroupCreateRequest request) async {
    final Uri uri = Uri.parse('$_baseUrl/groups');
    await _request(
      method: 'POST',
      uri: uri,
      body: request.toJson(),
    );
  }

  Future<void> updateGroup({
    required int id,
    required GroupCreateRequest request,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/groups/$id');
    await _request(
      method: 'PUT',
      uri: uri,
      body: request.toJson(),
    );
  }

  Future<void> deleteGroup(int id) async {
    final Uri uri = Uri.parse('$_baseUrl/groups/$id');
    await _request(method: 'DELETE', uri: uri);
  }

  Future<List<GroupStudent>> listGroupStudents(int groupId) async {
    final Uri uri = Uri.parse('$_baseUrl/groups/$groupId/students');
    final Map<String, dynamic> json = await _request(method: 'GET', uri: uri);
    return _parseGroupStudents(json['data']);
  }

  Future<void> addStudentToGroup({
    required int groupId,
    required int studentId,
    int status = 1,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/groups/$groupId/students');
    await _request(
      method: 'POST',
      uri: uri,
      body: <String, dynamic>{
        'student_id': studentId,
        'status': status,
      },
    );
  }

  Future<void> updateStudentStatusInGroup({
    required int groupId,
    required int studentId,
    required int status,
  }) async {
    final Uri uri =
        Uri.parse('$_baseUrl/groups/$groupId/students/$studentId');
    await _request(
      method: 'PUT',
      uri: uri,
      body: <String, dynamic>{'status': status},
    );
  }

  Future<void> removeStudentFromGroup({
    required int groupId,
    required int studentId,
  }) async {
    final Uri uri =
        Uri.parse('$_baseUrl/groups/$groupId/students/$studentId');
    await _request(method: 'DELETE', uri: uri);
  }

  List<TutorGroup> _parseGroups(dynamic data) {
    return _asMapList(data).map(TutorGroup.fromJson).toList();
  }

  List<GroupStudent> _parseGroupStudents(dynamic data) {
    return _asMapList(data).map(GroupStudent.fromJson).toList();
  }

  List<Map<String, dynamic>> _asMapList(dynamic data) {
    final List<dynamic> rows;
    if (data is List<dynamic>) {
      rows = data;
    } else if (data is Map<String, dynamic>) {
      rows = (data['data'] as List<dynamic>?) ?? <dynamic>[];
    } else {
      rows = <dynamic>[];
    }
    return rows.whereType<Map<String, dynamic>>().toList();
  }

  Map<String, dynamic> _unwrapGroup(dynamic data) {
    if (data is Map<String, dynamic>) {
      final dynamic nested = data['group'] ?? data['data'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return data;
    }
    throw const GroupServiceException('Group data is missing.');
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
        throw const GroupServiceException('Unsupported request method.');
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
        throw GroupServiceException(_extractErrorMessage(json));
      }
      return json;
    } on SocketException {
      throw const GroupServiceException('Cannot connect to server.');
    } on FormatException {
      throw const GroupServiceException('Invalid server response format.');
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
    return (json['message'] as String?) ?? 'Group request failed.';
  }
}

class GroupServiceException implements Exception {
  const GroupServiceException(this.message);

  final String message;
}
