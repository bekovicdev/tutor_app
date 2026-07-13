import 'dart:convert';
import 'dart:io';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    required this.message,
  });

  final String token;
  final AuthUser user;
  final String message;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.isAdmin,
    this.socialProvider,
    this.socialId,
    this.individualLessonCost,
    this.groupLessonCost,
  });

  final int id;
  final String name;
  final String email;
  final int status;
  final bool? isAdmin;
  final String? socialProvider;
  final String? socialId;
  final String? individualLessonCost;
  final String? groupLessonCost;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      status: (json['status'] as num?)?.toInt() ?? 0,
      isAdmin: json['is_admin'] as bool?,
      socialProvider: json['social_provider'] as String?,
      socialId: json['social_id'] as String?,
      individualLessonCost: json['individual_lesson_cost']?.toString(),
      groupLessonCost: json['group_lesson_cost']?.toString(),
    );
  }

  AuthUser copyWith({
    String? name,
    String? email,
    String? individualLessonCost,
    String? groupLessonCost,
  }) {
    return AuthUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      status: status,
      isAdmin: isAdmin,
      socialProvider: socialProvider,
      socialId: socialId,
      individualLessonCost: individualLessonCost ?? this.individualLessonCost,
      groupLessonCost: groupLessonCost ?? this.groupLessonCost,
    );
  }
}

class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.phone,
    this.individualLessonCost,
    this.groupLessonCost,
    this.fcmToken,
  });

  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String? phone;
  final double? individualLessonCost;
  final double? groupLessonCost;
  final String? fcmToken;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> payload = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };

    if (phone != null && phone!.isNotEmpty) {
      payload['phone'] = phone;
    }
    if (individualLessonCost != null) {
      payload['individual_lesson_cost'] = individualLessonCost;
    }
    if (groupLessonCost != null) {
      payload['group_lesson_cost'] = groupLessonCost;
    }
    if (fcmToken != null && fcmToken!.isNotEmpty) {
      payload['fcm_token'] = fcmToken;
    }

    return payload;
  }
}

class AuthService {
  AuthService({String? baseUrl})
      : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:8000/api',
            );

  final String _baseUrl;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) {
    return _post(
      endpoint: '/login',
      body: <String, dynamic>{
        'email': email,
        'password': password,
      },
    );
  }

  Future<AuthSession> register(RegisterRequest request) {
    return _post(
      endpoint: '/register',
      body: request.toJson(),
    );
  }

  Future<AuthUser> me(String token) async {
    final Map<String, dynamic> json = await _request(
      method: 'GET',
      endpoint: '/me',
      token: token,
    );
    final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const AuthException('User data is missing in response.');
    }
    return AuthUser.fromJson(data);
  }

  Future<AuthUser> updateProfile({
    required String token,
    String? name,
    String? email,
    String? phone,
    num? individualLessonCost,
    num? groupLessonCost,
    bool clearIndividualLessonCost = false,
    bool clearGroupLessonCost = false,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (name != null) {
      body['name'] = name;
    }
    if (email != null) {
      body['email'] = email;
    }
    if (phone != null) {
      body['phone'] = phone;
    }
    if (clearIndividualLessonCost) {
      body['individual_lesson_cost'] = null;
    } else if (individualLessonCost != null) {
      body['individual_lesson_cost'] = individualLessonCost;
    }
    if (clearGroupLessonCost) {
      body['group_lesson_cost'] = null;
    } else if (groupLessonCost != null) {
      body['group_lesson_cost'] = groupLessonCost;
    }
    final Map<String, dynamic> json = await _request(
      method: 'PUT',
      endpoint: '/user',
      token: token,
      body: body,
    );
    final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const AuthException('User data is missing in response.');
    }
    return AuthUser.fromJson(data);
  }

  Future<void> logout(String token) async {
    await _request(
      method: 'POST',
      endpoint: '/logout',
      token: token,
    );
  }

  Future<String> oauthRedirectUrl(String provider) async {
    final Map<String, dynamic> json = await _request(
      method: 'GET',
      endpoint: '/auth/$provider/redirect',
    );
    final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
    final String? url = data?['url'] as String?;
    if (url == null || url.isEmpty) {
      throw const AuthException('OAuth redirect url is missing in response.');
    }
    return url;
  }

  Future<AuthSession> _post({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    final Map<String, dynamic> json = await _request(
      method: 'POST',
      endpoint: endpoint,
      body: body,
    );

    final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
    final String? token = data?['token'] as String?;
    final Map<String, dynamic>? userJson = data?['user'] as Map<String, dynamic>?;

    if (token == null || userJson == null) {
      throw const AuthException('Token or user data is missing in response.');
    }

    return AuthSession(
      token: token,
      user: AuthUser.fromJson(userJson),
      message: (json['message'] as String?) ?? 'Auth successful',
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final HttpClient client = HttpClient();
    try {
      final Uri uri = Uri.parse('$_baseUrl$endpoint');
      late final HttpClientRequest request;
      if (method == 'GET') {
        request = await client.getUrl(uri);
      } else if (method == 'POST') {
        request = await client.postUrl(uri);
      } else if (method == 'PUT') {
        request = await client.putUrl(uri);
      } else {
        throw const AuthException('Unsupported request method.');
      }

      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> json =
          (jsonDecode(responseBody) as Map<String, dynamic>);

      final bool success = json['success'] == true;
      if (!success) {
        throw AuthException(_extractErrorMessage(json));
      }
      return json;
    } on SocketException {
      throw const AuthException('Cannot connect to server.');
    } on FormatException {
      throw const AuthException('Invalid server response format.');
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
    return (json['message'] as String?) ?? 'Authentication failed.';
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
