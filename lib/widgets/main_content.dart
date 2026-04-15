// main_content.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class MainContent extends StatefulWidget {
  const MainContent({super.key});

  @override
  State<MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<MainContent> {
  String? _facultyId;
  Map<String, dynamic>? _activeSession;
  bool _isLoadingSession = false;
  List<dynamic>? _attendanceData;
  bool _isLoadingAttendance = false;
  Timer? _sessionTimer;
  String? _currentSessionId;
  int _remainingSeconds = 600; // 10 minutes in seconds
  bool _isSessionActive = false; // Track if session is currently active

  @override
  void initState() {
    super.initState();
    _loadFacultyId();
    _loadActiveSession();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFacultyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _facultyId = prefs.getString('faculty_id');
    });
  }

  Future<void> _loadActiveSession() async {
    if (_facultyId == null) return;

    setState(() {
      _isLoadingSession = true;
    });

    try {
      final session = await ApiService.getActiveSession(_facultyId!);
      if (mounted) {
        setState(() {
          _activeSession = session;
          _isLoadingSession = false;
          _isSessionActive = session != null; // Set session active state
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeSession = null;
          _isLoadingSession = false;
          _isSessionActive = false; // No active session
        });
      }
    }
  }

  Future<void> _createSession() async {
    if (_facultyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faculty ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if there's already an active session
    if (_isSessionActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session already active'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final response = await ApiService.createSession(_facultyId!);

      if (mounted) {
        setState(() {
          _currentSessionId = response['session_id'];
          _isLoadingAttendance = true;
          _isSessionActive = true; // Mark session as active
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session Created'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 5),
          ),
        );

        // Start 10-minute timer
        _startSessionTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _startSessionTimer() {
    setState(() {
      _remainingSeconds = 600; // 10 minutes
    });

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _sessionTimer?.cancel();
        _fetchAttendanceData();
      }
    });
  }

  Future<void> _fetchAttendanceData() async {
    if (_currentSessionId == null) return;

    try {
      final attendance = await ApiService.getAttendanceBySessionId(
        _currentSessionId!,
      );
      if (mounted) {
        setState(() {
          _attendanceData = attendance;
          _isLoadingAttendance = false;
          _isSessionActive = false; // Reset session state when timer ends
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _attendanceData = null;
          _isLoadingAttendance = false;
          _isSessionActive = false; // Reset session state on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFFF5F6F8),
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lecture Information Card
            Expanded(flex: 2, child: _buildLectureInformationCard()),
            const SizedBox(width: 24),
            // Attendance Overview Card
            Expanded(flex: 3, child: _buildAttendanceOverviewCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureInformationCard() {
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
            // Title Row
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                const Text(
                  "Lecture Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 20),

            // Lecture Cover Placeholder
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage('assets/images/somaiyalogo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Information Fields
            _buildInfoField("LECTURE", "Image Processing (O23RC22)"),
            const SizedBox(height: 16),
            _buildInfoField("TIME SLOT", "10:30 AM - 11:30 AM"),
            const SizedBox(height: 16),
            _buildInfoField("ROOM NUMBER", "207"),
            const SizedBox(height: 16),
            _buildInfoField("DEPARTMENT", "Computer Engineering"),
            const SizedBox(height: 16),
            _buildInfoField("FACULTY", "Manjiri Samant"),
            const SizedBox(height: 24),

            // Start Session Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSessionActive ? null : _createSession,
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text(
                  "Start Session",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSessionActive
                      ? Colors.grey
                      : const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceOverviewCard() {
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
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Attendance Overview",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "LIVE COUNT",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _activeSession != null ? "0/0" : "Active",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 20),

            // Progress Section - Removed as requested
            const SizedBox(height: 24),

            // Timer Display - Show when session is active
            if (_currentSessionId != null && _remainingSeconds > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        const Text(
                          "Session Timer",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA50C22),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Time remaining",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Student Table Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "ROLL NUMBER",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          "NAME",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          "STATUS",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Student Rows - Show loading or empty state
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _isLoadingAttendance
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFA50C22),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Collecting attendance...",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _activeSession != null
                        ? const Center(
                            child: Text(
                              "No active session",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _attendanceData?.length ?? 0,
                            itemBuilder: (context, index) {
                              if (_attendanceData == null ||
                                  index >= _attendanceData!.length) {
                                return const SizedBox.shrink();
                              }

                              final student = _attendanceData![index];
                              final rollNumber =
                                  student['roll_number']?.toString() ?? '';
                              final name = student['name']?.toString() ?? '';
                              final status =
                                  student['status']?.toString() ?? '';
                              final present = status == 'PRESENT';

                              return Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        rollNumber,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Icon(
                                        present
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 16,
                                        color: present
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),

            // Footer - Removed End Session button as requested
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
