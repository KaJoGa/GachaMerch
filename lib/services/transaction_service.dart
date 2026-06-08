import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Service untuk pembelian + riwayat transaksi. Keduanya butuh bearer token.
class TransactionService {
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// Beli item dari sebuah listing. Return record (ok, error).
  static Future<({bool ok, String? error})> buy(
    int listingId,
    int quantity,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("${AuthService.baseUrl}/transactions"),
        headers: await _authHeaders(),
        body: jsonEncode({"listing_id": listingId, "quantity": quantity}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return (ok: true, error: null);
      }

      String message = "Purchase failed (${res.statusCode}).";
      if (res.statusCode == 401) {
        message = "Invalid session. Please log in again.";
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

  /// Riwayat transaksi user yang sedang login.
  static Future<List<Map<String, dynamic>>> history() async {
    final res = await http.get(
      Uri.parse("${AuthService.baseUrl}/transactions"),
      headers: await _authHeaders(),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data["data"] ?? []);
    }
    throw Exception("Failed to load transactions (${res.statusCode})");
  }
}
