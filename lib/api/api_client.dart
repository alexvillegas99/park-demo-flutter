import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  static const Duration timeout = Duration(seconds: 10);
}

/// WhatsApp phone number used to open the reservation flow from the packages
/// screen. Kept as a top-level constant so it can be swapped in one place.
// TODO: confirmar número oficial de reservas para producción.
const String kWhatsAppPhone = '593984770952';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException(${statusCode ?? '-'}): $message';
}

/// Single shared HTTP client with JWT persistence via shared_preferences.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String _tokenKey = 'park_demo_jwt';
  final http.Client _http = http.Client();
  String? _token;
  bool _tokenLoaded = false;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<void> _ensureToken() async {
    if (_tokenLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _tokenLoaded = true;
  }

  String? get token => _token;

  Future<void> setToken(String? value) async {
    _token = value;
    _tokenLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, value);
    }
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    await _ensureToken();
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (json) headers['Content-Type'] = 'application/json';
    final t = _token;
    if (t != null && t.isNotEmpty) headers['Authorization'] = 'Bearer $t';
    return headers;
  }

  Future<dynamic> _getJson(String path) async {
    try {
      final headers = await _headers();
      final res = await _http
          .get(_uri(path), headers: headers)
          .timeout(ApiConfig.timeout);
      return _decode(res, path);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error on $path: $e');
    }
  }

  Future<dynamic> _postJson(String path, Object? body) async {
    try {
      final headers = await _headers(json: true);
      final res = await _http
          .post(_uri(path),
              headers: headers, body: body == null ? null : jsonEncode(body))
          .timeout(ApiConfig.timeout);
      return _decode(res, path);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error on $path: $e');
    }
  }

  dynamic _decode(http.Response res, String path) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String detail = res.body;
      try {
        final j = jsonDecode(res.body);
        if (j is Map && j['message'] != null) {
          final msg = j['message'];
          detail = msg is List ? msg.join(', ') : msg.toString();
        }
      } catch (_) {}
      throw ApiException('HTTP ${res.statusCode} for $path: $detail',
          statusCode: res.statusCode);
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  // ───────── AUTH ─────────
  Future<AuthResult> appLogin({
    required String email,
    required String password,
  }) async {
    final data = await _postJson('/auth/app-login', {
      'email': email,
      'password': password,
    });
    if (data is! Map) throw ApiException('app-login: expected object');
    final result = AuthResult.fromJson(Map<String, dynamic>.from(data));
    await setToken(result.accessToken);
    return result;
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'displayName': displayName,
    };
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    final data = await _postJson('/auth/register', body);
    if (data is! Map) throw ApiException('register: expected object');
    final result = AuthResult.fromJson(Map<String, dynamic>.from(data));
    await setToken(result.accessToken);
    return result;
  }

  Future<AuthResult> guest({String? deviceId, String? displayName}) async {
    final data = await _postJson('/auth/guest', {
      if (deviceId != null) 'deviceId': deviceId,
      if (displayName != null) 'displayName': displayName,
    });
    if (data is! Map) throw ApiException('guest: expected object');
    final result = AuthResult.fromJson(Map<String, dynamic>.from(data));
    await setToken(result.accessToken);
    return result;
  }

  Future<void> signOut() => setToken(null);

  // ───────── LIST ENDPOINTS ─────────

  /// GET `/events/today` — returns today's Event, or null on 404 (nothing
  /// scheduled). Any other error propagates.
  Future<Event?> getTodayEvent() async {
    try {
      final data = await _getJson('/events/today');
      if (data == null) return null;
      if (data is! Map) throw ApiException('events/today: expected object');
      return Event.fromJson(Map<String, dynamic>.from(data));
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// GET `/events/upcoming` — events scheduled from today onwards.
  Future<List<Event>> getUpcomingEvents() async {
    final data = await _getJson('/events/upcoming');
    if (data is! List) throw ApiException('events/upcoming: expected array');
    return data
        .whereType<Map>()
        .map((e) => Event.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET `/events` — full events catalogue.
  Future<List<Event>> getEvents() async {
    final data = await _getJson('/events');
    if (data is! List) throw ApiException('events: expected array');
    return data
        .whereType<Map>()
        .map((e) => Event.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Restaurant>> getRestaurants() async {
    final data = await _getJson('/restaurants');
    if (data is! List) throw ApiException('restaurants: expected array');
    return data
        .whereType<Map>()
        .map((e) => Restaurant.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Restaurant> getRestaurant(String id) async {
    final data = await _getJson('/restaurants/$id');
    if (data is! Map) throw ApiException('restaurant $id: expected object');
    return Restaurant.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<Poi>> getPois() async {
    final data = await _getJson('/pois');
    if (data is! List) throw ApiException('pois: expected array');
    return data
        .whereType<Map>()
        .map((e) => Poi.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Poi>> getMapPois() async {
    final data = await _getJson('/map-pois');
    if (data is! List) throw ApiException('map-pois: expected array');
    return data
        .whereType<Map>()
        .map((e) => Poi.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<AppPackage>> getPackages() async {
    final data = await _getJson('/packages');
    if (data is! List) throw ApiException('packages: expected array');
    return data
        .whereType<Map>()
        .map((e) => AppPackage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Attraction>> getAttractions() async {
    final data = await _getJson('/attractions');
    if (data is! List) throw ApiException('attractions: expected array');
    return data
        .whereType<Map>()
        .map((e) => Attraction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<OnboardingQuestion>> getOnboardingQuestions() async {
    final data = await _getJson('/onboarding-questions');
    if (data is! List) throw ApiException('onboarding-questions: expected array');
    return data
        .whereType<Map>()
        .map((e) => OnboardingQuestion.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
