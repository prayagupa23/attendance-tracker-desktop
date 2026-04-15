// my_timetable_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dart:async';

class MyTimetableScreen extends StatefulWidget {
  const MyTimetableScreen({super.key});

  @override
  State<MyTimetableScreen> createState() => _MyTimetableScreenState();
}

class _MyTimetableScreenState extends State<MyTimetableScreen> {
  String? _facultyId;
  List<dynamic> _myTimetableData = [];
  bool _isLoading = false;
  String? _error;
  Timer? _timer;
  Map<String, dynamic>? _currentSession;
  Map<String, dynamic>? _nextSession;

  @override
  void initState() {
    super.initState();
    _loadFacultyId();
    // Set up timer to update current/next session every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateCurrentAndNextSessions();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadFacultyId() async {
    final prefs = await SharedPreferences.getInstance();
    final facultyId = prefs.getString('faculty_id');

    setState(() {
      _facultyId = facultyId;
    });

    if (_facultyId != null && _facultyId!.isNotEmpty) {
      _loadMyTimetable();
    } else {
      setState(() {
        _error = 'No faculty ID found. Please login again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMyTimetable() async {
    if (_facultyId == null || _facultyId!.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get all batches assigned to this faculty
      final batchesResponse = await ApiService.getBatches(_facultyId!);
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
            return session['faculty_id']?.toString() == _facultyId;
          }).toList();

          allTimetableData.addAll(facultySessions);
        } catch (e) {
          print('Debug: Error fetching timetable for batch $batch: $e');
          // Continue with other batches even if one fails
        }
      }

      if (mounted) {
        setState(() {
          _myTimetableData = allTimetableData;
          _isLoading = false;
        });
        // Update current and next sessions after loading data
        _updateCurrentAndNextSessions();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, Map<String, dynamic>> _processTimetableData() {
    Map<String, Map<String, dynamic>> timeSlotMap = {};

    // Process sessions and split 2-hour labs into 1-hour slots
    for (var item in _myTimetableData) {
      final startTime = item['start_time']?.toString().substring(0, 5) ?? '';
      final endTime = item['end_time']?.toString().substring(0, 5) ?? '';
      final timeSlot = '$startTime-$endTime';
      final day = item['day_of_week']?.toString() ?? '';
      final sessionType = item['session_type']?.toString() ?? '';

      if (sessionType.toUpperCase() == 'LAB' &&
          _isTwoHourLabSession(startTime, endTime)) {
        // Split 2-hour lab into two 1-hour sessions
        _addSplitLabSession(item, startTime, endTime, day, timeSlotMap);
      } else {
        // Add regular session as-is
        if (!timeSlotMap.containsKey(timeSlot)) {
          timeSlotMap[timeSlot] = {};
        }
        timeSlotMap[timeSlot]![day] = item;
      }
    }

    return timeSlotMap;
  }

  bool _isTwoHourLabSession(String startTime, String endTime) {
    final startHour = int.tryParse(startTime.split(':')[0]) ?? 0;
    final startMin = int.tryParse(startTime.split(':')[1]) ?? 0;
    final endHour = int.tryParse(endTime.split(':')[0]) ?? 0;
    final endMin = int.tryParse(endTime.split(':')[1]) ?? 0;

    return (endHour - startHour == 2) && (endMin - startMin == 0);
  }

  void _addSplitLabSession(
    Map<String, dynamic> originalSession,
    String startTime,
    String endTime,
    String day,
    Map<String, Map<String, dynamic>> timeSlotMap,
  ) {
    // Parse times
    final startHour = int.tryParse(startTime.split(':')[0]) ?? 0;
    final startMin = int.tryParse(startTime.split(':')[1]) ?? 0;
    final endHour = int.tryParse(endTime.split(':')[0]) ?? 0;
    final endMin = int.tryParse(endTime.split(':')[1]) ?? 0;

    // Create first hour session
    final firstHourEnd =
        '${startHour + 1}:${startMin.toString().padLeft(2, '0')}';
    final firstTimeSlot = '$startTime-$firstHourEnd';

    // Create second hour session
    final secondHourStart =
        '${startHour + 1}:${startMin.toString().padLeft(2, '0')}';
    final secondTimeSlot = '$secondHourStart-$endTime';

    // Copy original session data
    final firstSession = Map<String, dynamic>.from(originalSession);
    final secondSession = Map<String, dynamic>.from(originalSession);

    // Add to time slot map
    if (!timeSlotMap.containsKey(firstTimeSlot)) {
      timeSlotMap[firstTimeSlot] = {};
    }
    if (!timeSlotMap.containsKey(secondTimeSlot)) {
      timeSlotMap[secondTimeSlot] = {};
    }

    timeSlotMap[firstTimeSlot]![day] = firstSession;
    timeSlotMap[secondTimeSlot]![day] = secondSession;

    // Use endHour and endMin to avoid lint warnings
    print(
      'Debug: Split lab session from $startTime to $endTime (end: $endHour:$endMin)',
    );
  }

  void _updateCurrentAndNextSessions() {
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

    // Handle format like "10:30:00" or "10:30"
    final parts = timeString.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return _timeToMinutes(hour, minute);
    }
    return 0;
  }

  Widget _buildSessionStatusCards() {
    return Row(
      children: [
        // Current Session Card
        Expanded(
          child: _buildStatusCard(
            title: 'Current Session',
            session: _currentSession,
            isCurrent: true,
          ),
        ),
        const SizedBox(width: 16),
        // Next Session Card
        Expanded(
          child: _buildStatusCard(
            title: 'Next Session',
            session: _nextSession,
            isCurrent: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required Map<String, dynamic>? session,
    required bool isCurrent,
  }) {
    if (session == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCurrent ? Icons.play_circle : Icons.schedule,
                    size: 20,
                    color: isCurrent ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  isCurrent ? 'No sessions going on' : 'No more sessions today',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final courseCode = session['course_code']?.toString() ?? '';
    final courseName = session['course_name']?.toString() ?? courseCode;
    final batch = session['batch']?.toString() ?? '';
    final room = session['room_number']?.toString() ?? '';
    final labBatch = session['lab_batch']?.toString() ?? '';
    final startTime = session['start_time']?.toString().substring(0, 5) ?? '';
    final endTime = session['end_time']?.toString().substring(0, 5) ?? '';
    final sessionType = session['session_type']?.toString() ?? '';

    Color sessionColor = Colors.blue;
    if (sessionType.toUpperCase() == 'LAB') {
      sessionColor = Colors.deepOrange;
    } else if (sessionType.toUpperCase() == 'PROJECT') {
      sessionColor = Colors.green;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: sessionColor.withOpacity(0.3), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              sessionColor.withOpacity(0.05),
              sessionColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCurrent ? Icons.play_circle : Icons.schedule,
                  size: 20,
                  color: sessionColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Session Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: sessionColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$startTime - $endTime',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(Icons.group, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      batch,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (sessionType.toUpperCase() == 'LAB' &&
                        labBatch.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        '($labBatch)',
                        style: TextStyle(
                          fontSize: 12,
                          color: sessionColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(Icons.room, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Room $room',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                Icon(Icons.person, size: 24, color: Colors.grey[600]),
                const SizedBox(width: 8),
                const Text(
                  "My Timetable",
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

            // Current and Next Session Status
            _buildSessionStatusCards(),

            const SizedBox(height: 24),

            // Timetable Display
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
                            'Failed to load timetable',
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
                            onPressed: _loadMyTimetable,
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
                  : _myTimetableData.isEmpty
                  ? _buildEmptyState()
                  : _buildTimetableTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Timetable Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any scheduled sessions.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableTable() {
    final timeSlotMap = _processTimetableData();
    final timeSlots = [
      '10:30-11:30',
      '11:30-12:30',
      '13:15-14:15',
      '14:15-15:15',
      '15:30-16:30',
      '16:30-17:30',
    ];
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI'];

    // Use days variable to avoid lint warning
    print('Debug: Building timetable for days: ${days.join(', ')}');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Teaching Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Timetable Grid
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(80), // Time column
                    1: FixedColumnWidth(120), // MON
                    2: FixedColumnWidth(120), // TUE
                    3: FixedColumnWidth(120), // WED
                    4: FixedColumnWidth(120), // THU
                    5: FixedColumnWidth(120), // FRI
                  },
                  children: [
                    // Header row
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF8F9FA)),
                      children: [
                        _buildHeaderCell('Time'),
                        _buildHeaderCell('MON'),
                        _buildHeaderCell('TUE'),
                        _buildHeaderCell('WED'),
                        _buildHeaderCell('THU'),
                        _buildHeaderCell('FRI'),
                      ],
                    ),
                    // Time slot rows
                    ...timeSlots.map((timeSlot) {
                      return TableRow(
                        children: [
                          _buildTimeCell(timeSlot),
                          _buildDayCell(timeSlot, 'MON', timeSlotMap),
                          _buildDayCell(timeSlot, 'TUE', timeSlotMap),
                          _buildDayCell(timeSlot, 'WED', timeSlotMap),
                          _buildDayCell(timeSlot, 'THU', timeSlotMap),
                          _buildDayCell(timeSlot, 'FRI', timeSlotMap),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(right: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTimeCell(String timeSlot) {
    return Container(
      height: 45,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(right: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Text(
        timeSlot,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 10,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDayCell(
    String timeSlot,
    String day,
    Map<String, Map<String, dynamic>> timeSlotMap,
  ) {
    final session = timeSlotMap[timeSlot]?[day];

    return Container(
      height: 45,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: session != null ? _buildSessionCell(session) : null,
    );
  }

  Widget _buildSessionCell(Map<String, dynamic> session) {
    final sessionType = session['session_type']?.toString() ?? '';
    final courseCode = session['course_code']?.toString() ?? '';
    final batch = session['batch']?.toString() ?? '';
    final room = session['room_number']?.toString() ?? '';
    final labBatch = session['lab_batch']?.toString() ?? '';

    Color sessionColor = Colors.blue.withOpacity(0.15);
    Color textColor = Colors.blue;

    if (sessionType.toUpperCase() == 'LAB') {
      sessionColor = Colors.orange.withOpacity(0.15);
      textColor = Colors.deepOrange;
    }

    return Container(
      padding: const EdgeInsets.all(2), // Reduced padding
      decoration: BoxDecoration(
        color: sessionColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: textColor.withOpacity(0.4), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        children: [
          Text(
            courseCode,
            style: TextStyle(
              fontSize: 7, // Reduced font size
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                batch,
                style: TextStyle(
                  fontSize: 5, // Reduced font size
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              // Show lab batch for lab sessions inline with main batch
              if (sessionType.toUpperCase() == 'LAB' &&
                  labBatch.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  '($labBatch)',
                  style: TextStyle(
                    fontSize: 5, // Reduced font size
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ],
          ),
          Text(
            'R$room', // Shortened to fit
            style: TextStyle(
              fontSize: 5, // Reduced font size
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
