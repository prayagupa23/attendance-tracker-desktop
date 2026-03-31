// faculty_dashboard.dart
import 'package:flutter/material.dart';
import 'package:final_year_project_desktop/widgets/sidebar.dart';
import 'package:final_year_project_desktop/screens/home_screen.dart';
import 'package:final_year_project_desktop/screens/courses_screen.dart';
import 'package:final_year_project_desktop/screens/batches_screen.dart';

class FacultyDashboard extends StatefulWidget {
  final String facultyName;
  final String facultyId;
  final String email;
  final String department;
  final String designation;

  const FacultyDashboard({
    super.key,
    required this.facultyName,
    required this.facultyId,
    required this.email,
    required this.department,
    required this.designation,
  });

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BatchesScreen(),
    const CoursesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
          Expanded(flex: 4, child: _screens[_selectedIndex]),
          Expanded(
            flex: 1,
            child: SideBar(
              facultyName: widget.facultyName,
              facultyId: widget.facultyId,
              email: widget.email,
              department: widget.department,
              designation: widget.designation,
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
