import 'package:flutter/material.dart';

class Course {
  final String batch;
  final String courseName;
  final String? labBatch;
  final String sessionType;

  Course({
    required this.batch,
    required this.courseName,
    this.labBatch,
    required this.sessionType,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      batch: json['batch'] ?? '',
      courseName: json['course_name'] ?? '',
      labBatch: json['lab_batch'],
      sessionType: json['session_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch': batch,
      'course_name': courseName,
      'lab_batch': labBatch,
      'session_type': sessionType,
    };
  }

  String get displaySessionType {
    if (sessionType.toUpperCase() == 'LAB') {
      return 'Lab';
    } else if (sessionType.toUpperCase() == 'LECTURE') {
      return 'Theory';
    }
    return sessionType;
  }

  String get displayBatchInfo {
    if (sessionType.toUpperCase() == 'LAB' && labBatch != null) {
      return labBatch!;
    } else if (sessionType.toUpperCase() == 'LECTURE') {
      return 'Full Batch';
    }
    return batch;
  }

  Color get labBatchColor {
    if (labBatch != null) {
      switch (labBatch!.toUpperCase()) {
        case 'C1':
          return const Color(0xFF4CAF50); // Green
        case 'C2':
          return const Color(0xFF2196F3); // Blue
        case 'C3':
          return const Color(0xFFFF9800); // Orange
        case 'C4':
          return const Color(0xFF9C27B0); // Purple
        default:
          return const Color(0xFF607D8B); // Blue Grey
      }
    }
    return const Color(0xFF607D8B);
  }
}
