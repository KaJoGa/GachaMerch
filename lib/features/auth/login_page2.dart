import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gachamerch/features/auth/register_page2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  String? emailError;
  String? passwordError;

  /// ================= AUTO LOGIN =================
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');

    if (email != null && email.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/main');
      });
    }
  }

  /// ================= SAVE USER =================
  Future<void> saveUserData(String email) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('name', email.split('@')[0]);
    await prefs.setString('email', email);
  }

  /// ================= LOGIN VALIDATION =================
  void validateLogin() async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    if (emailController.text.isEmpty) {
      emailError = "Email is required";
    } else if (!emailController.text.contains("@")) {
      emailError = "Invalid email";
    }

    if (passwordController.text.isEmpty) {
      passwordError = "Password is required";
    } else if (passwordController.text.length < 6) {
      passwordError = "Invalid password";
    }

    if (emailError == null && passwordError == null) {
      setState(() {
        isLoading = true;
      });

      final result = await AuthService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      if (result.ok) {
        await saveUserData(emailController.text.trim());
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        // Pesan asli dari backend (mis. "XAMPP MySQL belum jalan") supaya tidak
        // selalu disalahartikan sebagai password salah.
        _showSnack(result.error ?? "Login failed. Wrong email or password.");
      }
    } else {
      setState(() {});
    }
  }

  /// Tampilkan SnackBar feedback (default merah untuk error).
  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void loginWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    final result = await AuthService.signInWithGoogle();

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });

    if (result.ok) {
      Navigator.pushReplacementNamed(context, '/main');
    } else if (result.error != null) {
      // error == null berarti user membatalkan popup → tidak perlu notifikasi
      _showSnack(result.error!);
    }
  }

  Widget buildIcon(IconData icon) {
    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 22.sp),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 90.h),

                        /// HEADER
                        Center(
                          child: Column(
                            children: [
                              Text(
                                "Welcome back",
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                "Good to See You!",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30.h),

                        /// EMAIL
                        Transform.translate(
                          offset: Offset(0, 15.h),
                          child: Padding(
                            padding: EdgeInsets.only(left: 54.w),
                            child: Text(
                              "Email Address",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 6.h),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                buildIcon(Icons.email),
                                Expanded(
                                  child: TextField(
                                    controller: emailController,
                                    decoration: const InputDecoration(
                                      border: UnderlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20.h,
                              child: Padding(
                                padding: EdgeInsets.only(left: 54.w),
                                child: Text(
                                  emailError ?? "",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        /// PASSWORD
                        Transform.translate(
                          offset: Offset(0, 15.h),
                          child: Padding(
                            padding: EdgeInsets.only(left: 54.w),
                            child: Text(
                              "Password",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 6.h),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                buildIcon(Icons.lock),
                                Expanded(
                                  child: TextField(
                                    controller: passwordController,
                                    obscureText: obscurePassword,
                                    decoration: InputDecoration(
                                      border: const UnderlineInputBorder(),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            obscurePassword = !obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20.h,
                              child: Padding(
                                padding: EdgeInsets.only(left: 54.w),
                                child: Text(
                                  passwordError ?? "",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20.h),

                        /// LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : validateLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    "Log In",
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                          ),
                        ),

                        // Spacer to push everything below it to the bottom
                        const Spacer(),

                        /// DIVIDER "Or" antara login dan tombol Google
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(thickness: 1, color: Colors.grey),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              child: Text(
                                "Or",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(thickness: 1, color: Colors.grey),
                            ),
                          ],
                        ),

                        SizedBox(height: 16.h),

                        /// GOOGLE LOGIN SMALL CIRCLE BUTTON (centered)
                        Center(
                          child: GestureDetector(
                            onTap: isLoading ? null : loginWithGoogle,
                            child: Container(
                              width: 50.w,
                              height: 50.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                color: Colors.white,
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/google-color.svg',
                                  width: 24.w,
                                  height: 24.w,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // small gap between Google button and register text
                        SizedBox(height: 16.h),

                        // Register text (just above bottom, then bottom gap)
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(fontSize: 14.sp),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterPage(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  "Register",
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // bottom gap
                        SizedBox(height: 50.h),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
