import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EipMessage {
  final int id;             // id (Primary Key)
  final String sender;      // sender (發件人)
  final String receivers;   // receivers (收件人)
  final String subjectLine; // subject_line (主旨)
  final String msgContent;  // msg_content (內容)
  final String msgStatus;   // msg_status (閱讀狀態)
  final DateTime? createDate; // create_date (通知日期)

  EipMessage({
    required this.id,
    this.sender = '',
    this.receivers = '',
    this.subjectLine = '',
    this.msgContent = '',
    this.msgStatus = '0',
    this.createDate,
  });

  factory EipMessage.fromJson(Map<String, dynamic> json) {
    return EipMessage(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      sender: json['sender'] as String? ?? '系統通知',
      receivers: json['receivers'] as String? ?? '',
      subjectLine: json['subject_line'] as String? ?? '無主旨',
      msgContent: json['msg_content'] as String? ?? '',
      msgStatus: json['msg_status'] as String? ?? '0',
      createDate: json['create_date'] != null ? DateTime.tryParse(json['create_date']) : null,
    );
  }

  // 格式化顯示通知日期
  String get formattedDate {
    if (createDate == null) return '未知時間';
    final df = DateFormat('yyyy/MM/dd HH:mm');
    return df.format(createDate!);
  }

  // 判斷是否已讀 (假設 '1' 為已讀，'0' 為未讀)
  bool get isRead => msgStatus == '1';

  // 狀態視覺呈現
  Color get statusColor => isRead ? Colors.grey : Colors.blueAccent;
  String get statusText => isRead ? '已讀' : '未讀';
}