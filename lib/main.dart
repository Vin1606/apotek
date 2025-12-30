import 'package:apotek/pages/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:apotek/nav/main_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('token');
  final isLoggedIn = token != null && token.isNotEmpty;
  print('Is logged in: $isLoggedIn + Token: $token');
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apotek Digital',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        useMaterial3: true,
      ),
      home: isLoggedIn ? const MainNavPage() : const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
