import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' as excel;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class StudentAttendance {
  final double attendancePercent;
  final int attended;
  final String batch;
  final String labGroup;
  final String studentName;
  final String subject;
  final int total;

  StudentAttendance({
    required this.attendancePercent,
    required this.attended,
    required this.batch,
    required this.labGroup,
    required this.studentName,
    required this.subject,
    required this.total,
  });

  factory StudentAttendance.fromJson(Map<String, dynamic> json) {
    return StudentAttendance(
      attendancePercent: (json['Attendance %'] as num).toDouble(),
      attended: json['Attended'] as int,
      batch: json['Batch'] as String,
      labGroup: json['Lab Group'] as String,
      studentName: json['Student Name'] as String,
      subject: json['Subject'] as String,
      total: json['Total'] as int,
    );
  }
}

// ── Screen ───────────────────────────────────────────────────────────────────

class DefaulterScreen extends StatefulWidget {
  const DefaulterScreen({super.key});

  @override
  State<DefaulterScreen> createState() => _DefaulterScreenState();
}

class _DefaulterScreenState extends State<DefaulterScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  int _selectedPercentage = 75;
  String? _selectedBatch;
  String? _selectedSubject;
  List<StudentAttendance> _allStudents = [];
  List<StudentAttendance> _displayedStudents = [];
  List<String> _subjects = [];
  bool _isLoading = false;
  bool _hasGenerated = false;
  String? _errorMessage;

  final List<int> _percentages = List.generate(51, (i) => 50 + i);
  final List<String> _batches = ['FYCO', 'SYCO', 'TYCO'];

  static const String _apiUrl = 'http://13.235.16.3:5000/student/attendance';

  // ── Theme constants ────────────────────────────────────────────────────────
  static const _bg = Color(0xFFF5F6F8);
  static const _cardBg = Colors.white;
  static const _accent = Color(0xFFE65100);        // deep orange
  static const _accentLight = Color(0xFFFFF3E0);
  static const _headerText = Color(0xFF1A1A2E);
  static const _labelText = Color(0xFF6B7280);
  static const _borderColor = Color(0xFFE0E0E0);
  static const _tableHeader = Color(0xFFF8F9FA);

  // ── API ────────────────────────────────────────────────────────────────────

  Future<void> _fetchAndGenerate() async {
    if (_selectedBatch == null) {
      setState(() => _errorMessage = 'Please select a batch.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasGenerated = false;
    });

    try {
      final response =
          await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> jsonData;
        
        if (responseData is Map<String, dynamic>) {
          // API returned a Map, look for data in common keys
          if (responseData.containsKey('data')) {
            jsonData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('students')) {
            jsonData = responseData['students'] as List<dynamic>;
          } else if (responseData.containsKey('results')) {
            jsonData = responseData['results'] as List<dynamic>;
          } else {
            // If no common keys found, try to extract values
            jsonData = responseData.values.where((v) => v is List).first as List<dynamic>;
          }
        } else if (responseData is List<dynamic>) {
          // API returned a List directly
          jsonData = responseData;
        } else {
          throw Exception('Unexpected response format: ${responseData.runtimeType}');
        }
        
        final List<StudentAttendance> all =
            jsonData.map((e) => StudentAttendance.fromJson(e)).toList();

        final batchFiltered = all.where((s) => s.batch == _selectedBatch).toList();
        final subjectSet = batchFiltered.map((s) => s.subject).toSet().toList()
          ..sort();

        List<StudentAttendance> subjectFiltered = batchFiltered;
        if (_selectedSubject != null && subjectSet.contains(_selectedSubject)) {
          subjectFiltered =
              batchFiltered.where((s) => s.subject == _selectedSubject).toList();
        }

        final defaulters = subjectFiltered
            .where((s) => s.attendancePercent < _selectedPercentage)
            .toList()
          ..sort((a, b) => a.attendancePercent.compareTo(b.attendancePercent));

        setState(() {
          _allStudents = all;
          _subjects = subjectSet;
          _displayedStudents = defaulters;
          _isLoading = false;
          _hasGenerated = true;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}. Please try again.';
          _isLoading = false;
        });
      }
    } on SocketException {
      setState(() {
        _errorMessage = 'Network error: Unable to reach server.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ── Excel Export ───────────────────────────────────────────────────────────

  Future<void> _exportToExcel() async {
    if (_displayedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export!')),
      );
      return;
    }

    try {
      final excelFile = excel.Excel.createExcel();
      final excel.Sheet sheet = excelFile['Defaulter List'];

      final headerStyle = excel.CellStyle(
        bold: true,
        backgroundColorHex: excel.ExcelColor.fromHexString('#E65100'),
        fontColorHex: excel.ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: excel.HorizontalAlign.Center,
      );

      final headers = [
        'Sr. No.',
        'Student Name',
        'Batch',
        'Lab Group',
        'Subject',
        'Attended',
        'Total',
        'Attendance %',
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell =
            sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = excel.TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      for (int i = 0; i < _displayedStudents.length; i++) {
        final s = _displayedStudents[i];
        final rowData = [
          (i + 1).toString(),
          s.studentName,
          s.batch,
          s.labGroup,
          s.subject,
          s.attended.toString(),
          s.total.toString(),
          '${s.attendancePercent.toStringAsFixed(2)}%',
        ];

        final rowStyle = excel.CellStyle(
          backgroundColorHex: i % 2 == 0
              ? excel.ExcelColor.fromHexString('#FFF3E0')
              : excel.ExcelColor.fromHexString('#FFFFFF'),
        );

        for (int j = 0; j < rowData.length; j++) {
          final cell = sheet.cell(
              excel.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
          cell.value = excel.TextCellValue(rowData[j]);
          cell.cellStyle = rowStyle;
        }
      }

      sheet.setColumnWidth(0, 8);
      sheet.setColumnWidth(1, 25);
      sheet.setColumnWidth(2, 10);
      sheet.setColumnWidth(3, 12);
      sheet.setColumnWidth(4, 30);
      sheet.setColumnWidth(5, 12);
      sheet.setColumnWidth(6, 10);
      sheet.setColumnWidth(7, 15);

      final downloadsDir = await getDownloadsDirectory();
      final filePath =
          '${downloadsDir!.path}/Defaulter_List_${_selectedBatch}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      final fileBytes = excelFile.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported successfully to:\n$filePath'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _onBatchChanged(String? batch) {
    setState(() {
      _selectedBatch = batch;
      _selectedSubject = null;
      _subjects = [];
      _displayedStudents = [];
      _hasGenerated = false;
    });
    
    // Fetch available subjects for the selected batch
    if (batch != null) {
      _fetchSubjectsForBatch(batch);
    }
  }

  Future<void> _fetchSubjectsForBatch(String batch) async {
    try {
      final response =
          await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> jsonData;
        
        if (responseData is Map<String, dynamic>) {
          // API returned a Map, look for data in common keys
          if (responseData.containsKey('data')) {
            jsonData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('students')) {
            jsonData = responseData['students'] as List<dynamic>;
          } else if (responseData.containsKey('results')) {
            jsonData = responseData['results'] as List<dynamic>;
          } else {
            // If no common keys found, try to extract values
            jsonData = responseData.values.where((v) => v is List).first as List<dynamic>;
          }
        } else if (responseData is List<dynamic>) {
          // API returned a List directly
          jsonData = responseData;
        } else {
          throw Exception('Unexpected response format: ${responseData.runtimeType}');
        }
        
        final List<StudentAttendance> all =
            jsonData.map((e) => StudentAttendance.fromJson(e)).toList();

        final batchFiltered = all.where((s) => s.batch == batch).toList();
        final subjectSet = batchFiltered.map((s) => s.subject).toSet().toList()
          ..sort();

        setState(() {
          _subjects = subjectSet;
        });
      }
    } catch (e) {
      // Silently handle errors for subject fetching
      print('Error fetching subjects: $e');
    }
  }

  Color _percentageColor(double pct) {
    if (pct < 60) return const Color(0xFFD32F2F);
    if (pct < 75) return const Color(0xFFF57C00);
    return const Color(0xFF388E3C);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F6F8),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: table
                Expanded(flex: 3, child: _buildTableCard()),
                const SizedBox(width: 20),
                // Right: controls
                SizedBox(width: 210, child: _buildControlsColumn()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildExportButton(),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _accentLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.warning_amber_outlined,
              color: _accent, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Defaulters List',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _headerText,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Students below the attendance threshold',
              style: TextStyle(
                fontSize: 13,
                color: _labelText,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (_hasGenerated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _accentLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_outline, size: 15, color: _accent),
                const SizedBox(width: 6),
                Text(
                  '${_displayedStudents.length} Defaulters',
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Table Card ─────────────────────────────────────────────────────────────

  Widget _buildTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(Icons.person_off_outlined,
                    size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Students with Low Attendance',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (_hasGenerated && _displayedStudents.isNotEmpty)
                  Text(
                    'Below $_selectedPercentage%',
                    style: TextStyle(
                      fontSize: 12,
                      color: _accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table body
          Expanded(child: _buildTableBody()),
        ],
      ),
    );
  }

  Widget _buildTableBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text('Fetching attendance data…',
                style: TextStyle(color: _labelText, fontSize: 14)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  color: Colors.red.shade400, size: 36),
            ),
            const SizedBox(height: 14),
            Text(_errorMessage!,
                style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (!_hasGenerated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.list_alt_outlined,
                  color: Colors.grey.shade400, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Select filters and generate\nthe defaulter list',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  height: 1.5),
            ),
          ],
        ),
      );
    }

    if (_displayedStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline,
                  color: Colors.green.shade500, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('No Defaulters Found!',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            const SizedBox(height: 6),
            Text(
              'All students meet the $_selectedPercentage% threshold.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Column headers row
        Container(
          color: _tableHeader,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              _th('#', flex: 1),
              _th('Student / Batch', flex: 3),
              _th('Subject', flex: 3),
              _th('Attended', flex: 2),
              _th('Total', flex: 1),
              _th('Attendance', flex: 2),
            ],
          ),
        ),
        const Divider(height: 1),
        // Rows
        Expanded(
          child: ListView.separated(
            itemCount: _displayedStudents.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
            itemBuilder: (context, index) {
              final s = _displayedStudents[index];
              final pctColor = _percentageColor(s.attendancePercent);
              final isEven = index % 2 == 0;

              return Container(
                color: isEven ? const Color(0xFFFAFAFA) : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Serial
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    // Name + batch/lab
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.studentName,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${s.batch} · ${s.labGroup}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    // Subject
                    Expanded(
                      flex: 3,
                      child: Text(
                        s.subject,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Attended
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${s.attended}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87),
                      ),
                    ),
                    // Total
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${s.total}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ),
                    // Attendance % badge
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: pctColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: pctColor.withOpacity(0.35)),
                          ),
                          child: Text(
                            '${s.attendancePercent.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: pctColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _th(String label, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: label == 'Student / Batch' || label == 'Subject'
              ? TextAlign.left
              : TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
      );

  // ── Controls ───────────────────────────────────────────────────────────────

  Widget _buildControlsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _controlCard(
          label: 'Attendance Threshold',
          icon: Icons.percent,
          child: _styledDropdown<int>(
            value: _selectedPercentage,
            items: _percentages
                .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text('$p%',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600))))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedPercentage = v);
            },
          ),
        ),
        const SizedBox(height: 12),
        _controlCard(
          label: 'Select Batch',
          icon: Icons.groups_outlined,
          child: _styledDropdown<String>(
            value: _selectedBatch,
            hint: 'Choose batch',
            items: _batches
                .map((b) => DropdownMenuItem(
                    value: b,
                    child: Text(b,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600))))
                .toList(),
            onChanged: _onBatchChanged,
          ),
        ),
        const SizedBox(height: 12),
        _controlCard(
          label: 'Select Subject',
          icon: Icons.book_outlined,
          child: _styledDropdown<String>(
            value: _selectedSubject,
            hint: 'All Subjects',
            items: [
              const DropdownMenuItem<String>(
                  value: null,
                  child: SizedBox(
                    width: 120, // Reduced width for compactness
                    child: Text('All Subjects',
                        style: const TextStyle(fontSize: 11), // Smaller font
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                  )),
              ..._subjects.map((s) => DropdownMenuItem(
                    value: s,
                    child: SizedBox(
                      width: 120, // Reduced width for compactness
                      child: Text(s,
                          style: const TextStyle(fontSize: 10), // Smaller font
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ),
                  )),
            ],
            onChanged: _selectedBatch == null
                ? null
                : (v) => setState(() => _selectedSubject = v),
          ),
        ),
        const SizedBox(height: 20),

        // Generate button
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchAndGenerate,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.analytics_outlined, size: 18),
            label: Text(
              _isLoading ? 'Generating…' : 'Generate List',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _controlCard(
      {required String label,
      required IconData icon,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: _labelText),
              const SizedBox(width: 5),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _labelText,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _styledDropdown<T>({
    required T? value,
    String? hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: hint != null
          ? Text(hint,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400))
          : null,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // More compact padding
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      items: items,
      onChanged: onChanged,
      dropdownColor: Colors.white,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
    );
  }

  // ── Export Button ──────────────────────────────────────────────────────────

  Widget _buildExportButton() {
    final canExport = _hasGenerated && _displayedStudents.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: canExport ? _exportToExcel : null,
        icon: const Icon(Icons.download_outlined, size: 20),
        label: const Text('Export to Excel',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey.shade400,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}