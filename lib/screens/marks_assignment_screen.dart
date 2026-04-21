// marks_assignment_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';

class MarksAssignmentScreen extends StatefulWidget {
  final String courseCode;
  final String courseName;
  final String? labBatch;
  final String year; // Added year parameter for API call
  final VoidCallback onBackPressed;

  const MarksAssignmentScreen({
    super.key,
    required this.courseCode,
    required this.courseName,
    this.labBatch,
    required this.year,
    required this.onBackPressed,
  });

  @override
  State<MarksAssignmentScreen> createState() => _MarksAssignmentScreenState();
}

class _MarksAssignmentScreenState extends State<MarksAssignmentScreen> {
  String? selectedSession;
  List<Map<String, dynamic>> _students = [];
  bool _isLoadingStudents = false;
  String? _studentsError;

  final List<TextEditingController> marks2Controllers = List.generate(
    15,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> marks3Controllers = List.generate(
    15,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> marks5Controllers = List.generate(
    15,
    (_) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    if (widget.labBatch != null) {
      _fetchStudents();
    }
  }

  @override
  void dispose() {
    for (final c in [
      ...marks2Controllers,
      ...marks3Controllers,
      ...marks5Controllers,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    if (widget.labBatch == null) return;

    setState(() {
      _isLoadingStudents = true;
      _studentsError = null;
    });

    try {
      final studentsData = await ApiService.getStudentsForLabBatch(
        year: widget.year, // Use year parameter for API call
        labBatch: widget.labBatch!,
      );

      setState(() {
        _students = studentsData.map((student) => student as Map<String, dynamic>).toList();
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() {
        _studentsError = e.toString();
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _exportToExcel() async {
    final excel = xl.Excel.createExcel();
    final xl.Sheet sheet = excel['Student Marks'];

    xl.CellStyle titleStyle() => xl.CellStyle(
      bold: true,
      fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
      fontSize: 14,
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: xl.ExcelColor.fromHexString('#8B0000'),
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
    );

    xl.CellStyle subTitleStyle() => xl.CellStyle(
      fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
      fontSize: 11,
      fontColorHex: xl.ExcelColor.fromHexString('#333333'),
      backgroundColorHex: xl.ExcelColor.fromHexString('#F5F5F5'),
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
    );

    xl.CellStyle sessionStyle() => xl.CellStyle(
      italic: true,
      fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
      fontSize: 10,
      fontColorHex: xl.ExcelColor.fromHexString('#555555'),
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    xl.CellStyle colHeaderStyle() => xl.CellStyle(
      bold: true,
      fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
      fontSize: 11,
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: xl.ExcelColor.fromHexString('#2E7D32'),
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
      textWrapping: xl.TextWrapping.WrapText,
    );

    xl.CellStyle totalColHeaderStyle() => xl.CellStyle(
      bold: true,
      fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
      fontSize: 11,
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: xl.ExcelColor.fromHexString('#1565C0'),
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
      textWrapping: xl.TextWrapping.WrapText,
    );

    xl.CellStyle rowStyle(bool isEven, {bool leftAlign = false}) =>
        xl.CellStyle(
          fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
          fontSize: 11,
          backgroundColorHex: xl.ExcelColor.fromHexString(
            isEven ? '#FFFFFF' : '#F9F9F9',
          ),
          horizontalAlign: leftAlign
              ? xl.HorizontalAlign.Left
              : xl.HorizontalAlign.Center,
          verticalAlign: xl.VerticalAlign.Center,
        );

    xl.CellStyle totalCellStyle(bool isEven) => xl.CellStyle(
      bold: true,
      fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
      fontSize: 11,
      backgroundColorHex: xl.ExcelColor.fromHexString(
        isEven ? '#E3F2FD' : '#BBDEFB',
      ),
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
    );

    xl.CellStyle totalRowStyle() => xl.CellStyle(
      bold: true,
      fontFamily: xl.getFontFamily(xl.FontFamily.Arial),
      fontSize: 11,
      backgroundColorHex: xl.ExcelColor.fromHexString('#E8F5E9'),
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
    );

    // Row 0: Institution header (A–G)
    sheet.merge(
      xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0),
    );
    sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = xl.TextCellValue('KJ Somaiya Polytechnic, Vidyavihar')
      ..cellStyle = titleStyle();

    // Row 1: Course info
    sheet.merge(
      xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 1),
    );
    sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
      ..value = xl.TextCellValue(
        '${widget.courseName}  |  Course Code: ${widget.courseCode}  |  Computer Engineering',
      )
      ..cellStyle = subTitleStyle();

    // Row 2: Session
    sheet.merge(
      xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
      xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 2),
    );
    sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
      ..value = xl.TextCellValue('Session: ${selectedSession ?? 'N/A'}')
      ..cellStyle = sessionStyle();

    // Row 3: Column headers
    final headers = [
      ('SR. NO.', false),
      ('ROLL NUMBER', false),
      ('NAME', false),
      ('MARKS 2\n(Out of 2)', false),
      ('MARKS 3\n(Out of 3)', false),
      ('MARKS 5\n(Out of 5)', false),
      ('TOTAL\n(Out of 10)', true), // true = use totalColHeaderStyle
    ];
    for (int c = 0; c < headers.length; c++) {
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3))
        ..value = xl.TextCellValue(headers[c].$1)
        ..cellStyle = headers[c].$2 ? totalColHeaderStyle() : colHeaderStyle();
    }

    // Rows 4–18: Student data
    final studentCount = _students.length > 15 ? 15 : _students.length;
    for (int i = 0; i < studentCount; i++) {
      final rowIndex = 4 + i;
      final excelRow = rowIndex + 1; // Excel is 1-indexed
      final isEven = i % 2 == 0;

      final m2 = marks2Controllers[i].text.trim();
      final m3 = marks3Controllers[i].text.trim();
      final m5 = marks5Controllers[i].text.trim();

      void set(int col, xl.CellValue val, {bool left = false}) {
        sheet.cell(
            xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
          )
          ..value = val
          ..cellStyle = rowStyle(isEven, leftAlign: left);
      }

      // Get real student data if available
      String rollNumber = '';
      String studentName = '';
      if (i < _students.length) {
        final student = _students[i];
        rollNumber = student['roll_number']?.toString() ?? '';
        studentName = student['name']?.toString() ?? 'Unknown';
      } else {
        // Fallback to placeholder data
        rollNumber = 'O23RC${23 + i}';
        studentName = 'Student ${i + 1}';
      }

      set(0, xl.IntCellValue(i + 1));
      set(1, xl.TextCellValue(rollNumber));
      set(2, xl.TextCellValue(studentName), left: true);
      set(
        3,
        m2.isNotEmpty ? xl.IntCellValue(int.parse(m2)) : xl.TextCellValue(''),
      );
      set(
        4,
        m3.isNotEmpty ? xl.IntCellValue(int.parse(m3)) : xl.TextCellValue(''),
      );
      set(
        5,
        m5.isNotEmpty ? xl.IntCellValue(int.parse(m5)) : xl.TextCellValue(''),
      );

      // TOTAL per student = D + E + F for this row
      sheet.cell(
          xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
        )
        ..value = xl.FormulaCellValue('D$excelRow+E$excelRow+F$excelRow')
        ..cellStyle = totalCellStyle(isEven);
    }

    // Row 19: Grand totals
    sheet.merge(
      xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 19),
      xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 19),
    );
    sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 19))
      ..value = xl.TextCellValue('TOTAL')
      ..cellStyle = totalRowStyle();

    for (int c = 3; c <= 6; c++) {
      final col = ['D', 'E', 'F', 'G'][c - 3];
      sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 19))
        ..value = xl.FormulaCellValue('SUM(${col}5:${col}19)')
        ..cellStyle = totalRowStyle();
    }

