import 'package:flutter/material.dart';
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
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Color(0xFFA50C22)),
      ),
      home: const FacultyDashboard(),
      debugShowCheckedModeBanner: false
    );
  }
}