// batches_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class BatchesScreen extends StatefulWidget {
  const BatchesScreen({super.key});

  @override
  State<BatchesScreen> createState() => _BatchesScreenState();
}

class _BatchesScreenState extends State<BatchesScreen> {
  String? _facultyId;
  List<dynamic> _batches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFacultyId();
  }

  Future<void> _loadFacultyId() async {
    final prefs = await SharedPreferences.getInstance();
    final facultyId = prefs.getString('faculty_id');
    print('Debug: Faculty ID from SharedPreferences: $facultyId'); // Debug line

    setState(() {
      _facultyId = facultyId;
    });

    if (_facultyId != null && _facultyId!.isNotEmpty) {
      _loadBatches();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No faculty ID found. Please login again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadBatches() async {
    if (_facultyId == null || _facultyId!.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print(
        'Debug: Fetching batches for faculty_id: $_facultyId',
      ); // Debug line
      final batches = await ApiService.getBatches(_facultyId!);
      print('Debug: Batches received: $batches'); // Debug line

      // Fetch student count for each batch
      List<Map<String, dynamic>> batchesWithCounts = [];
      for (var batch in batches) {
        try {
          final countData = await ApiService.getStudentCount(batch['code']);
          final batchWithCount = Map<String, dynamic>.from(batch);
          batchWithCount['students'] = countData['student_count'] ?? 0;
          batchesWithCounts.add(batchWithCount);
          print(
            'Debug: Batch ${batch['code']} has ${countData['student_count']} students',
          );
        } catch (e) {
          print('Debug: Failed to get count for batch ${batch['code']}: $e');
          // Add batch with 0 students if count fetch fails
          final batchWithCount = Map<String, dynamic>.from(batch);
          batchWithCount['students'] = 0;
          batchesWithCounts.add(batchWithCount);
        }
      }

      if (mounted) {
        setState(() {
          _batches = batchesWithCounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Debug: Error loading batches: $e'); // Debug line
      if (mounted) {
        setState(() {
          _batches = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load batches: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _batches.length,
                      itemBuilder: (context, index) {
                        final batch = _batches[index];
                        return _buildBatchCard(
                          context,
                          batch['code'],
                          batch['name'],
                          'Students: ${batch['students']}',
                          const Color.fromARGB(255, 16, 37, 176),
                        );
                      },
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
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch Code and Icon
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: batchColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.group, size: 24, color: batchColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batchCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
            const SizedBox(height: 16),

            // Batch Name
            Text(
              batchName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
