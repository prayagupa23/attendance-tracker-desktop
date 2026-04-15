// sidebar.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SideBar extends StatelessWidget {
  final String facultyName;
  final String facultyId;
  final String email;
  final String department;
  final String designation;
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback? onRefresh; // Added refresh callback

  const SideBar({
    super.key,
    required this.facultyName,
    required this.facultyId,
    required this.email,
    required this.department,
    required this.designation,
    required this.selectedIndex,
    required this.onItemTapped,
    this.onRefresh, // Optional refresh callback
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF3d4957), // Dark blue for sidebar
      child: Column(
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 30,
                    color: Color(0xFF3d4957),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  facultyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  designation,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  icon: Icons.home,
                  title: "Home",
                  onTap: () => onItemTapped(0),
                  isSelected: selectedIndex == 0,
                ),
                _buildMenuItem(
                  icon: Icons.group,
                  title: "Batches",
                  onTap: () => onItemTapped(1),
                  isSelected: selectedIndex == 1,
                ),
                _buildMenuItem(
                  icon: Icons.book,
                  title: "Courses",
                  onTap: () => onItemTapped(2),
                  isSelected: selectedIndex == 2,
                ),
                _buildMenuItem(
                  icon: Icons.schedule,
                  title: "Timetable",
                  onTap: () => onItemTapped(3),
                  isSelected: selectedIndex == 3,
                ),
                _buildMenuItem(
                  icon: Icons.person,
                  title: "My Timetable",
                  onTap: () => onItemTapped(4),
                  isSelected: selectedIndex == 4,
                ),

                // Refresh Button
                if (onRefresh != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text(
                        "Refresh",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA50C22),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),

          // Logout Button
          Container(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text(
                "Logout",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3d4957),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.1)
                  : Colors.transparent,
              border: isSelected
                  ? const Border(
                      left: BorderSide(color: Colors.white, width: 3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          height: 1,
          color: Colors.white.withOpacity(0.2),
          margin: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ],
    );
  }
}
