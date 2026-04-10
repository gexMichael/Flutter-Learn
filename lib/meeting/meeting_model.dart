import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Meeting {
  final int uniqueNo;          // uniqueno (Primary Key)
  final String meetingTitle;   // meeting_title (會議標題)
  final String? meetingPlace;  // meeting_place (會議地點)
  final String? meetingDesc;   // meeting_desc (會議說明)
  final String? bossPersonId;  // boss_personid (主持人 ID)
  final String? recPersonId;   // rec_personid (記錄人 ID)
  final DateTime? startDate;   // startdate (開始日期)
  final String? startTime;     // starttime (開始時間, e.g., '14:00')
  final DateTime? endDate;     // end_date (結束日期)
  final String? endTime;       // end_time (結束時間, e.g., '16:00')
  final String? resolution;    // meeting_resolution (會議決議)
  final String? meetingUsers;  // meeting_users (參與者名單)
  final String? flowFlag;      // flowflag (狀態/流程旗標)

  Meeting({
    required this.uniqueNo,
    required this.meetingTitle,
    this.meetingPlace,
    this.meetingDesc,
    this.bossPersonId,
    this.recPersonId,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.resolution,
    this.meetingUsers,
    this.flowFlag,
  });

  // Factory 構造函數：從 API 返回的 JSON (Map) 創建 Meeting 物件
  factory Meeting.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) {
      if (date is String && date.isNotEmpty) {
        // 假設日期格式為 YYYY-MM-DD HH:mm:ss.sss 或 YYYY-MM-DD
        return DateTime.tryParse(date);
      }
      return null;
    }

    return Meeting(
      uniqueNo: json['uniqueno'] as int? ?? 0,
      meetingTitle: json['meeting_title'] as String? ?? '無標題會議',
      meetingPlace: json['meeting_place'] as String?,
      meetingDesc: json['meeting_desc'] as String?,
      bossPersonId: json['boss_personid'] as String?,
      recPersonId: json['rec_personid'] as String?,
      startDate: parseDate(json['startdate']),
      startTime: json['starttime'] as String?,
      endDate: parseDate(json['end_date']),
      endTime: json['end_time'] as String?,
      resolution: json['meeting_resolution'] as String?,
      meetingUsers: json['meeting_users'] as String?,
      flowFlag: json['flowflag'] as String?,
    );
  }

  // Helper: 格式化開始日期和時間
  String get formattedStartDateTime {
    if (startDate == null) return 'N/A';
    final datePart = DateFormat('MM/dd').format(startDate!);
    final timePart = startTime ?? '';
    return '$datePart ${timePart.isNotEmpty ? timePart : ''}'.trim();
  }

  // Helper: 獲取會議狀態顏色
  Color get statusColor {
    // 假設 '1' 表示已定案/已批准, '0' 表示審核中, 其他表示草稿/待開始
    switch (flowFlag) {
      case '1':
        return Colors.green; // 已定案
      case '0':
        return Colors.orange; // 審核中
      default:
        return Colors.blue; // 待開始
    }
  }

  // Helper: 獲取會議狀態文字
  String get statusText {
    switch (flowFlag) {
      case '1':
        return '已定案';
      case '0':
        return '審核中';
      default:
        return '待開始';
    }
  }
}