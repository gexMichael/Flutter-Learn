import 'package:flutter/material.dart';
import './issue_model.dart';
import 'package:intl/intl.dart';

class IssueDetail extends StatelessWidget {
  final Issue issue;

  const IssueDetail({required this.issue, super.key});

  // 輔助函式：建立屬性列
  Widget _buildAttributeRow(BuildContext context, String label, String? value, {Color color = Colors.black}) {
    // 處理日期欄位
    String displayValue = value ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // 輔助函式：格式化日期時間
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }


  @override
  Widget build(BuildContext context) {
    // 完整描述 (Model中可能被截斷，這裡使用原始欄位)
    final fullDescription = issue.description ?? '無詳細描述。';
    final hasSolution = issue.solution != null && issue.solution!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('問題 #${issue.issueId}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 標題與 ID
            Text(
              '問題 ID: #${issue.issueId}',
              style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87),
            ),

            const Divider(height: 24.0),

            // 核心屬性
            _buildAttributeRow(context, '狀態', issue.statusText, color: issue.statusColor),
            _buildAttributeRow(context, '優先級', issue.priority, color: issue.priorityColor),
            _buildAttributeRow(context, '預計完成日', issue.formattedExpectedDate, color: Colors.blue),
            _buildAttributeRow(context, '指派對象', issue.responsible),
            _buildAttributeRow(context, '提出人', issue.raisedBy),
            _buildAttributeRow(context, '專案 ID', issue.projectId),
            _buildAttributeRow(context, '功能碼', issue.functionCode),
            _buildAttributeRow(context, '提出時間', _formatDateTime(issue.raisedDate)),
            _buildAttributeRow(context, '解決說明', hasSolution ? '詳見下方' : '尚未解決', color: hasSolution ? Colors.green : Colors.red),

            const Divider(height: 32.0),

            // 問題詳細描述
            const Text(
              '問題描述 (Issue Description):',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                fullDescription,
                style: const TextStyle(fontSize: 16.0, height: 1.5, color: Colors.black87),
                textAlign: TextAlign.justify,
              ),
            ),

            const Divider(height: 32.0),

            // 解決說明/備註
            Text(
              '解決說明 (Solution Explanation):',
              style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  color: hasSolution ? Colors.black87 : Colors.grey.shade500
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: hasSolution ? Colors.lightGreen.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: hasSolution ? Colors.green.shade200 : Colors.transparent)
              ),
              child: Text(
                issue.solution ?? '尚無解決說明或備註。',
                style: TextStyle(
                    fontSize: 16.0,
                    height: 1.5,
                    color: hasSolution ? Colors.black87 : Colors.grey.shade600
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 40),

            // 底部按鈕
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('待實作處理問題流程（例如：變更狀態）。')),
                  );
                },
                icon: const Icon(Icons.build),
                label: const Text('處理問題'),
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