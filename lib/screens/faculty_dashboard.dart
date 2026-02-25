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
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/somaiyalogo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "K.J Somaiya Polytechnic, Vidyavihar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFFA50C22),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/images/somaiya2.jpg',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
        ],
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
