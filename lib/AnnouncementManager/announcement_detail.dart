import 'package:flutter/material.dart';
import './announcement_model.dart';
// 引入 url_launcher 來處理附件 (可選，需要 pubspec.yaml 增加 url_launcher 套件)
// import 'package:url_launcher/url_launcher.dart';

class AnnouncementDetail extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetail({required this.announcement, super.key});

  // 處理附件下載的函數 (需要 url_launcher 套件)
  /*
  void _launchAttachment(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // 處理錯誤
      print('無法開啟附件連結: $url');
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(announcement.title, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 標題
            Text(
              announcement.title,
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 資訊列
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('發布日期: ${announcement.formattedBillDate}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                Text('作者: ${announcement.personCName}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
            const Divider(height: 32.0),

            // 附件按鈕 (如果有)
            if (announcement.attachment != null && announcement.attachment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('查看附件'),
                  onPressed: () {
                    // TODO: 實作附件下載/開啟邏輯
                    // _launchAttachment(announcement.attachment!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('附件功能待實作。')),
                    );
                  },
                ),
              ),

            // 公告詳細內容 (使用 Text 顯示)
            Text(
              announcement.description,
              style: const TextStyle(
                fontSize: 16.0,
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}