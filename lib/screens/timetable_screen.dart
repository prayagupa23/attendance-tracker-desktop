// timetable_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String? selectedBatch;
  final List<String> batches = ['FYCO', 'SYCO', 'TYCO'];
  List<dynamic> timetableData = [];
  bool isLoading = false;
  String? error;

  // Lab batch selection state
  Map<String, String?> selectedLabBatches = {};

  // Time slot map for timetable data
  Map<String, Map<String, dynamic>> timeSlotMap = {};

  // Time slots for the grid
  final List<String> timeSlots = [
    '10:30-11:30',
    '11:30-12:30',
    '13:15-14:15',
    '14:15-15:15',
    '15:30-16:30',
    '16:30-17:30',
  ];

  // Days of the week
  final List<String> days = ['MON', 'TUE', 'WED', 'THU', 'FRI'];

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
                Icon(Icons.schedule, size: 24, color: Colors.grey[600]),
                const SizedBox(width: 8),
                const Text(
                  "Timetable",
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

            // Batch Selection Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Batch",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dropdown and Button Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: DropdownButton<String>(
                              value: selectedBatch,
                              hint: const Text(
                                'Select batch',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: batches.map((batch) {
                                return DropdownMenuItem<String>(
                                  value: batch,
                                  child: Text(
                                    batch,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedBatch = value;
                                  timetableData.clear();
                                  error = null;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // View Timetable Button
                        SizedBox(
                          width: 180,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: selectedBatch != null && !isLoading
                                ? _loadTimetable
                                : null,
                            icon: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              isLoading ? 'Loading...' : 'View Timetable',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  selectedBatch != null && !isLoading
                                  ? const Color(0xFFA50C22)
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              elevation: selectedBatch != null && !isLoading
                                  ? 2
                                  : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (selectedBatch != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Selected batch: ${_getBatchFullName(selectedBatch!)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Timetable Display
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFA50C22),
                        ),
                      ),
                    )
                  : error != null
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
                            error!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadTimetable,
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
                  : timetableData.isEmpty
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
            selectedBatch == null
                ? 'No Batch Selected'
                : 'No Timetable Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedBatch == null
                ? 'Please select a batch to view timetable'
                : 'No timetable data available for this batch',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableTable() {
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
            Text(
              '${_getBatchFullName(selectedBatch!)} Timetable',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Timetable Grid
            Expanded(
              child: SingleChildScrollView(child: _buildTimetableGrid()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableGrid() {
    // Clear and rebuild the time slot map
    timeSlotMap.clear();

    print('Debug: Processing ${timetableData.length} timetable entries');

    // Process sessions and split 2-hour labs into 1-hour slots
    for (var item in timetableData) {
      final startTime = item['start_time']?.toString().substring(0, 5) ?? '';
      final endTime = item['end_time']?.toString().substring(0, 5) ?? '';
      final timeSlot = '$startTime-$endTime';
      final day = item['day_of_week']?.toString() ?? '';
      final sessionType = item['session_type']?.toString() ?? '';

      print('Debug: Processing session - $sessionType at $timeSlot on $day');

      if (sessionType.toUpperCase() == 'PROJECT') {
        print('Debug: Processing PROJECT session at $timeSlot on $day');
      }

      if (sessionType.toUpperCase() == 'LAB' &&
          _isTwoHourLabSession(startTime, endTime)) {
        // Split 2-hour lab into two 1-hour sessions
        _addSplitLabSession(item, startTime, endTime, day);
      } else {
        // Add regular session as-is
        if (!timeSlotMap.containsKey(timeSlot)) {
          timeSlotMap[timeSlot] = {};
        }
        timeSlotMap[timeSlot]![day] = item;
        print(
          'Debug: Added to timeSlotMap[$timeSlot][$day] = ${item['course_code']}',
        );
      }
    }

    print(
      'Debug: Time slot map created with ${timeSlotMap.keys.length} time slots',
    );
    print('Debug: All time slots in map: ${timeSlotMap.keys.toList()}');
    print('Debug: Time slots to iterate: $timeSlots');

    return Table(
      border: TableBorder.all(color: const Color(0xFFE0E0E0), width: 1),
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
          print('Debug: Building row for $timeSlot');
          print(
            'Debug: Available sessions for $timeSlot: ${timeSlotMap[timeSlot]?.keys.toList()}',
          );
          return TableRow(
            children: [
              _buildTimeCell(timeSlot),
              _buildDayCell(timeSlot, 'MON'),
              _buildDayCell(timeSlot, 'TUE'),
              _buildDayCell(timeSlot, 'WED'),
              _buildDayCell(timeSlot, 'THU'),
              _buildDayCell(timeSlot, 'FRI'),
            ],
          );
        }).toList(),
      ],
    );
  }

  void _addSplitLabSession(
    Map<String, dynamic> originalSession,
    String startTime,
    String endTime,
    String day,
  ) {
    // Parse times
    final startHour = int.tryParse(startTime.split(':')[0]) ?? 0;
    final startMin = int.tryParse(startTime.split(':')[1]) ?? 0;
    final endHour = int.tryParse(endTime.split(':')[0]) ?? 0;
    final endMin = int.tryParse(endTime.split(':')[1]) ?? 0;

    // Create first hour session (start to start+1 hour)
    final firstHourEnd =
        '${startHour + 1}:${startMin.toString().padLeft(2, '0')}';
    final firstTimeSlot = '$startTime-$firstHourEnd';

    // Create second hour session (start+1 hour to end)
    final secondHourStart =
        '${startHour + 1}:${startMin.toString().padLeft(2, '0')}';
    final secondTimeSlot = '$secondHourStart-$endTime';

    // Copy original session data
    final firstSession = Map<String, dynamic>.from(originalSession);
    final secondSession = Map<String, dynamic>.from(originalSession);

    // Update times for split sessions
    firstSession['start_time'] = firstSession['start_time']
        ?.toString()
        .substring(0, 8);
    firstSession['end_time'] = firstHourEnd + ':00';
    secondSession['start_time'] = secondHourStart + ':00';
    secondSession['end_time'] = secondSession['end_time'];

    // Add to time slot map
    if (!timeSlotMap.containsKey(firstTimeSlot)) {
      timeSlotMap[firstTimeSlot] = {};
    }
    if (!timeSlotMap.containsKey(secondTimeSlot)) {
      timeSlotMap[secondTimeSlot] = {};
    }

    timeSlotMap[firstTimeSlot]![day] = firstSession;
    timeSlotMap[secondTimeSlot]![day] = secondSession;

    print(
      'Debug: Split 2-hour lab $startTime-$endTime into $firstTimeSlot and $secondTimeSlot for $day',
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

  void _showLabTooltip(String timeSlot, String day) {
    // Find all lab sessions for this time slot and day across all batches
    final labSessions = timetableData.where((item) {
      final startTime = item['start_time']?.toString().substring(0, 5) ?? '';
      final endTime = item['end_time']?.toString().substring(0, 5) ?? '';
      final itemTimeSlot = '$startTime-$endTime';
      final itemDay = item['day_of_week']?.toString() ?? '';
      final sessionType = item['session_type']?.toString() ?? '';

      return sessionType.toUpperCase() == 'LAB' &&
          itemDay == day &&
          (itemTimeSlot == timeSlot || _isLabSessionInTimeSlot(item, timeSlot));
    }).toList();

    if (labSessions.isEmpty) {
      _showSimpleTooltip('No lab sessions found for this time slot');
      return;
    }

    // Group by lab batch
    final Map<String, List<dynamic>> labBatches = {};
    for (var session in labSessions) {
      final labBatch = session['lab_batch']?.toString() ?? 'Unknown';
      if (!labBatches.containsKey(labBatch)) {
        labBatches[labBatch] = [];
      }
      labBatches[labBatch]!.add(session);
    }

    // Build tooltip content
    String tooltipContent = 'Lab Details - $day $timeSlot\n\n';

    // Add details for each batch
    for (String batch in ['C1', 'C2', 'C3']) {
      tooltipContent += 'Batch $batch:\n';
      if (labBatches.containsKey(batch)) {
        final sessions = labBatches[batch]!;
        for (var session in sessions) {
          final course =
              session['course_name']?.toString() ??
              session['course_code']?.toString() ??
              'Unknown';
          final room = session['room_number']?.toString() ?? 'N/A';
          final faculty = session['faculty_id']?.toString() ?? 'N/A';
          tooltipContent += '  $course - Room $room - Faculty $faculty\n';
        }
      } else {
        tooltipContent += '  No lab scheduled\n';
      }
      tooltipContent += '\n';
    }

    _showSimpleTooltip(tooltipContent.trim());
  }

  bool _isLabSessionInTimeSlot(Map<String, dynamic> session, String timeSlot) {
    final startTime = session['start_time']?.toString().substring(0, 5) ?? '';
    final endTime = session['end_time']?.toString().substring(0, 5) ?? '';

    // Check if this is a 2-hour lab that spans the current time slot
    if (_isTwoHourLabSession(startTime, endTime)) {
      // For 2-hour labs, check if the time slot falls within the lab session
      final slotStartTime = timeSlot.split('-')[0];
      final slotEndTime = timeSlot.split('-')[1];

      // Parse times for comparison
      final sessionStartHour = int.tryParse(startTime.split(':')[0]) ?? 0;
      final sessionStartMin = int.tryParse(startTime.split(':')[1]) ?? 0;
      final sessionEndHour = int.tryParse(endTime.split(':')[0]) ?? 0;
      final sessionEndMin = int.tryParse(endTime.split(':')[1]) ?? 0;
      final slotStartHour = int.tryParse(slotStartTime.split(':')[0]) ?? 0;
      final slotStartMin = int.tryParse(slotStartTime.split(':')[1]) ?? 0;
      final slotEndHour = int.tryParse(slotEndTime.split(':')[0]) ?? 0;
      final slotEndMin = int.tryParse(slotEndTime.split(':')[1]) ?? 0;

      // Check if slot is within session time
      final sessionStartTotal = sessionStartHour * 60 + sessionStartMin;
      final sessionEndTotal = sessionEndHour * 60 + sessionEndMin;
      final slotStartTotal = slotStartHour * 60 + slotStartMin;
      final slotEndTotal = slotEndHour * 60 + slotEndMin;

      return slotStartTotal >= sessionStartTotal &&
          slotEndTotal <= sessionEndTotal;
    }

    return false;
  }

  void _showSimpleTooltip(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lab Information', style: TextStyle(fontSize: 16)),
          content: SingleChildScrollView(
            child: Text(message, style: const TextStyle(fontSize: 12)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowFullDayProject(String day) {
    return selectedBatch == 'TYCO' && day == 'FRI';
  }

  Widget _buildDayCell(String timeSlot, String day) {
    final session = timeSlotMap[timeSlot]?[day];

    return Container(
      height: 45,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: _shouldShowFullDayProject(day)
          ? _buildSingleSessionCell({
              'course_code': 'PROJ',
              'session_type': 'PROJECT',
            })
          : session != null
          ? _buildSessionContent(session, timeSlot, day)
          : null,
    );
  }

  Widget _buildSessionContent(
    Map<String, dynamic> session,
    String timeSlot,
    String day,
  ) {
    final sessionType = session['session_type']?.toString() ?? '';
    final startTime = session['start_time']?.toString().substring(0, 5) ?? '';
    final endTime = session['end_time']?.toString().substring(0, 5) ?? '';
    final labBatch = session['lab_batch']?.toString() ?? '';

    // Check if this is a 2-hour lab session that needs to be split (only LAB sessions)
    if (sessionType.toUpperCase() == 'LAB' &&
        _isTwoHourLabSession(startTime, endTime)) {
      return _buildTwoHourLabSession(
        session,
        startTime,
        endTime,
        timeSlot,
        day,
      );
    } else {
      // For regular sessions (including PROJECT), display as normal 1-hour cells
      return _buildSingleSessionCell(session);
    }
  }

  bool _isTwoHourLabSession(String startTime, String endTime) {
    // Parse times to compare
    final startHour = int.tryParse(startTime.split(':')[0]) ?? 0;
    final startMin = int.tryParse(startTime.split(':')[1]) ?? 0;
    final endHour = int.tryParse(endTime.split(':')[0]) ?? 0;
    final endMin = int.tryParse(endTime.split(':')[1]) ?? 0;

    final isTwoHours = (endHour - startHour == 2) && (endMin - startMin == 0);

    print(
      'Debug: Checking if $startTime-$endTime is 2-hour session: $isTwoHours',
    );

    // Check if exactly 2 hours (e.g., 13:15-15:15)
    return isTwoHours;
  }

  Widget _buildTwoHourLabSession(
    Map<String, dynamic> session,
    String startTime,
    String endTime,
    String timeSlot,
    String day,
  ) {
    final sessionType = session['session_type']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First hour slot
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: sessionType.toUpperCase() == 'PROJECT'
                  ? Colors.green.withOpacity(0.15)
                  : Colors.orange.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
              border: Border.all(
                color: sessionType.toUpperCase() == 'PROJECT'
                    ? Colors.green.withOpacity(0.4)
                    : Colors.deepOrange.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (sessionType.toUpperCase() == 'LAB') ...[
                  // View Lab button - takes full width
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: () => _showLabTooltip(timeSlot, day),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: Colors.deepOrange.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          'View Lab',
                          style: TextStyle(
                            fontSize: 7,
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  // Lab batch dropdown
                  Expanded(
                    flex: 2,
                    child: _buildLabBatchDropdown(
                      session,
                      startTime,
                      'first',
                      timeSlot,
                      day,
                    ),
                  ),
                ] else ...[
                  // For non-LAB sessions (PROJECT), show course code
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        session['course_code']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: sessionType.toUpperCase() == 'PROJECT'
                              ? Colors.green
                              : Colors.deepOrange,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Second hour slot
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: sessionType.toUpperCase() == 'PROJECT'
                  ? Colors.green.withOpacity(0.15)
                  : Colors.orange.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
              border: Border.all(
                color: sessionType.toUpperCase() == 'PROJECT'
                    ? Colors.green.withOpacity(0.4)
                    : Colors.deepOrange.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (sessionType.toUpperCase() == 'LAB') ...[
                  // View Lab button
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: () => _showLabTooltip(timeSlot, day),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: Colors.deepOrange.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          'View Lab',
                          style: TextStyle(
                            fontSize: 7,
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  // Lab batch dropdown
                  Expanded(
                    flex: 2,
                    child: _buildLabBatchDropdown(
                      session,
                      startTime,
                      'second',
                      timeSlot,
                      day,
                    ),
                  ),
                ] else ...[
                  // For non-LAB sessions (PROJECT), show course code
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        session['course_code']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: sessionType.toUpperCase() == 'PROJECT'
                              ? Colors.green
                              : Colors.deepOrange,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabBatchDropdown(
    Map<String, dynamic> session,
    String startTime,
    String hourPart,
    String timeSlot,
    String day,
  ) {
    final labBatch = session['lab_batch']?.toString() ?? '';
    final key = '$timeSlot-$day-$hourPart';
    final currentSelection = selectedLabBatches[key] ?? labBatch;

    return Container(
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.deepOrange.withOpacity(0.3), width: 1),
      ),
      child: DropdownButton<String>(
        value: currentSelection.isNotEmpty ? currentSelection : null,
        hint: Text(
          'Select Batch',
          style: TextStyle(
            fontSize: 7,
            color: Colors.deepOrange.withOpacity(0.7),
          ),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, size: 12, color: Colors.deepOrange),
        style: TextStyle(fontSize: 7, color: Colors.deepOrange),
        items: ['C1', 'C2', 'C3'].map((batch) {
          return DropdownMenuItem<String>(
            value: batch,
            child: Text(
              batch,
              style: const TextStyle(fontSize: 7, color: Colors.deepOrange),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedLabBatches[key] = value;
          });
        },
      ),
    );
  }

  Widget _buildSingleSessionCell(Map<String, dynamic> session) {
    final sessionType = session['session_type']?.toString() ?? '';
    final courseCode = session['course_code']?.toString() ?? '';
    final timeSlot =
        '${session['start_time']?.toString().substring(0, 5) ?? ''}-${session['end_time']?.toString().substring(0, 5) ?? ''}';
    final day = session['day_of_week']?.toString() ?? '';

    Color sessionColor = Colors.blue.withOpacity(0.15);
    Color textColor = Colors.blue;

    // Handle PROJECT sessions with different color
    if (sessionType.toUpperCase() == 'PROJECT') {
      sessionColor = Colors.green.withOpacity(0.15);
      textColor = Colors.green;
    } else if (sessionType.toUpperCase() == 'LAB') {
      sessionColor = Colors.orange.withOpacity(0.15);
      textColor = Colors.deepOrange;
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: sessionColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: textColor.withOpacity(0.4), width: 1),
      ),
      child: sessionType.toUpperCase() == 'LAB'
          ? Center(
              child: GestureDetector(
                onTap: () => _showLabTooltip(timeSlot, day),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: Colors.deepOrange.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    'View Lab',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                courseCode,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
    );
  }

  Future<void> _loadTimetable() async {
    if (selectedBatch == null) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await ApiService.getTimetable(selectedBatch!);
      if (mounted) {
        setState(() {
          timetableData = response['data'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
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
