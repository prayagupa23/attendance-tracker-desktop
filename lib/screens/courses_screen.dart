// courses_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/course.dart';
import 'marks_assignment_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String? _facultyId;
  List<Course> _courses = [];
  bool _isLoading = false;
  String? _error;
  bool _showMarksScreen = false;
  Course? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _loadFacultyId();
  }

  Future<void> _loadFacultyId() async {
    final prefs = await SharedPreferences.getInstance();
    final facultyId = prefs.getString('faculty_id');
    print('Debug: Faculty ID from SharedPreferences: $facultyId');

    setState(() {
      _facultyId = facultyId;
    });

    if (_facultyId != null && _facultyId!.isNotEmpty) {
      _loadCourses();
    } else {
      setState(() {
        _error = 'No faculty ID found. Please login again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCourses() async {
    if (_facultyId == null || _facultyId!.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Debug: Fetching courses for faculty_id: $_facultyId');
      final coursesData = await ApiService.getAssignedCourses(_facultyId!);
      print('Debug: Courses data received: $coursesData');

      final courses = coursesData.map((data) => Course.fromJson(data)).toList();

      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Debug: Error loading courses: $e');
      if (mounted) {
        setState(() {
          _courses = [];
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Map<String, List<Course>> _groupCoursesByBatch() {
    final Map<String, List<Course>> grouped = {};
    for (final course in _courses) {
      if (!grouped.containsKey(course.batch)) {
        grouped[course.batch] = [];
      }
      grouped[course.batch]!.add(course);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_showMarksScreen && _selectedCourse != null) {
      return MarksAssignmentScreen(
        courseCode: _selectedCourse!.batch,
        courseName: _selectedCourse!.courseName,
        labBatch: _selectedCourse!.labBatch,
        onBackPressed: () {
          setState(() {
            _showMarksScreen = false;
            _selectedCourse = null;
          });
        },
      );
    }

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
                Icon(Icons.book, size: 24, color: Colors.grey[600]),
                const SizedBox(width: 8),
                const Text(
                  "My Courses",
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

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFA50C22),
                        ),
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load courses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadCourses,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA50C22),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _courses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No courses assigned',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You don\'t have any courses assigned yet.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildCoursesGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesGrid() {
    final groupedCourses = _groupCoursesByBatch();
    final batchOrder = ['FYCO', 'SYCO', 'TYCO']; // Order batches

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: batchOrder.map((batch) {
          final courses = groupedCourses[batch] ?? [];
          if (courses.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Batch Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$batch - ${_getBatchFullName(batch)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFA50C22),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Courses Grid for this batch
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.5,
                ),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  return _buildCourseCard(courses[index]);
                },
              ),
              const SizedBox(height: 32),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to attendance screen for this course
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening attendance for ${course.courseName}...'),
            backgroundColor: const Color(0xFFA50C22),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Course Name (Title)
              Text(
                course.courseName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Session Type and Batch Info
              Row(
                children: [
                  // Session Type Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: course.sessionType.toUpperCase() == 'LAB'
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      course.displaySessionType,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: course.sessionType.toUpperCase() == 'LAB'
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ),
                  ),

                  // Lab Batch or Full Batch
                  if (course.sessionType.toUpperCase() == 'LAB' &&
                      course.labBatch != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: course.labBatchColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        course.labBatch!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: course.labBatchColor,
                        ),
                      ),
                    ),
                  ] else if (course.sessionType.toUpperCase() == 'LECTURE') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Full Batch',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Batch Code and Assign Marks Button
              Row(
                children: [
                  // Batch Code
                  Expanded(
                    child: Text(
                      course.batch,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Assign Marks Button - Only for LAB sessions
                  if (course.sessionType.toUpperCase() == 'LAB')
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showMarksScreen = true;
                          _selectedCourse = course;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA50C22).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFA50C22).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Assign Marks',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFA50C22),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBatchFullName(String code) {
    switch (code) {
      case 'FYCO':
        return 'First Year Computer Engineering';
      case 'SYCO':
        return 'Second Year Computer Engineering';
      case 'TYCO':
        return 'Third Year Computer Engineering';
      default:
        return code;
    }
  }
}
