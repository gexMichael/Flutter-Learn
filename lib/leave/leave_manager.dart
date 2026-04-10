import 'package:flutter/material.dart';
import './leave_model.dart';
import './leave_api.dart';
import './leave_form.dart'; // 稍後定義的新增頁面
import './leave_detail.dart';

class LeaveManager extends StatefulWidget {
  final String currentUserId;
  const LeaveManager({required this.currentUserId, super.key});

  @override
  State<LeaveManager> createState() => _LeaveManagerState();
}

class _LeaveManagerState extends State<LeaveManager> {
  late LeaveApiService _apiService;
  late Future<List<Leave>> _leaveFuture;

  @override
  void initState() {
    super.initState();
    _apiService = LeaveApiService();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _leaveFuture = _apiService.fetchLeaves(widget.currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('請假紀錄')),
      body: FutureBuilder<List<Leave>>(
        future: _leaveFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('尚無請假紀錄'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, i) => _buildLeaveCard(snapshot.data![i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LeaveForm(userId: widget.currentUserId)),
          );
          if (result == true) _refreshList();
        },
        label: const Text('申請請假'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLeaveCard(Leave item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LeaveDetail(leave: item)),
          );
        },
        // title: Text('${item.leaveType} (${item.days}天 ${item.hours}時)'),
        title: Text('${item.leaveTypeName} (${item.days}天 ${item.hours}時)'), // 使用 leaveTypeName
        subtitle: Text(item.formattedRange),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: item.statusColor, borderRadius: BorderRadius.circular(5)),
          child: Text(item.statusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
    );
  }
}