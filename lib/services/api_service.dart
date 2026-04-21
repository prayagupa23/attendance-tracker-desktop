import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://13.235.16.3:5000"; // deployed API URL

  static Future<Map<String, dynamic>> login(
    String facultyId,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/faculty/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"faculty_id": facultyId, "password": password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Faculty Login failed");
    }
  }

  static Future<Map<String, dynamic>> createSession(
    String facultyId, {
    Map<String, dynamic>? sessionData,
  }) async {
    final url = Uri.parse("$baseUrl/sessions/create");

    // Use sessionData if provided, otherwise fallback to default
    final requestBody = sessionData != null
        ? {
            "course_code":
                sessionData['course_code'] ?? sessionData['course_name'] ?? "",
            "faculty_id": facultyId,
          }
        : {"course_code": "IP", "faculty_id": facultyId};

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Session creation failed");
    }
  }

  static Future<Map<String, dynamic>> getActiveSession(String facultyId) async {
    final url = Uri.parse("$baseUrl/sessions/active");

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // If there's an active session, return the first one
      if (data is List && data.isNotEmpty) {
        final activeSessions = data as List;
        for (final session in activeSessions) {
          if (session['faculty_id'] == facultyId) {
            return session;
          }
        }
      }
      throw Exception("No active session found for this faculty");
    } else {
      throw Exception(data["error"] ?? "Failed to fetch active session");
    }
  }

  static Future<List<dynamic>> getAttendance(String sessionId) async {
    final url = Uri.parse("$baseUrl/attendance/session/$sessionId");

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Failed to fetch attendance");
    }
  }

  static Future<List<dynamic>> getAttendanceBySessionId(
    String sessionId,
  ) async {
    final url = Uri.parse("$baseUrl/attendance/session/$sessionId");

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Failed to fetch attendance");
    }
  }

  static Future<List<dynamic>> getBatches(String facultyId) async {
    final url = Uri.parse("$baseUrl/api/faculty/batches?faculty_id=$facultyId");

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);
    print('Debug: Raw API response: $data'); // Debug line

    if (response.statusCode == 200) {
      // Handle the specific response format: { "assigned_batches": ["FYCO", "TYCO"], "faculty_id": "FAC002" }
      if (data is Map<String, dynamic>) {
        if (data.containsKey('assigned_batches') &&
            data['assigned_batches'] is List) {
          final batchCodes = data['assigned_batches'] as List<dynamic>;
          print('Debug: Batch codes found: $batchCodes'); // Debug line

          // Convert batch codes to batch objects with the expected structure
          final batchesList = batchCodes
              .map(
                (code) => {
                  'code': code.toString(),
                  'name': _getBatchFullName(code.toString()),
                  // Student count will be fetched separately for each batch
                },
              )
              .toList();

          print('Debug: Processed batches list: $batchesList'); // Debug line
          return batchesList;
        } else {
          throw Exception("Response does not contain 'assigned_batches' field");
        }
      } else {
        throw Exception("Unexpected response format: ${data.runtimeType}");
      }
    } else {
      throw Exception(data["error"] ?? "Failed to fetch batches");
    }
  }

  // Helper method to get full batch name from code
  static String _getBatchFullName(String code) {
    switch (code) {
      case 'FYCO':
        return 'First Year Computer Engineering';
      case 'SYCO':
        return 'Second Year Computer Engineering';
      case 'TYCO':
        return 'Third Year Computer Engineering';
      default:
        return code; // Return code if no mapping found
    }
  }

  static Future<Map<String, dynamic>> getStudentCount(String batch) async {
    final url = Uri.parse("$baseUrl/api/students/count?batch=$batch");

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Failed to fetch student count");
    }
  }

  static Future<List<dynamic>> getAssignedCourses(String facultyId) async {
    final url = Uri.parse(
      "$baseUrl/api/faculty/assigned-courses?faculty_id=$facultyId",
    );

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);
    print('Debug: Courses API response: $data'); // Debug line

    if (response.statusCode == 200) {
      if (data is Map<String, dynamic> && data['success'] == true) {
        // Handle the old format: {success: true, data: [...]}
        return data['data'] ?? [];
      } else if (data is List) {
        // Handle the new format: direct array [...]
        return data;
      } else {
        print('Debug: Unexpected response format: ${data.runtimeType} - $data');
        throw Exception(
          "Failed to fetch assigned courses - unexpected response format",
        );
      }
    } else {
      throw Exception(data["error"] ?? "Failed to fetch assigned courses");
    }
  }

  // Get timetable for batch
  static Future<Map<String, dynamic>> getTimetable(String batch) async {
    final url = Uri.parse("http://13.235.16.3:5001/timetable?batch=$batch");

    final response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);
    print('Debug: Timetable API response for $batch: $data'); // Debug line

    if (response.statusCode == 200) {
      if (data is Map<String, dynamic> && data['success'] == true) {
        return data;
      } else {
        throw Exception("Failed to fetch timetable");
      }
    } else {
      throw Exception(data["error"] ?? "Failed to fetch timetable");
    }
  }

  // Get students for lab batch and year from database
  static Future<List<dynamic>> getStudentsForLabBatch({
    required String year, // Changed from batch to year
    required String labBatch,
  }) async {
    // Use the correct endpoint provided by user
    final url = Uri.parse("$baseUrl/students?year=$year&lab_batch=$labBatch");
    
    try {
      print('Debug: Fetching students from database: $url');

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 15));

      print('Debug: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Check if response is HTML (error page)
        if (response.body.toLowerCase().contains('<!doctype') || 
            response.body.toLowerCase().contains('<html')) {
          print('Debug: Received HTML error page');
          throw Exception('Server returned HTML error page instead of JSON');
        }

        final data = jsonDecode(response.body);
        print('Debug: Database response for $year - $labBatch: ${data.runtimeType}');

        // Parse different possible response formats from database
        if (data is Map<String, dynamic>) {
          if (data['success'] == true && data['data'] != null) {
            final students = data['data'] as List<dynamic>;
            print('Debug: Found ${students.length} students from database');
            return students;
          } else if (data.containsKey('students')) {
            final students = data['students'] as List<dynamic>;
            print('Debug: Found ${students.length} students from database');
            return students;
          } else if (data.containsKey('data')) {
            final students = data['data'] as List<dynamic>;
            print('Debug: Found ${students.length} students from database');
            return students;
          }
        } else if (data is List<dynamic>) {
          print('Debug: Found ${data.length} students from database');
          return data;
        }
        
        throw Exception('Unexpected response format from database');
      } else {
        print('Debug: HTTP ${response.statusCode} error from database');
        throw Exception('HTTP ${response.statusCode}: Failed to fetch student data');
      }
    } catch (e) {
      print('Debug: Database connection error: $e');
      throw Exception('Unable to fetch student data from database: $e');
    }
  }
}
