import 'package:flutter/material.dart';
// 1. 必須加入這一行，否則系統不認識 launchUrl
import 'package:url_launcher/url_launcher.dart';
import './person_model.dart';

class PersonDetail extends StatelessWidget {
  final Person person;

  const PersonDetail({required this.person, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(person.personCName ?? '人員詳細資訊'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 50,
              // 修正 .withOpacity 警告，改用新的 .withValues
              backgroundColor: person.sexColor.withValues(alpha: 0.2),
              child: Icon(person.sexIcon, size: 60, color: person.sexColor),
            ),
            const SizedBox(height: 10),
            Text(
              person.personCName ?? 'N/A',
              style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Text(
              person.jobName ?? 'N/A',
              style: const TextStyle(fontSize: 18.0, color: Colors.black54),
            ),
            const Divider(height: 30.0, thickness: 1),

            _buildInfoTile(Icons.badge, '工號 / ID', person.personId),
            _buildInfoTile(Icons.business, '部門代號', person.departmentId ?? 'N/A'),
            _buildActionTile(context, Icons.phone, '公司電話', person.tel ?? 'N/A', person.tel, 'tel:'),
            _buildActionTile(context, Icons.smartphone, '手機號碼', person.cellphone ?? 'N/A', person.cellphone, 'tel:'),
            _buildActionTile(context, Icons.email, '電子郵件', person.email ?? 'N/A', person.email, 'mailto:'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700], size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
      BuildContext context, IconData icon, String label, String displayValue,
      String? actionValue, String protocol) {
    final canLaunch = actionValue != null && actionValue.isNotEmpty;

    // 修正點：在 StatelessWidget 中我們不使用 mounted，直接處理即可
    Future<void> _handleLaunch() async {
      if (canLaunch) {
        final Uri uri = Uri.parse('$protocol$actionValue');
        try {
          if (!await launchUrl(uri)) {
            if (context.mounted) { // 修正點：StatelessWidget 要用 context.mounted
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('無法打開 $displayValue')),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('執行錯誤: $e')),
            );
          }
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: canLaunch ? _handleLaunch : null,
        child: Row(
          children: [
            Icon(icon, color: canLaunch ? Colors.deepPurple : Colors.grey[700], size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: canLaunch ? Colors.deepPurple : Colors.black,
                      decoration: canLaunch ? TextDecoration.underline : TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}