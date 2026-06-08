import 'package:gachamerch/features/auth/login_page2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool agreeTerms = false;
  bool isLoading = false;

  String? nameError;
  String? emailError;
  String? passwordError;
  String? termsError;
  String? globalError;

  void validateRegister() async {
    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
      termsError = null;
      globalError = null;
    });

    if (fullNameController.text.trim().isEmpty) {
      nameError = "Name is required";
    }

    if (emailController.text.trim().isEmpty) {
      emailError = "Email is required";
    } else if (!emailController.text.contains("@")) {
      emailError = "Invalid email";
    }

    if (passwordController.text.isEmpty) {
      passwordError = "Password is required";
    } else if (passwordController.text.length < 6) {
      passwordError = "Password must be at least 6 characters";
    }

    if (!agreeTerms) {
      termsError = "You must agree to the terms";
    }

    if (nameError == null &&
        emailError == null &&
        passwordError == null &&
        termsError == null) {
      setState(() {
        isLoading = true;
      });

      final success = await AuthService.register(
        fullNameController.text.trim(),
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      if (success) {
        // Beri tahu user register berhasil & harus login ulang.
        _showSnack(
          "Registration successful! Please log in with your account.",
          isError: false,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        setState(() {
          globalError =
              "Registration failed. Email already in use or invalid data.";
        });
      }
    } else {
      setState(() {});
    }
  }

  /// Tampilkan SnackBar feedback (default merah; hijau bila isError=false).
  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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

  Widget buildError(String? error) {
    return SizedBox(
      height: 20.h,
      child: Padding(
        padding: EdgeInsets.only(left: 54.w),
        child: Text(
          error ?? "",
          style: TextStyle(color: Colors.red, fontSize: 12.sp),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30.h),

              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back_sharp, size: 24.sp),
              ),

              SizedBox(height: 10.h),

              Center(
                child: Column(
                  children: [
                    Text(
                      "Create an Account",
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "Let's get you started!",
                      style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30.h),

              /// FULL NAME
              Transform.translate(
                offset: Offset(0, 15.h),
                child: Padding(
                  padding: EdgeInsets.only(left: 54.w),
                  child: Text(
                    "Full Name",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  buildIcon(Icons.person),
                  Expanded(
                    child: TextField(
                      controller: fullNameController,
                      maxLength: 100, // tampilkan counter "current/100" di pojok kanan
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                    ),
                  ),
                ],
              ),

              buildError(nameError),

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

              Row(
                children: [
                  buildIcon(Icons.email),
                  Expanded(
                    child: TextField(
                      controller: emailController,
                      maxLength: 100, // tampilkan counter "current/100" di pojok kanan
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                    ),
                  ),
                ],
              ),

              buildError(emailError),

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

              Row(
                children: [
                  buildIcon(Icons.lock),
                  Expanded(
                    child: TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        border: const UnderlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
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

              buildError(passwordError),

              SizedBox(height: 10.h),

              /// TERMS
              Row(
                children: [
                  Checkbox(
                    value: agreeTerms,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() {
                        agreeTerms = value!;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      "I agree to the terms & conditions",
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                ],
              ),

              SizedBox(
                height: 18.h,
                child: Text(
                  termsError ?? "",
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ),

              SizedBox(height: 10.h),

              if (globalError != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Text(
                    globalError!,
                    style: TextStyle(color: Colors.red, fontSize: 12.sp),
                  ),
                ),

              SizedBox(height: 10.h),

              /// SIGN UP BUTTON
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: isLoading ? null : validateRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const Spacer(),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: Text("Log In", style: TextStyle(fontSize: 14.sp)),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 50.h),
            ],
          ),
        ),
      ),
    );
  }
}
