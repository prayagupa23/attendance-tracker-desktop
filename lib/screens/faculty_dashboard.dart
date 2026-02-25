// faculty_dashboard.dart
import 'package:flutter/material.dart';
import 'package:final_year_project_desktop/widgets/main_content.dart';
import 'package:final_year_project_desktop/widgets/sidebar.dart';

class FacultyDashboard extends StatelessWidget {
  const FacultyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "K.J Somaiya Polytechnic, Vidyavihar",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFFA50C22),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(flex: 4, child: const MainContent()),
          Expanded(flex: 1, child: const SideBar()),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
