import 'package:flutter/material.dart';
import './sign_todo_model.dart';
import './sign_todo_api.dart';

class SignTodoManager extends StatefulWidget {
  const SignTodoManager({super.key});

  @override
  State<SignTodoManager> createState() => _SignTodoManagerState();
}

class _SignTodoManagerState extends State<SignTodoManager> {
  final SignTodoApiService _apiService = SignTodoApiService();
  late Future<List<SignTodoItem>> _todoFuture;

  // 用於處理簽核中的 loading 狀態 (避免重複點擊)
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _todoFuture = _apiService.fetchSignTodos();
    });
  }

  // 處理簽核動作 (彈出對話框 -> 呼叫 API -> 更新列表)
  Future<void> _handleSignAction(BuildContext context, SignTodoItem item, String type) async {
    final isAgree = type == 'A';
    final actionText = isAgree ? '同意' : '駁回';
    final TextEditingController noteController = TextEditingController();

    // 預設意見
    if (isAgree) noteController.text = '同意';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionText簽核'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('單號: ${item.billNo}'),
            Text('申請人: ${item.senderName}'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: '簽核意見',
                hintText: isAgree ? '請輸入意見(可選)' : '駁回請務必輸入原因',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              // 駁回時強制要求填寫意見 (這裡可依需求調整)
              if (!isAgree && noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('駁回時請填寫原因')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAgree ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('確認$actionText'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);

      final success = await _apiService.executeSign(
        type: type,
        uuid: item.functionTag,
        billNo: item.billNo,
        note: noteController.text,
      );

      setState(() => _isProcessing = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('單號 ${item.billNo} 已$actionText')),
          );
          _refreshList(); // 成功後刷新列表
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('簽核失敗，請稍後再試')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('待簽核事項')),
      body: Stack(
        children: [
          FutureBuilder<List<SignTodoItem>>(
            future: _todoFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('載入失敗: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final items = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), // 預留空間
                itemCount: items.length,
                itemBuilder: (ctx, i) => _buildSignCard(items[i]),
              );
            },
          ),
          // 全域 Loading 遮罩 (當執行簽核動作時)
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshList,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('目前沒有待簽核事項', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSignCard(SignTodoItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: 流程名稱與單號
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(item.flowName),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  item.formattedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Content: 申請人與資訊
            Text(
              '${item.deptName} - ${item.senderName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('單號: ${item.billNo}', style: const TextStyle(color: Colors.black87)),
            Text('目前關卡: ${item.stepName}', style: const TextStyle(color: Colors.black54)),
            if (item.signNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('上關意見: ${item.signNote}', style: const TextStyle(fontSize: 12)),
              ),
            ],

            const Divider(height: 24),

            // Actions: 同意與駁回按鈕
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleSignAction(context, item, 'R'),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('駁回', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleSignAction(context, item, 'A'),
                    icon: const Icon(Icons.check),
                    label: const Text('同意'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}