// todo_model.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Todo {
  final int id;
  final String className;       // todolist_class (類別/分類)
  final String taskName;        // task_name (任務名稱/標題)
  final String? description;    // task_desc (詳細說明)
  final String? priority;       // issue_priority (優先級)
  final String? status;         // pbi_status (狀態)
  final DateTime? endDate;      // end_date (預計完成日期)
  final String? createdBy;      // create_user (建立者)
  final DateTime? createDate;   // create_date (建立日期)
  final String? updatedBy;      // update_user (更新者) - 配合新 Schema 新增
  final DateTime? updateDate;   // update_date (更新日期) - 配合新 Schema 新增

  Todo({
    required this.id,
    required this.className,
    required this.taskName,
    this.description,
    this.priority,
    this.status,
    this.endDate,
    this.createdBy,
    this.createDate,
    this.updatedBy,
    this.updateDate,
  });

  // Factory 構造函數：從 API 返回的 JSON (Map) 創建 Todo 物件
  factory Todo.fromJson(Map<String, dynamic> json) {
    // 輔助函數：安全解析日期字串
    DateTime? parseDate(dynamic date) {
      if (date is String && date.isNotEmpty) {
        return DateTime.tryParse(date);
      }
      return null;
    }

    return Todo(
      id: json['id'] as int? ?? 0,
      className: json['todolist_class'] as String? ?? '未分類',
      taskName: json['task_name'] as String? ?? '無任務標題',
      description: json['task_desc'] as String?,
      priority: json['issue_priority'] as String?,
      status: json['pbi_status'] as String?,
      endDate: parseDate(json['end_date']),
      createdBy: json['create_user'] as String?,
      createDate: parseDate(json['create_date']),
      updatedBy: json['update_user'] as String?,
      updateDate: parseDate(json['update_date']),
    );
  }

  // 格式化日期，用於列表顯示
  String get formattedEndDate {
    if (endDate == null) return 'N/A';
    return DateFormat('yyyy/MM/dd').format(endDate!);
  }

  // 根據狀態獲取顏色 (例如：已完成/進行中)
  Color get statusColor {
    switch (status?.toUpperCase()) {
      case 'WIP': // Work In Progress
        return Colors.blue;
      case 'DONE': // Completed
        return Colors.green;
      case 'HOLD': // On Hold
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}