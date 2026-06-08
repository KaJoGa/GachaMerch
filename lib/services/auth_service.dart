import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // OAuth Google Cloud — Web application client ID.
  // Web: dipakai sebagai clientId. Android: dipakai sebagai serverClientId
  // supaya idToken yang dihasilkan punya audience = client ID ini, dan bisa
  // diverifikasi backend pakai client ID yang sama.
  static const String googleClientId =
      '609943472345-0ed58l6g0ahhavklldged3t2sh4d8feg.apps.googleusercontent.com';

  // Gunakan localhost untuk Web, 10.0.2.2 untuk Emulator Android
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000";
    } else {
      return "http://10.0.2.2:3000";
    }
  }

  /// Login pakai DB.
  /// Mengembalikan record:
  /// - `ok`    : true jika berhasil login.
  /// - `error` : pesan untuk ditampilkan ke user (null jika sukses). Diambil
  ///             dari body backend kalau ada — supaya 503 (XAMPP/DB mati) tampil
  ///             beda dengan 401 (email/password salah), bukan disamaratakan.
  static Future<({bool ok, String? error})> login(
    String email,
    String password,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data["token"];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        // Simpan role untuk gating fitur (admin vs user).
        await prefs.setString("role", (data["role"] ?? "user").toString());
        await prefs.setString("email", email);

        return (ok: true, error: null);
      }

      // Pakai pesan dari backend bila ada (mis. 503 dbGuard = "XAMPP MySQL
      // belum jalan", 401 = "email/password salah"). Fallback per status code.
      String message = res.statusCode == 401
          ? "Wrong email or password."
          : "Login failed (${res.statusCode}).";
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
      // http.post throw → backend Node-nya yang mati / tak terjangkau.
      debugPrint("Login error: $e");
      return (
        ok: false,
        error: "Cannot connect to the server. Is the backend running?",
      );
    }
  }

  /// Ambil role user yang tersimpan ('admin' / 'user'). Default 'user'.
  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("role") ?? "user";
  }

  static Future<bool> register(
    String name,
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );

    return res.statusCode == 200;
  }

  /// Login dengan Google.
  /// Mengembalikan record:
  /// - `ok`    : true jika berhasil login.
  /// - `error` : pesan untuk ditampilkan ke user (null jika sukses ATAU user
  ///             membatalkan popup — biar tidak memunculkan notifikasi palsu).
  static Future<({bool ok, String? error})> signInWithGoogle() async {
    try {
      // OAuth Google Cloud langsung (tanpa Firebase).
      // Web  : clientId       = Web OAuth client ID.
      // Android: serverClientId = Web OAuth client ID  -> idToken audience-nya
      //          jadi client ID itu, sehingga backend bisa memverifikasinya.
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? googleClientId : null,
        serverClientId: kIsWeb ? null : googleClientId,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User menutup popup / batal — bukan error.
        return (ok: false, error: null);
      }

      // Ambil accessToken (tersedia reliable di Web & Android, beda dengan
      // idToken yang null di web lewat signIn()). Backend yang verifikasi
      // token ini ke Google + cek audience-nya.
      final GoogleSignInAuthentication auth = await googleUser.authentication;
      final String? accessToken = auth.accessToken;

      if (accessToken == null) {
        return (ok: false, error: "Failed to get Google token. Please try again.");
      }

      // Kirim accessToken — backend verifikasi & ambil email/nama dari Google,
      // sekaligus auto-register bila email belum terdaftar.
      final res = await http.post(
        Uri.parse("$baseUrl/auth/google-login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"accessToken": accessToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data["token"];
        final user = data["user"] ?? {};

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("email", user["email"] ?? googleUser.email);
        await prefs.setString(
          "name",
          user["name"] ?? googleUser.displayName ?? emailToName(googleUser.email),
        );
        // Simpan role untuk gating fitur (admin vs user).
        await prefs.setString("role", (user["role"] ?? "user").toString());

        return (ok: true, error: null);
      }

      // Ambil pesan error dari backend supaya feedback-nya jelas.
      String message = "Google Login failed (${res.statusCode}).";
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
      debugPrint("Google Sign In Error: $e");
      return (ok: false, error: "An error occurred during Google login.");
    }
  }

  static String emailToName(String email) {
    return email.split('@')[0];
  }
}
