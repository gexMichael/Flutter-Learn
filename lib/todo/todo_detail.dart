import 'package:flutter/material.dart';
import './todo_model.dart';
import './todo_api.dart';

class TodoDetail extends StatefulWidget {
  final Todo todo;

  const TodoDetail({required this.todo, super.key});

  @override
  State<TodoDetail> createState() => _TodoDetailState();
}

class _TodoDetailState extends State<TodoDetail> {
  final TodoApiService _apiService = TodoApiService();
  bool _isUpdating = false; // 控制按鈕 Loading 狀態

  // 執行「標記為完成」的 API 邏輯
  Future<void> _handleMarkAsDone() async {
    setState(() => _isUpdating = true);

    // 呼叫 API 更新 pbi_status 為 'DONE'
    bool success = await _apiService.updateTodoStatus(widget.todo.id, 'DONE');

    if (mounted) {
      setState(() => _isUpdating = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('任務 "${widget.todo.taskName}" 已完成！')),
        );
        // 重要：返回 true 告知列表頁 (TodoManager) 執行 _refreshTodos()
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('狀態更新失敗，請檢查網路連線。'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 檢查目前狀態是否已為 DONE
    bool isCompleted = widget.todo.status?.toUpperCase() == 'DONE';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('任務詳情', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題與分類卡片
            _buildHeaderCard(),
            const SizedBox(height: 24),

            // 詳細屬性清單
            const Text('詳細資訊', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 12),
            _buildInfoCard(),
            const SizedBox(height: 24),

            // 任務描述
            const Text('任務說明', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 12),
            _buildDescriptionBox(),
            const SizedBox(height: 40),

            // 操作按鈕
            _buildActionButton(isCompleted),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF0EFFF), borderRadius: BorderRadius.circular(8)),
                child: Text(widget.todo.className, style: const TextStyle(color: Color(0xFF6542D0), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const Spacer(),
              Text(widget.todo.priority ?? '一般', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.todo.taskName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildDetailRow(Icons.calendar_today, '截止日期', widget.todo.formattedEndDate),
          const Divider(height: 32),
          _buildDetailRow(Icons.person_outline, '建立者', widget.todo.createdBy ?? '系統'),
          const Divider(height: 32),
          _buildDetailRow(Icons.info_outline, '目前狀態', widget.todo.status ?? 'WIP', color: widget.todo.statusColor),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color ?? Colors.black87)),
      ],
    );
  }

  Widget _buildDescriptionBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Text(
        widget.todo.description ?? '尚無詳細說明。',
        style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.6),
      ),
    );
  }

  Widget _buildActionButton(bool isCompleted) {
    if (isCompleted) {
      return Center(
        child: Column(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            SizedBox(height: 8),
            Text('此任務已圓滿完成', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : _handleMarkAsDone,
        icon: _isUpdating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.check_circle_outline),
        label: Text(_isUpdating ? '正在更新狀態...' : '標記為已完成', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      ),
    );
  }
}