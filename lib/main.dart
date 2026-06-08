import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'features/auth/login_page2.dart';
import 'features/auth/register_page2.dart';
import 'features/main/home_page.dart';
import 'theme/app_theme.dart';

void main() {
  // Tanpa Firebase — login Google pakai OAuth Google Cloud langsung
  // (lihat AuthService.signInWithGoogle).
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // standar iPhone X / Figma umum
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/main': (context) => const MainMenuPage(),
          },
        );
      },
    );
  }
}
