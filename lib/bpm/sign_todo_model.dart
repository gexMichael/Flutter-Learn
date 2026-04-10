import 'package:intl/intl.dart';

class SignTodoItem {
  final String functionTag;   // 流程代碼 (uuid)
  final String flowName;      // 流程名稱 (e.g. 請假單)
  final String billNo;        // 單號 (sourceid)
  final String senderId;      // 送單人 ID
  final String senderName;    // 送單人姓名
  final String deptName;      // 部門名稱
  final String stepName;      // 當前關卡名稱
  final String signNote;      // 上一關意見
  final DateTime? createDate; // 送達時間
  final int flowLevel;        // 關卡層級

  SignTodoItem({
    required this.functionTag,
    required this.flowName,
    required this.billNo,
    required this.senderId,
    required this.senderName,
    required this.deptName,
    required this.stepName,
    this.signNote = '',
    this.createDate,
    required this.flowLevel,
  });

  factory SignTodoItem.fromJson(Map<String, dynamic> json) {
    return SignTodoItem(
      functionTag: json['functiontag'] ?? '',
      flowName: json['flow_name'] ?? '未命名流程',
      billNo: json['billno'] ?? '',
      senderId: json['signerid'] ?? '',
      senderName: json['personcname'] ?? '',
      deptName: json['departmentcname'] ?? '',
      stepName: json['stepName'] ?? '',
      signNote: json['sign_note'] ?? '',
      // 處理 SQL 可能回傳的日期字串格式
      createDate: json['create_date'] != null
          ? DateTime.tryParse(json['create_date'].toString().replaceAll('/', '-'))
          : null,
      flowLevel: int.tryParse(json['flow_level']?.toString() ?? '0') ?? 0,
    );
  }

  // 輔助顯示：格式化日期
  String get formattedDate {
    if (createDate == null) return '';
    return DateFormat('yyyy/MM/dd HH:mm').format(createDate!);
  }
}