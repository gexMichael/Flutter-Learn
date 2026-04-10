import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'leave_api.dart';

// 假別模型 260110
class LeaveType {
  final String id;
  final String name;

  LeaveType({required this.id, required this.name});

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['leavetype_id'] as String,
      name: json['leavetype_name'] as String,
    );
  }
}

// 簽核進度模型
class FlowLog {
  final String stepName;
  final String approverName;
  final String status; // 1:同意, X:駁回, 0:待審
  final DateTime? time;

  FlowLog({required this.stepName, required this.approverName, required this.status, this.time});
}

class Leave {
  final String billNo;       // billno (Primary Key)
  final DateTime? billDate;  // billdate
  final String personId;     // personid
  final String agentId;      // agentid (代理人)
  final String agentName;       /// 關聯顯示
  final String leaveType;    // leavetype (假別：事假、病假等)
  final String leaveTypeName;   /// 顯示名稱
  final DateTime? startTime; // starttime
  final DateTime? endTime;   // endtime
  final double days;         // days
  final double hours;        // hours
  final String? leaveNote;   // leave_note
  final String? flowStatus;  // flow_status (0:草稿, 1:審核中, 2:已核准, X:駁回)

  Leave({
    required this.billNo,
    this.billDate,
    required this.personId,
    required this.agentId,
    required this.agentName,
    required this.leaveType,
    required this.leaveTypeName,
    this.startTime,
    this.endTime,
    this.days = 0,
    this.hours = 0,
    this.leaveNote,
    this.flowStatus,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    // 取的假別關聯名稱
    final String typeId = json['leavetype'] as String? ?? '';

    // 自動映射名稱：若 API 有給就用 API 的，沒有就去 Service 快取找
    final String typeName = json['leavetype_name'] ?? LeaveApiService.getTypeName(typeId);

    return Leave(
      billNo: json['billno'] as String? ?? '',
      billDate: json['billdate'] != null ? DateTime.tryParse(json['billdate']) : null,
      personId: json['personid'] as String? ?? '',
      agentId: json['agentid'] as String? ?? '',
      agentName: json['agentName'] ?? '', /// 假設 API 會 Join 姓名
      leaveType: json['leavetype'] as String? ?? '',
      // leaveTypeName: json['leavetype_name'] ?? json['leavetype'] ?? '',
      leaveTypeName: typeName, // 這裡現在保證有值
      startTime: json['starttime'] != null ? DateTime.tryParse(json['starttime']) : null,
      endTime: json['endtime'] != null ? DateTime.tryParse(json['endtime']) : null,
      days: double.tryParse(json['days']?.toString() ?? '0') ?? 0,
      hours: double.tryParse(json['hours']?.toString() ?? '0') ?? 0,
      leaveNote: json['leave_note'] as String?,
      flowStatus: json['flow_status'] as String?,
    );
  }

  // 格式化顯示
  String get formattedRange {
    if (startTime == null || endTime == null) return '時間未定';
    final df = DateFormat('yyyy/MM/dd HH:mm');
    return '${df.format(startTime!)} ~ ${df.format(endTime!)}';
  }

  /*
  -- [sign_status] [varchar](2) not null,    -- N:待簽核 P:簽核中 R:拒絶 A:同意 C:作廢
  -- [flow_status] [varchar](2) not null,    -- N:待簽核 P:簽核中 Z:結案 C:作廢
  */
  // 狀態顏色映射
  Color get statusColor {
    switch (flowStatus) {
      case 'N': return Colors.blue;   // 待簽核
      case 'P': return Colors.orange; // 審核中
      case 'A': return Colors.green;  // 同意
      case 'R': return Colors.red;    // 駁回
      case 'C': return Colors.black;  // 作廢
      case 'Z': return Colors.purple; // 結案
      default: return Colors.grey;    // 草稿
    }
  }

  String get statusText {
    switch (flowStatus) {
      case 'N': return '待簽核';
      case 'P': return '審核中';
      case 'A': return '同意';
      case 'R': return '駁回';
      case 'C': return '作廢';
      case 'Z': return '結案';
      default: return '草稿';
    }
  }
}