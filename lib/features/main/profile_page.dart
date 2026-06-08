import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../theme/app_theme.dart';
import '../admin/manage_listings_page.dart';
import 'wishlist_page.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onNavigateToTransactions;

  const ProfilePage({super.key, this.onNavigateToTransactions});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "";
  String email = "";
  String role = "user";

  bool get isAdmin => role == "admin";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  /// ================= LOAD USER =================
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) Tampilkan dulu data dari prefs (cepat, biar tidak kosong).
    setState(() {
      name = prefs.getString('name') ?? "No Name";
      email = prefs.getString('email') ?? "No Email";
      role = prefs.getString('role') ?? "user";
    });

    // 2) Ambil role terbaru dari backend (authoritative) — supaya perubahan
    //    role di DB langsung kebaca tanpa harus login ulang.
    await _refreshFromServer(prefs);
  }

  /// Ambil profil dari endpoint terproteksi /profile pakai bearer token.
  Future<void> _refreshFromServer(SharedPreferences prefs) async {
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) return;

    try {
      final res = await http.get(
        Uri.parse("${AuthService.baseUrl}/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = data["user"] ?? {};
        final serverRole = (user["role"] ?? "user").toString();
        final serverName = user["name"]?.toString();
        final serverEmail = user["email"]?.toString();

        // Sinkronkan prefs dengan nilai dari server.
        await prefs.setString("role", serverRole);
        if (serverName != null && serverName.isNotEmpty) {
          await prefs.setString("name", serverName);
        }
        if (serverEmail != null && serverEmail.isNotEmpty) {
          await prefs.setString("email", serverEmail);
        }

        if (!mounted) return;
        setState(() {
          role = serverRole;
          if (serverName != null && serverName.isNotEmpty) name = serverName;
          if (serverEmail != null && serverEmail.isNotEmpty) email = serverEmail;
        });
      }
    } catch (_) {
      // Backend mati / offline — biarkan pakai data prefs.
    }
  }

  /// ================= LOGOUT =================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    CartService.clearCart(save: false);

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  /// ================= MENU ITEM =================
  Widget menuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap ?? () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      /// ================= BODY =================
      body: ListView(
        children: [
          /// ===== HEADER (TOKOPEDIA STYLE) =====
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=3',
                  ),
                ),

                const SizedBox(width: 16),

                // Expanded membatasi lebar Column ke sisa ruang Row, supaya
                // nama/email panjang ter-ellipsis dan tidak tembus/overflow.
                Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),

                    /// Badge role: tampil beda untuk admin vs user.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAdmin ? AppColors.primary : Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person_outline,
                            size: 14,
                            color: isAdmin ? Colors.black87 : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAdmin ? "Admin" : "User",
                            style: TextStyle(
                              color: isAdmin ? Colors.black87 : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// ===== MENU AKUN =====
          /// Menu khusus admin — hanya tampil bila role == 'admin'.
          if (isAdmin)
            menuItem(
              Icons.storefront,
              "Manage Sales (Admin)",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageListingsPage(),
                  ),
                );
              },
            ),
          menuItem(
            Icons.favorite,
            "Wishlist",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WishlistPage()),
              );
            },
          ),
          menuItem(Icons.history, "Purchase History", onTap: widget.onNavigateToTransactions),

          const SizedBox(height: 70),

          /// ===== LOGOUT BUTTON =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to log out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          logout();
                        },
                        child: const Text("Logout"),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
