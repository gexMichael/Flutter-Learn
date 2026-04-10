import 'package:flutter/material.dart';

// 通用的佔位畫面
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title 功能正在開發中...',
          style: const TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );
  }
}

// 各功能頁面 (繼承自 PlaceholderScreen，方便未來替換成真實頁面)
class AttendanceScreen extends PlaceholderScreen {
  const AttendanceScreen({super.key}) : super(title: '員工打卡');
}

class ApprovalScreen extends PlaceholderScreen {
  const ApprovalScreen({super.key}) : super(title: '待簽核事項');
}

class TodoScreen extends PlaceholderScreen {
  const TodoScreen({super.key}) : super(title: '待辦事項');
}

class CalendarScreen extends PlaceholderScreen {
  const CalendarScreen({super.key}) : super(title: '行事曆');
}