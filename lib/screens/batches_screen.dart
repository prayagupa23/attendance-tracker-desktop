// batches_screen.dart
import 'package:flutter/material.dart';

class BatchesScreen extends StatelessWidget {
  const BatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.group, size: 24, color: Colors.grey[600]),
                const SizedBox(width: 8),
                const Text(
                  "My Batches",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 24),

            // Batches List
            Expanded(
              child: ListView(
                children: [
                  _buildBatchCard(
                    context,
                    'FYCO',
                    'First Year Computer Engineering',
                    'Students: 63',
                    const Color.fromARGB(255, 16, 37, 176),
                  ),
                  const SizedBox(height: 16),
                  _buildBatchCard(
                    context,
                    'SYCO',
                    'Second Year Computer Engineering',
                    'Students: 58',
                    const Color.fromARGB(255, 16, 37, 176),
                  ),
                  const SizedBox(height: 16),
                  _buildBatchCard(
                    context,
                    'TYCO',
                    'Third Year Computer Engineering',
                    'Students: 55',
                    const Color.fromARGB(255, 16, 37, 176),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchCard(
    BuildContext context,
    String batchCode,
    String batchName,
    String studentCount,
    Color batchColor,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch Header
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: batchColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      batchCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batchName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        studentCount,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Batch Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Managing $batchCode students...'),
                          backgroundColor: batchColor.withOpacity(0.8),
                        ),
                      );
                    },
                    icon: const Icon(Icons.people, size: 18),
                    label: const Text('View Students'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: batchColor.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening attendance records...'),
                          backgroundColor: Color(0xFF0D47A1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
