import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/faculty_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Final Year Project Desktop',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Color(0xFFA50C22))),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? facultyName;
  String? facultyId;
  String? email;
  String? department;
  String? designation;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (isLoggedIn) {
      setState(() {
        _isLoggedIn = true;
        facultyName = prefs.getString('name');
        facultyId = prefs.getString('faculty_id');
        email = prefs.getString('email');
        department = prefs.getString('department');
        designation = prefs.getString('designation');
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoggedIn) {
      return FacultyDashboard(
        facultyName: facultyName!,
        facultyId: facultyId!,
        email: email!,
        department: department!,
        designation: designation!,
      );
    }

    return const LoginScreen();
  }
}
