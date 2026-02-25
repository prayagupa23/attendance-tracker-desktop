// sidebar.dart
import 'package:flutter/material.dart';

class SideBar extends StatelessWidget {
  const SideBar({super.key});

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
                const Text(
                  "Manjiri Samant",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  "Faculty",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(icon: Icons.home, title: "Home", onTap: () {}),
                _buildMenuItem(
                  icon: Icons.group,
                  title: "Batches",
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.book,
                  title: "Courses",
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Logout Button
          Container(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout, size: 18),
              label: const Text(
                "Log Out",
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
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