    // Column widths
    sheet.setColumnWidth(0, 9);
    sheet.setColumnWidth(1, 17);
    sheet.setColumnWidth(2, 30);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 15);
    sheet.setColumnWidth(5, 15);
    sheet.setColumnWidth(6, 15);

    // Row heights
    sheet.setRowHeight(0, 32);
    sheet.setRowHeight(1, 24);
    sheet.setRowHeight(2, 20);
    sheet.setRowHeight(3, 38);
    for (int i = 4; i <= 19; i++) sheet.setRowHeight(i, 22);

    // Save
    final fileBytes = excel.encode();
    if (fileBytes == null) return;

    Directory saveDir;
    final home = Platform.environment['USERPROFILE'] ?? '';
    final downloads = Directory('$home\\Downloads');
    saveDir = downloads.existsSync()
        ? downloads
        : await getApplicationDocumentsDirectory();

    final session = selectedSession?.replaceAll(' ', '_') ?? 'marks';
    final courseName = widget.courseName.replaceAll(' ', '_');
    final filePath = '${saveDir.path}\\${courseName}_${session}.xlsx';
    await File(filePath).writeAsBytes(fileBytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: $filePath'),
          backgroundColor: const Color(0xFF1B5E20),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBackPressed,
                icon: const Icon(Icons.arrow_back, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F5),
                  foregroundColor: Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Assign Marks - ${widget.courseName}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.courseName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Course Code: ${widget.courseCode}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        'Computer Engineering',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      if (widget.labBatch != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA50C22).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFA50C22).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Lab Batch: ${widget.labBatch}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFA50C22),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 150,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
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
                    value: selectedSession,
                    hint: const Text(
                      'Select Session',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: List.generate(15, (i) => i + 1).map((s) {
                      return DropdownMenuItem<String>(
                        value: 'Session $s',
                        child: Text(
                          'Session $s',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => selectedSession = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Student Marks",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 1,
                          ),
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
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              "MARKS 2",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              "MARKS 3",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              "MARKS 5",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoadingStudents
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA50C22)),
                              ),
                            )
                          : _studentsError != null
                              ? Center(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 40,
                                          color: Colors.red[400],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Failed to load students',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            _studentsError!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: _fetchStudents,
                                          icon: const Icon(Icons.refresh, size: 16),
                                          label: const Text('Retry'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFA50C22),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _students.length > 15 ? 15 : _students.length,
                                  itemBuilder: (context, index) {
                                    if (index >= _students.length) {
                                      return Container(
                                        height: 50,
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
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
                                                '',
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
                                                'No student data',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                            _markField(marks2Controllers[index], '0-2', 2),
                                            _markField(marks3Controllers[index], '0-3', 3),
                                            _markField(marks5Controllers[index], '0-5', 5),
                                          ],
                                        ),
                                      );
                                    }

                                    final student = _students[index];
                                    final rollNumber = student['roll_number']?.toString() ?? '';
                                    final studentName = student['name']?.toString() ?? 'Unknown';

                                    return Container(
                                      height: 50,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                              studentName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          _markField(marks2Controllers[index], '0-2', 2),
                                          _markField(marks3Controllers[index], '0-3', 3),
                                          _markField(marks5Controllers[index], '0-5', 5),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text(
                    'Save Marks',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }

  Widget _markField(TextEditingController ctrl, String hint, int max) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
            _MaxValueFormatter(max),
          ],
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _MaxValueFormatter extends TextInputFormatter {
  final int maxValue;
  _MaxValueFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final n = int.tryParse(newValue.text);
    if (n == null || n > maxValue) return oldValue;
    return newValue;
  }
}
