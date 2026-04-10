import 'package:intl/intl.dart';

class Announcement {
  final int uniqueNo;
  final String title; // bbs_title
  final String description; // bbs_desc (詳細內容)
  final String createdBy; // create_user (作者)
  final DateTime billDate; // billdate (發布日期)
  final DateTime startDate; // startdate
  final DateTime endDate; // end_date
  final String? attachment; // bbs_attach
  final String personCName; // 姓名

  Announcement({
    required this.uniqueNo,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.billDate,
    required this.startDate,
    required this.endDate,
    this.attachment,
    required this.personCName,
  });

  // Factory 構造函數：從 API 返回的 JSON (Map) 創建 Announcement 物件
  factory Announcement.fromJson(Map<String, dynamic> json) {
    // 輔助函數：安全解析日期字串
    DateTime? parseDate(dynamic date) {
      if (date is String && date.isNotEmpty) {
        // 假設日期格式為 YYYY-MM-DD HH:mm:ss.sss
        return DateTime.tryParse(date);
      }
      return DateTime.now(); // 預設為當前時間或您可以選擇 null
    }

    return Announcement(
      uniqueNo: json['uniqueno'] as int? ?? 0,
      title: json['bbs_title'] as String? ?? '無標題',
      description: json['bbs_desc'] as String? ?? '無詳細內容',
      createdBy: json['create_user'] as String? ?? '未知作者',
      billDate: parseDate(json['billdate'])!,
      startDate: parseDate(json['startdate'])!,
      endDate: parseDate(json['end_date'])!,
      attachment: json['bbs_attach'] as String?,
      personCName: json['personCName'] as String,
    );
  }

  // 格式化日期，用於列表顯示
  String get formattedBillDate {
    return DateFormat('yyyy/MM/dd HH:mm').format(billDate);
  }
}