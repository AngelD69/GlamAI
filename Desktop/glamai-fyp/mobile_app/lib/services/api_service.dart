import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment.dart';
import '../models/face_shape_result.dart';
import '../models/service.dart';
import '../models/user.dart';
import '../utils/config.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';

class ApiService {
  static const String _tag = 'ApiService';
  static const String baseUrl = AppConfig.baseUrl;

  // ── Token helpers ────────────────────────────────────────────────────────────

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Response handler ─────────────────────────────────────────────────────────

  static dynamic _handle(http.Response response, String endpoint) {
    AppLogger.debug(_tag, '${response.request?.method} $endpoint → ${response.statusCode}');
    try {
      final body = jsonDecode(response.body);
      switch (response.statusCode) {
        case >= 200 && < 300:
          return body;
        case 401:
          throw AuthException(_extractDetail(body, 'Session expired. Please log in again.'));
        case 403:
          throw ForbiddenException(_extractDetail(body, 'You do not have permission to perform this action.'));
        case 404:
          throw NotFoundException(_extractDetail(body, 'The requested resource was not found.'));
        case 422:
          throw ValidationException(_extractDetail(body, 'Validation error. Please check your input.'));
        default:
          throw ServerException(response.statusCode, _extractDetail(body, 'An unexpected server error occurred.'));
      }
    } on AppException {
      rethrow;
    } on FormatException catch (e, st) {
      AppLogger.error(_tag, 'Failed to parse response from $endpoint', e, st);
      throw const ParseException();
    }
  }

  static String _extractDetail(dynamic body, String fallback) {
    if (body is Map) {
      final detail = body['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) return first['msg'].toString();
      }
    }
    return fallback;
  }

  static Future<T> _safeCall<T>(String endpoint, Future<T> Function() call) async {
    AppLogger.info(_tag, 'Request → $endpoint');
    try {
      return await call();
    } on AppException {
      rethrow;
    } on SocketException catch (e, st) {
      AppLogger.error(_tag, 'Network error on $endpoint', e, st);
      throw const NetworkException();
    } on HttpException catch (e, st) {
      AppLogger.error(_tag, 'HTTP error on $endpoint', e, st);
      throw const NetworkException();
    } on Exception catch (e, st) {
      AppLogger.error(_tag, 'Unexpected error on $endpoint', e, st);
      throw const NetworkException('An unexpected error occurred. Please try again.');
    }
  }

  // ── AUTH ─────────────────────────────────────────────────────────────────────

  static Future<User> register(String name, String email, String password) async {
    return _safeCall('/auth/register', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      AppLogger.info(_tag, 'Register success for $email');
      return User.fromJson(_handle(res, '/auth/register') as Map<String, dynamic>);
    });
  }

  /// Returns the logged-in [User]. Token and user_id are persisted automatically.
  static Future<User> login(String email, String password) async {
    return _safeCall('/auth/login', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final body = _handle(res, '/auth/login') as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', body['access_token'] as String);
      final user = User.fromJson(body['user'] as Map<String, dynamic>);
      await prefs.setInt('user_id', user.id);
      AppLogger.info(_tag, 'Login success for $email');
      return user;
    });
  }

  // ── SERVICES ─────────────────────────────────────────────────────────────────

  static Future<List<Service>> getServices() async {
    return _safeCall('/services/', () async {
      final res = await http.get(Uri.parse('$baseUrl/services/'));
      final list = _handle(res, '/services/') as List<dynamic>;
      return list.map((e) => Service.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  // ── APPOINTMENTS ──────────────────────────────────────────────────────────────

  static Future<Appointment> createAppointment({
    required int serviceId,
    required String date,
    required String time,
    String? notes,
  }) async {
    return _safeCall('/appointments/', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/appointments/'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'service_id': serviceId,
          'appointment_date': date,
          'appointment_time': time,
          'notes': notes ?? '',
        }),
      );
      final body = _handle(res, '/appointments/') as Map<String, dynamic>;
      final appt = Appointment.fromJson(body);
      AppLogger.info(_tag, 'Appointment created: id=${appt.id}');
      return appt;
    });
  }

  static Future<List<Appointment>> getMyAppointments() async {
    return _safeCall('/appointments/mine', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/appointments/mine'),
        headers: await _authHeaders(),
      );
      final list = _handle(res, '/appointments/mine') as List<dynamic>;
      return list.map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  static Future<void> cancelAppointment(int appointmentId) async {
    return _safeCall('/appointments/$appointmentId', () async {
      final res = await http.delete(
        Uri.parse('$baseUrl/appointments/$appointmentId'),
        headers: await _authHeaders(),
      );
      if (res.statusCode != 204) _handle(res, '/appointments/$appointmentId');
      AppLogger.info(_tag, 'Appointment $appointmentId cancelled');
    });
  }

  // ── USER PROFILE ──────────────────────────────────────────────────────────────

  static Future<User> getMyProfile() async {
    return _safeCall('/users/me', () async {
      final res = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: await _authHeaders(),
      );
      return User.fromJson(_handle(res, '/users/me') as Map<String, dynamic>);
    });
  }

  static Future<User> updateMyProfile(Map<String, dynamic> data) async {
    return _safeCall('/users/me', () async {
      final res = await http.put(
        Uri.parse('$baseUrl/users/me'),
        headers: await _authHeaders(),
        body: jsonEncode(data),
      );
      AppLogger.info(_tag, 'Profile updated');
      return User.fromJson(_handle(res, '/users/me') as Map<String, dynamic>);
    });
  }

  static Future<User> uploadProfilePicture(File imageFile) async {
    return _safeCall('/users/me/upload-picture', () async {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/me/upload-picture'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      AppLogger.info(_tag, 'Profile picture uploaded');
      return User.fromJson(_handle(res, '/users/me/upload-picture') as Map<String, dynamic>);
    });
  }

  // ── FACE SHAPE DETECTION ──────────────────────────────────────────────────────

  static Future<FaceShapeResult> detectFaceShape(File imageFile) async {
    return _safeCall('/face-shape/detect', () async {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/face-shape/detect'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      final result = FaceShapeResult.fromJson(
          _handle(res, '/face-shape/detect') as Map<String, dynamic>);
      AppLogger.info(_tag, 'Face shape: ${result.faceShape} (${result.confidence}%)');
      return result;
    });
  }

  // ── AI RECOMMENDATION ─────────────────────────────────────────────────────────

  static Future<String> getRecommendation({
    String? faceShape,
    String? hairType,
    String? occasion,
    String? concerns,
  }) async {
    return _safeCall('/recommendations/', () async {
      final res = await http.post(
        Uri.parse('$baseUrl/recommendations/'),
        headers: await _authHeaders(),
        body: jsonEncode({
          if (faceShape != null) 'face_shape': faceShape,
          if (hairType != null) 'hair_type': hairType,
          if (occasion != null) 'occasion': occasion,
          if (concerns != null) 'current_concerns': concerns,
        }),
      );
      final body = _handle(res, '/recommendations/') as Map<String, dynamic>;
      AppLogger.info(_tag, 'Recommendation fetched');
      return body['recommendations'] as String;
    });
  }
}
