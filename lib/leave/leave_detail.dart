import 'package:flutter/material.dart';
import './leave_model.dart';
import './leave_api.dart';

class LeaveDetail extends StatefulWidget {
  final Leave leave;
  const LeaveDetail({required this.leave, super.key});

  @override
  State<LeaveDetail> createState() => _LeaveDetailState();
}

class _LeaveDetailState extends State<LeaveDetail> {
  final LeaveApiService _apiService = LeaveApiService();
  bool _isPromoting = false;

  // 實作上呈邏輯
  Future<void> _handlePromote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認上呈'),
        content: const Text('您確定要將此張請假單上呈簽核嗎？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消', style: TextStyle(color: Colors.grey))
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('確定上呈', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isPromoting = true);

      final success = await _apiService.promoteLeave(
          widget.leave.personId,
          widget.leave.billNo
      );

      setState(() => _isPromoting = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已成功上呈單據'),
              backgroundColor: Colors.green,
            )
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leave = widget.leave;
    return Scaffold(
      appBar: AppBar(title: const Text('請假單詳情')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderStatus(),
            const SizedBox(height: 24),
            _buildInfoCard(context),
            const SizedBox(height: 24),

            // 簽核進度區塊
            const Text('簽核進度', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            _buildSignHistoryTable(),
            const SizedBox(height: 24),

            if (leave.flowStatus == '0' || leave.flowStatus == '1')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isPromoting ? null : _handlePromote,
                  icon: _isPromoting
                      ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                  )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isPromoting ? '上呈處理中...' : '上呈申請'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('單號: ${widget.leave.billNo}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(widget.leave.leaveTypeName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
        Chip(
          backgroundColor: widget.leave.statusColor.withOpacity(0.1),
          side: BorderSide(color: widget.leave.statusColor),
          label: Text(widget.leave.statusText, style: TextStyle(color: widget.leave.statusColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    String displayAgent = '${widget.leave.agentId} ${widget.leave.agentName}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDetailRow(Icons.calendar_month, '請假期間', widget.leave.formattedRange),
            const Divider(height: 30),
            _buildDetailRow(Icons.timer_outlined, '請假時數', '${widget.leave.days} 天 ${widget.leave.hours} 小時'),
            const Divider(height: 30),
            _buildDetailRow(Icons.person_outline, '代理人', displayAgent),
            const Divider(height: 30),
            _buildDetailRow(Icons.edit_note, '事由', widget.leave.leaveNote ?? '未填寫'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueAccent),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ],
    );
  }

  // ===== 簽核進度 Table (精準對接 SP 欄位) =====
  Widget _buildSignHistoryTable() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _apiService.fetchSignHistory(widget.leave.billNo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
            child: const Text('尚無簽核歷程', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          );
        }

        final logs = snapshot.data!;

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            // 設定各欄位的寬度比例：意見欄位給予最大空間
            columnWidths: const {
              0: FlexColumnWidth(2.0), // 簽核人
              1: FlexColumnWidth(2.0), // 狀態
              2: FlexColumnWidth(3.0), // 意見
              3: FlexColumnWidth(2.5), // 時間
            },
            children: [
              // 表頭列
              TableRow(
                decoration: BoxDecoration(color: Colors.blueGrey.shade50),
                children: [
                  _buildTableCell('簽核人', isHeader: true),
                  _buildTableCell('狀態', isHeader: true),
                  _buildTableCell('意見', isHeader: true),
                  _buildTableCell('時間', isHeader: true),
                ],
              ),
              // 動態產生資料列，對接 SP 欄位
              ...logs.map((log) {
                final approver = log['personcname']?.toString() ?? '-';
                final statusName = log['sign_status_name']?.toString() ?? '-';
                final note = log['sign_note']?.toString() ?? '';
                final timeStr = log['create_date']?.toString() ?? '';

                // 簡單判斷狀態文字來給予顏色提示 (依照中文涵義)
                Color statusColor = Colors.black87;
                if (statusName.contains('同意') || statusName.contains('核准')) {
                  statusColor = Colors.green;
                } else if (statusName.contains('駁回') || statusName.contains('拒絕')) {
                  statusColor = Colors.red;
                } else if (statusName.contains('待簽')) {
                  statusColor = Colors.orange;
                }

                // 處理時間格式，如果為 yyyy-MM-dd HH:mm:ss 則截取 MM-dd HH:mm 以節省空間
                String displayTime = timeStr;
                if (displayTime.length >= 16) {
                  // 如果前面有年份(例如: 2026-03-04)，可視需求決定要不要擷取 substring(5, 16)
                  displayTime = displayTime.substring(5, 16);
                }

                return TableRow(
                  children: [
                    _buildTableCell(approver),
                    _buildTableCell(statusName, textColor: statusColor),
                    _buildTableCell(note.isEmpty ? '-' : note),
                    _buildTableCell(displayTime),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // 表格單元格的小元件
  Widget _buildTableCell(String text, {bool isHeader = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: textColor ?? (isHeader ? Colors.blueGrey.shade700 : Colors.black87),
          fontSize: 13,
        ),
      ),
    );
  }
}