// faculty_dashboard.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:final_year_project_desktop/widgets/sidebar.dart';
import 'package:final_year_project_desktop/screens/home_screen.dart';
import 'package:final_year_project_desktop/screens/courses_screen.dart';
import 'package:final_year_project_desktop/screens/batches_screen.dart';
import 'package:final_year_project_desktop/screens/timetable_screen.dart';
import 'package:final_year_project_desktop/screens/my_timetable_screen.dart';
import 'package:final_year_project_desktop/screens/defaulter_screen.dart';
import 'package:final_year_project_desktop/services/api_service.dart';

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
  List<dynamic> _myTimetableData = [];
  Map<String, dynamic>? _currentSession;
  Map<String, dynamic>? _nextSession;
  Timer? _timer;
  bool _isLoadingSessions = false;

  // Session management variables
  String? _currentSessionId;
  bool _isSessionActive = false;
  Timer? _sessionTimer;
  int _remainingSeconds = 60; // 1 minute in seconds
  List<dynamic>? _attendanceData;
  bool _isLoadingAttendance = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BatchesScreen(),
    const CoursesScreen(),
    const TimetableScreen(),
    const MyTimetableScreen(),
    const DefaulterScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchTimetableData();
    // Set up timer to update current/next session every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateSessionStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _fetchTimetableData() async {
    setState(() {
      _isLoadingSessions = true;
    });

    try {
      // Get all batches assigned to this faculty
      final batchesResponse = await ApiService.getBatches(widget.facultyId);
      final batches = batchesResponse
          .map((batch) => batch['code'].toString())
          .toList();

      List<dynamic> allTimetableData = [];

      // Fetch timetable for each batch
      for (String batch in batches) {
        try {
          final timetableResponse = await ApiService.getTimetable(batch);
          final batchTimetable = timetableResponse['data'] ?? [];

          // Filter sessions that belong to this faculty
          final facultySessions = batchTimetable.where((session) {
            return session['faculty_id']?.toString() == widget.facultyId;
          }).toList();

          allTimetableData.addAll(facultySessions);
        } catch (e) {
          print('Debug: Error fetching timetable for batch $batch: $e');
        }
      }

      setState(() {
        _myTimetableData = allTimetableData;
        _isLoadingSessions = false;
      });
      _updateSessionStatus();
    } catch (e) {
      setState(() {
        _isLoadingSessions = false;
      });
      print('Debug: Error fetching timetable data: $e');
    }
  }

  void _updateSessionStatus() {
    if (_myTimetableData.isEmpty) {
      setState(() {
        _currentSession = null;
        _nextSession = null;
      });
      return;
    }

    final now = DateTime.now();
    final currentDay = _getDayOfWeek(now.weekday);
    final currentTime = _timeToMinutes(now.hour, now.minute);

    List<Map<String, dynamic>> todaySessions = _myTimetableData
        .where((session) => session['day_of_week']?.toString() == currentDay)
        .cast<Map<String, dynamic>>()
        .toList();

    // Sort sessions by start time
    todaySessions.sort((a, b) {
      final aTime = _parseTime(a['start_time']?.toString() ?? '');
      final bTime = _parseTime(b['start_time']?.toString() ?? '');
      return aTime.compareTo(bTime);
    });

    Map<String, dynamic>? current;
    Map<String, dynamic>? next;

    for (var session in todaySessions) {
      final startTime = _parseTime(session['start_time']?.toString() ?? '');
      final endTime = _parseTime(session['end_time']?.toString() ?? '');

      if (currentTime >= startTime && currentTime < endTime) {
        current = session;
      } else if (currentTime < startTime && next == null) {
        next = session;
      }
    }

    setState(() {
      _currentSession = current;
      _nextSession = next;
    });
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'MON';
      case 2:
        return 'TUE';
      case 3:
        return 'WED';
      case 4:
        return 'THU';
      case 5:
        return 'FRI';
      case 6:
        return 'SAT';
      case 7:
        return 'SUN';
      default:
        return 'MON';
    }
  }

  int _timeToMinutes(int hour, int minute) {
    return hour * 60 + minute;
  }

  int _parseTime(String timeString) {
    if (timeString.isEmpty) return 0;

    final parts = timeString.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return _timeToMinutes(hour, minute);
    }
    return 0;
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
            padding: const EdgeInsets.only(right: 16),
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
          Expanded(flex: 4, child: _buildMainContent()),
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
              onRefresh: _refreshDashboard,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildMainContent() {
    if (_selectedIndex == 0) {
      // Home screen with dynamic session information
      return _buildDynamicHomeScreen();
    } else {
      // Other screens remain unchanged
      return _screens[_selectedIndex];
    }
  }

  Widget _buildDynamicHomeScreen() {
    if (_isLoadingSessions) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA50C22)),
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFFF5F6F8),
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lecture Information Card
            Expanded(flex: 2, child: _buildDynamicLectureCard()),
            const SizedBox(width: 24),
            // Attendance Overview Card
            Expanded(flex: 3, child: _buildDynamicAttendanceCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicLectureCard() {
    bool hasCurrentSession = _currentSession != null;
    bool hasNextSession = _nextSession != null;

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

            // Content based on session status
            if (hasCurrentSession) ...[
              _buildSessionContent(_currentSession!),
            ] else if (hasNextSession) ...[
              _buildCountdownContent(_nextSession!),
            ] else ...[
              _buildNoSessionContent(),
            ],

            const SizedBox(height: 24),

            // Start Session Button (only enabled when there's a current session and no active session)
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (hasCurrentSession && !_isSessionActive)
                        ? Colors.transparent
                        : const Color(0xFFE0E0E0),
                    width: 2,
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: (hasCurrentSession && !_isSessionActive)
                      ? _createSession
                      : null,
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text(
                    "Start Session",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (hasCurrentSession && !_isSessionActive)
                        ? const Color(0xFF2E7D32)
                        : Colors.transparent,
                    foregroundColor: (hasCurrentSession && !_isSessionActive)
                        ? Colors.white
                        : const Color(0xFF666666),
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionContent(Map<String, dynamic> session) {
    final courseName =
        session['course_name']?.toString() ??
        session['course_code']?.toString() ??
        '';
    final room = session['room_number']?.toString() ?? '';
    final startTime = session['start_time']?.toString().substring(0, 5) ?? '';
    final endTime = session['end_time']?.toString().substring(0, 5) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lecture Cover
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
        _buildInfoField("LECTURE", courseName),
        const SizedBox(height: 16),
        _buildInfoField("TIME SLOT", "$startTime - $endTime"),
        const SizedBox(height: 16),
        _buildInfoField("ROOM NUMBER", room),
        const SizedBox(height: 16),
        _buildInfoField("DEPARTMENT", widget.department),
        const SizedBox(height: 16),
        _buildInfoField("FACULTY", widget.facultyName),
      ],
    );
  }

  Widget _buildCountdownContent(Map<String, dynamic> nextSession) {
    final courseName = nextSession['course_name']?.toString() ?? '';
    final startTime =
        nextSession['start_time']?.toString().substring(0, 5) ?? '';
    final room = nextSession['room_number']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, size: 40, color: Colors.orange),
              const SizedBox(height: 8),
              const Text(
                "Next Session",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          courseName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFA50C22),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _buildCountdownTimer(startTime),
        const SizedBox(height: 16),
        _buildInfoField("ROOM", room),
      ],
    );
  }

  Widget _buildCountdownTimer(String startTime) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1), (count) => count),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final sessionTime = _parseTime(startTime);
        final currentTime = _timeToMinutes(now.hour, now.minute);

        if (currentTime >= sessionTime) {
          return const Text(
            "Session Starting Now!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          );
        }

        final minutesUntil = sessionTime - currentTime;
        if (minutesUntil <= 0) return const SizedBox.shrink();

        final hours = minutesUntil ~/ 60;
        final minutes = minutesUntil % 60;

        return Text(
          "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} till next session",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFA50C22),
          ),
        );
      },
    );
  }

  Widget _buildNoSessionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFF8F8),
                const Color(0xFFFFF0F0),
                const Color(0xFFFEF5F5),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFA50C22).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.self_improvement,
                  size: 32,
                  color: const Color(0xFFA50C22),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "No Sessions Today",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          "Enjoy your free time!",
          style: TextStyle(
            fontSize: 16,
            color: const Color(0xFF666666),
            height: 1.5,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicAttendanceCard() {
    bool hasCurrentSession = _currentSession != null;

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
                      color: hasCurrentSession
                          ? Colors.grey[600]
                          : Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Attendance Overview",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: hasCurrentSession
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Refresh Button (only show when session is active)
                    if (_isSessionActive) ...[
                      IconButton(
                        onPressed: _refreshAttendance,
                        icon: const Icon(
                          Icons.refresh,
                          size: 20,
                          color: Color(0xFFA50C22),
                        ),
                        tooltip: "Refresh Attendance",
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "LIVE COUNT",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: hasCurrentSession
                                ? Colors.grey[600]
                                : Colors.grey[400],
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasCurrentSession
                              ? "${_attendanceData?.length ?? 0}"
                              : "Inactive",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: hasCurrentSession
                                ? Colors.black87
                                : const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 20),

            // Content based on session status
            if (hasCurrentSession) ...[
              _buildActiveAttendanceContent(),
            ] else ...[
              _buildInactiveAttendanceContent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAttendanceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timer Display
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

            // Student Table Content
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildAttendanceTableContent(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceTableContent() {
    if (_isLoadingAttendance) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA50C22)),
            ),
            const SizedBox(height: 16),
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
      );
    }

    if (_attendanceData == null || _attendanceData!.isEmpty) {
      return const Center(
        child: Text(
          "No attendance data available",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    // Show attendance data
    return ListView.builder(
      itemCount: _attendanceData!.length,
      itemBuilder: (context, index) {
        final student = _attendanceData![index];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  student['roll_number']?.toString() ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  student['name']?.toString() ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Present",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInactiveAttendanceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFF8F8),
                const Color(0xFFFFF0F0),
                const Color(0xFFFEF5F5),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Icon(
                  Icons.coffee,
                  size: 36,
                  color: const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "No Active Session",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Start a session to track attendance",
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF666666),
                  height: 1.5,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
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

  void _startSessionTimer() {
    setState(() {
      _remainingSeconds = 60; // 1 minute
    });

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _sessionTimer?.cancel();
        // Fetch attendance data when 1 minute is up
        _fetchAttendanceData();
      }
    });
  }

  Future<void> _fetchAttendanceData() async {
    if (_currentSessionId == null) return;

    setState(() {
      _isLoadingAttendance = true;
    });

    try {
      final attendance = await ApiService.getAttendanceBySessionId(
        _currentSessionId!,
      );
      if (mounted) {
        setState(() {
          _attendanceData = attendance;
          _isLoadingAttendance = false;
        });
        print('Attendance data fetched: ${attendance.length} students');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAttendance = false;
        });
        print('Error fetching attendance: $e');
      }
    }
  }

  Future<void> _refreshAttendance() async {
    if (!_isSessionActive || _currentSessionId == null) return;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Refreshing attendance...'),
          ],
        ),
        backgroundColor: Color(0xFFA50C22),
        duration: Duration(seconds: 2),
      ),
    );

    // Fetch attendance data
    await _fetchAttendanceData();

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attendance updated: ${_attendanceData?.length ?? 0} students',
          ),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _refreshDashboard() async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Refreshing dashboard...'),
          ],
        ),
        backgroundColor: Color(0xFFA50C22),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Refresh timetable data
      await _fetchTimetableData();

      // Update session status
      _updateSessionStatus();

      // If session is active, refresh attendance data too
      if (_isSessionActive && _currentSessionId != null) {
        await _fetchAttendanceData();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard refreshed successfully'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing dashboard: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _createSession() async {
    if (widget.facultyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faculty ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if there's already an active session
    if (_currentSessionId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session already active'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final response = await ApiService.createSession(
        widget.facultyId,
        sessionData: _currentSession,
      );

      if (mounted) {
        setState(() {
          _currentSessionId = response['session_id'];
          _isSessionActive = true;
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
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
}
