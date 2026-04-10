import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarEvent {
  final String uuid;
  final String title;
  final String? description;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? type;      // cal_type
  final String? level;     // cal_level (重要程度)
  final String? personId;
  final bool isFinished;   // cal_finished: 'Y' or 'N'
  final String? repeatedFlag; // cal_repeated_flag
  final String? projectId;

  CalendarEvent({
    required this.uuid,
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.type,
    this.level,
    this.personId,
    this.isFinished = false,
    this.repeatedFlag,
    this.projectId,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      uuid: json['uuid'] as String,
      title: json['title'] as String? ?? '未命名行程',
      description: json['cal_description'] as String?,
      startTime: json['start_time'] != null ? DateTime.tryParse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time']) : null,
      type: json['cal_type'] as String?,
      level: json['cal_level'] as String?,
      personId: json['personid'] as String?,
      isFinished: json['cal_finished'] == 'Y',
      repeatedFlag: json['cal_repeated_flag'] as String?,
      projectId: json['projectid'] as String?,
    );
  }

  // UI 輔助屬性
  Color get levelColor {
    switch (level?.toUpperCase()) {
      case 'URGENT': return Colors.red;
      case 'HIGH': return Colors.orange;
      case 'NORMAL': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String get timeRangeText {
    if (startTime == null) return "未定時";
    final df = DateFormat('HH:mm');
    return "${df.format(startTime!)}${endTime != null ? ' - ${df.format(endTime!)}' : ''}";
  }
}