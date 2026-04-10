import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './expense_model.dart';

class ExpenseDetail extends StatelessWidget {
  final ExpenseApply expense;

  const ExpenseDetail({required this.expense, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('費用申請詳情'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 頂部狀態與摘要區塊
            _buildHeaderStatus(),
            const SizedBox(height: 24),

            // 2. 主要資訊卡片 (日期、工號、申請人)
            _buildInfoCard(context),
            const SizedBox(height: 24),

            // 3. 費用說明區塊 (RowData)
            const Text(
              '費用說明',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                expense.rowData ?? '無說明內容',
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),

            // 4. 單據照片預覽區塊 (PicPath)
            const Text(
              '單據照片',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 12),
            _buildImagePreview(context),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 頂部狀態與 ID 顯示
  Widget _buildHeaderStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '單號: ${expense.applyId ?? 'N/A'}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              '費用報支申請',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        // 假設狀態固定為已提交 (可依需求擴充資料表狀態欄位)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '已提交',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // 核心資訊卡片
  Widget _buildInfoCard(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDetailRow(Icons.event, '費用日期', DateFormat('yyyy-MM-dd').format(expense.applyDate)),
            const Divider(height: 30),
            _buildDetailRow(Icons.badge_outlined, '申請人工號', '${expense.empNo} ${expense.personCName}'),
            const Divider(height: 30),
            _buildDetailRow(Icons.category, '費用類別', expense.expCName ?? expense.expId ?? '未分類'),
            const Divider(height: 30),
            _buildDetailRow(Icons.monetization_on, '申請金額', '${expense.expAmt?.toStringAsFixed(2)}'),
            const Divider(height: 30),
            _buildDetailRow(Icons.category, '費用說明', expense.rowData ?? ''),
            const Divider(height: 30),
            _buildDetailRow(Icons.person_pin, '建立者', expense.creatorId ?? '系統'),
            const Divider(height: 30),
            _buildDetailRow(Icons.history, '系統存檔時間',
                expense.createDateTime != null ? df.format(expense.createDateTime!) : 'N/A'),
          ],
        ),
      ),
    );
  }

  // 輔助元件：建立細節列
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey.shade400),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  // 圖片預覽元件
  Widget _buildImagePreview(BuildContext context) {
    if (expense.picPath == null || expense.picPath!.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('無單據照片', style: TextStyle(color: Colors.grey))),
      );
    }

    return GestureDetector(
      onTap: () => _showFullScreenImage(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.grey.shade200,
          child: Image.network(
            expense.fullPicUrl,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
            // [新增] 加載中的轉圈圈
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 250,
                color: Colors.grey.shade100,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            // 處理圖片加載失敗
            errorBuilder: (context, error, stackTrace) {
              print("圖片載入失敗，試圖存取的網址為: ${expense.fullPicUrl}");
              return Container(
                height: 200,
                color: Colors.grey.shade100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image, color: Colors.red, size: 40),
                    const SizedBox(height: 8),
                    Text('無法載入圖片', style: TextStyle(color: Colors.grey.shade600)),
                    Text(expense.picPath ?? "無檔名", style: const TextStyle(fontSize: 10)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 全螢幕查看圖片
  void _showFullScreenImage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
          body: Center(
            child: InteractiveViewer( // 支援手勢縮放
              child: Image.network(expense.fullPicUrl),
            ),
          ),
        ),
      ),
    );
  }
}