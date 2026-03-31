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

  static Future<Map<String, dynamic>> createSession(String facultyId) async {
    final url = Uri.parse("$baseUrl/sessions/create");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"course_code": "IP", "faculty_id": facultyId}),
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
}
