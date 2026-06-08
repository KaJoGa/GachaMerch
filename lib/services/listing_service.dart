import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Service untuk listing (item yang dijual) + katalog item master.
/// Endpoint write & /catalog butuh bearer token milik admin.
class ListingService {
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// Daftar item yang sedang dijual (publik — dipakai home user juga).
  static Future<List<Map<String, dynamic>>> list() async {
    final res = await http.get(Uri.parse("${AuthService.baseUrl}/listings"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data["data"] ?? []);
    }
    throw Exception("Failed to load listings (${res.statusCode})");
  }

  /// Katalog semua item master (weapons + foods) untuk dipilih admin.
  static Future<List<Map<String, dynamic>>> catalog() async {
    final res = await http.get(
      Uri.parse("${AuthService.baseUrl}/catalog"),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data["data"] ?? []);
    }
    throw Exception("Failed to load catalog (${res.statusCode})");
  }

  static Future<({bool ok, String? error})> create(
    Map<String, dynamic> payload,
  ) async {
    return _write(
      () async => http.post(
        Uri.parse("${AuthService.baseUrl}/listings"),
        headers: await _authHeaders(),
        body: jsonEncode(payload),
      ),
    );
  }

  static Future<({bool ok, String? error})> update(
    int id,
    Map<String, dynamic> payload,
  ) async {
    return _write(
      () async => http.put(
        Uri.parse("${AuthService.baseUrl}/listings/$id"),
        headers: await _authHeaders(),
        body: jsonEncode(payload),
      ),
    );
  }

  static Future<({bool ok, String? error})> remove(int id) async {
    return _write(
      () async => http.delete(
        Uri.parse("${AuthService.baseUrl}/listings/$id"),
        headers: await _authHeaders(),
      ),
    );
  }

  /// Helper umum: map status code ke (ok, error) + ambil pesan error backend.
  static Future<({bool ok, String? error})> _write(
    Future<http.Response> Function() send,
  ) async {
    try {
      final res = await send();
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return (ok: true, error: null);
      }

      String message = "Operation failed (${res.statusCode}).";
      if (res.statusCode == 401) {
        message = "Invalid session. Please log in again.";
      } else if (res.statusCode == 403) {
        message = "Access denied: admin only.";
      }
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body["error"] != null) {
          message = body["error"].toString();
        }
      } catch (_) {
        // body bukan JSON — pakai pesan default
      }
      return (ok: false, error: message);
    } catch (e) {
      return (ok: false, error: "Cannot connect to the server.");
    }
  }
}
