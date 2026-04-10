import 'package:flutter/material.dart';
import './calendar_model.dart';

class CalendarDetail extends StatelessWidget {
  final CalendarEvent event;

  const CalendarDetail({required this.event, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('行程詳情')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: event.levelColor, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Text(event.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 40),
          _buildDetailItem(Icons.access_time, '時間範圍', event.timeRangeText),
          _buildDetailItem(Icons.repeat, '重複設定', event.repeatedFlag ?? '無重複'),
          _buildDetailItem(Icons.folder_open, '關聯專案', event.projectId ?? '無相關專案'),
          _buildDetailItem(Icons.category_outlined, '類型', event.type ?? '一般行程'),
          const SizedBox(height: 24),
          const Text('行程描述', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Text(event.description ?? '無詳細描述內容', style: const TextStyle(height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}