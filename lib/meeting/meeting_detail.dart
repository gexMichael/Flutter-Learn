import 'package:flutter/material.dart';
import './meeting_model.dart';
import 'package:intl/intl.dart';

class MeetingDetail extends StatelessWidget {
  final Meeting meeting;

  const MeetingDetail({required this.meeting, super.key});

  // 輔助函式：建立屬性列 (從 todo_detail.dart 最佳化而來)
  Widget _buildAttributeRow(BuildContext context, String label, String value, {Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // 輔助函式：格式化日期時間範圍
  String _formatDateRange() {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final startDateStr = meeting.startDate != null ? dateFormat.format(meeting.startDate!) : 'N/A';
    final endDateStr = meeting.endDate != null ? dateFormat.format(meeting.endDate!) : startDateStr;

    // 檢查日期是否相同
    final isSameDate = meeting.startDate != null && meeting.endDate != null &&
        meeting.startDate!.day == meeting.endDate!.day &&
        meeting.startDate!.month == meeting.endDate!.month &&
        meeting.startDate!.year == meeting.endDate!.year;

    String dateRange;
    if (isSameDate) {
      dateRange = startDateStr;
    } else {
      dateRange = '$startDateStr 至 $endDateStr';
    }

    final timeRange = '${meeting.startTime ?? ''} ~ ${meeting.endTime ?? ''}';
    return '$dateRange ${timeRange.trim()}';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(meeting.meetingTitle, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 會議標題
            Text(
              meeting.meetingTitle,
              style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Divider(height: 24.0),

            // 會議屬性表格
            _buildAttributeRow(context, '狀態', meeting.statusText, color: meeting.statusColor),
            _buildAttributeRow(context, '地點', meeting.meetingPlace ?? '待定'),
            _buildAttributeRow(context, '時間範圍', _formatDateRange(), color: Colors.blue),
            _buildAttributeRow(context, '主持人 ID', meeting.bossPersonId ?? 'N/A'),
            _buildAttributeRow(context, '記錄人 ID', meeting.recPersonId ?? 'N/A'),
            _buildAttributeRow(context, '參與者名單', meeting.meetingUsers ?? '無'),

            const Divider(height: 32.0),

            // 會議說明
            const Text(
              '會議說明:',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              meeting.meetingDesc ?? '無詳細說明。',
              style: const TextStyle(fontSize: 16.0, height: 1.5, color: Colors.black54),
              textAlign: TextAlign.justify,
            ),

            const Divider(height: 32.0),

            // 會議決議
            const Text(
              '會議決議:',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              meeting.resolution ?? '無決議事項。',
              style: const TextStyle(fontSize: 16.0, height: 1.5, color: Colors.black54),
              textAlign: TextAlign.justify,
            ),

            const SizedBox(height: 40),

            // 底部按鈕 (範例：下載文件)
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('待實作下載會議文件功能。')),
                  );
                },
                icon: const Icon(Icons.file_download),
                label: const Text('下載會議文件'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}