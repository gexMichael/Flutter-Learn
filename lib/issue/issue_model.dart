import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Issue {
  final int issueId;           // issueid (Primary Key)
  final String? projectId;     // projectid
  final String? functionCode;  // functioncode
  final String? description;   // issue_description
  final String? priority;      // issue_priority (High, Medium, Low)
  final int? status;          // issue_status (1=New, 2=InProgress, 3=Resolved, 4=Closed)
  final String? raisedBy;      // raised_by
  final String? responsible;   // responsible
  final DateTime? raisedDate;  // raised_date
  final DateTime? expectedDate; // excepted_date
  final String? solution;      // solution_explanation

  Issue({
    required this.issueId,
    this.projectId,
    this.functionCode,
    this.description,
    this.priority,
    this.status,
    this.raisedBy,
    this.responsible,
    this.raisedDate,
    this.expectedDate,
    this.solution,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) {
      if (date is String && date.isNotEmpty) {
        return DateTime.tryParse(date);
      }
      return null;
    }

    // 由於 issue_priority 是 VARCHAR，我們假設它直接就是 'High', 'Medium', 'Low'
    // 或是一個代號，此處保留為 String
    final rawPriority = json['issue_priority'] as String?;

    // 假設 issue_description 欄位是問題標題/簡述
    final rawDescription = json['issue_description'] as String?;

    final descriptionLength = rawDescription?.length ?? 0;
    final truncatedDescription = (descriptionLength > 50)
        ? '${rawDescription!.substring(0, 50)}...' // 列表截斷
        : rawDescription;

    return Issue(
      issueId: json['issueid'] as int? ?? 0,
      projectId: json['projectid'] as String?,
      functionCode: json['functioncode'] as String?,
      description: truncatedDescription, // 使用修正後的變數
      priority: rawPriority,
      status: json['issue_status'] as int?,
      raisedBy: json['raised_by'] as String?,
      responsible: json['responsible'] as String?,
      raisedDate: parseDate(json['raised_date']),
      expectedDate: parseDate(json['excepted_date']),
      solution: json['solution_explanation'] as String?,
    );
  }

  // Helper: 格式化預計完成日期
  String get formattedExpectedDate {
    if (expectedDate == null) return 'N/A';
    return DateFormat('yyyy/MM/dd').format(expectedDate!);
  }

  // Helper: 獲取狀態文字
  String get statusText {
    switch (status) {
      case 1:
        return '新建';
      case 2:
        return '進行中';
      case 3:
        return '已解決';
      case 4:
        return '已結案';
      default:
        return '未知';
    }
  }

  // Helper: 獲取狀態顏色
  Color get statusColor {
    switch (status) {
      case 1:
        return Colors.red; // 新建
      case 2:
        return Colors.orange; // 進行中
      case 3:
        return Colors.blue; // 已解決
      case 4:
        return Colors.green; // 已結案
      default:
        return Colors.grey;
    }
  }

  // Helper: 獲取優先級圖示
  IconData get priorityIcon {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Icons.arrow_upward;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.sort;
    }
  }

  // Helper: 獲取優先級顏色
  Color get priorityColor {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red.shade700;
      case 'medium':
        return Colors.orange.shade700;
      case 'low':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }
}