import 'package:flutter/material.dart';
import './announcement_api.dart';
import './announcement_model.dart';
import './announcement_detail.dart'; // 稍後創建

class AnnouncementManager extends StatefulWidget {
  const AnnouncementManager({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AnnouncementManagerState();
  }
}

class _AnnouncementManagerState extends State<AnnouncementManager> {
  final AnnouncementApiService _apiService = AnnouncementApiService();
  late Future<List<Announcement>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    // 頁面加載時自動開始獲取資料
    _announcementsFuture = _apiService.fetchAnnouncements();
  }

  // 刷新資料的函數
  void _refreshAnnouncements() {
    setState(() {
      _announcementsFuture = _apiService.fetchAnnouncements();
    });
  }

  // 導航回主頁（與您 NewsManager 中的邏輯相似）
  void _backToHome() {
    // 假設 MainMenu 在 main.dart 中
    // import './main.dart';
    // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainMenu()), (route) => false,);
    // 在這裡我們假設它作為子頁面，使用 pop 即可返回
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('企業公告'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新列表',
            onPressed: _refreshAnnouncements,
          ),
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: '返回主頁',
            onPressed: _backToHome,
          ),
        ],
      ),
      body: FutureBuilder<List<Announcement>>(
        future: _announcementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 資料載入中
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // 資料載入失敗 (顯示錯誤訊息)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('載入失敗: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _refreshAnnouncements, child: const Text('重試')),
                ],
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            // 資料載入成功 (顯示列表)
            return AnnouncementList(announcements: snapshot.data!);
          } else {
            // 沒有資料
            return const Center(child: Text('目前沒有企業公告。'));
          }
        },
      ),
    );
  }
}

// -----------------------------------------------------------
// 列表顯示小部件 (取代原有的 News 類別)
// -----------------------------------------------------------

class AnnouncementList extends StatelessWidget {
  final List<Announcement> announcements;

  const AnnouncementList({required this.announcements, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: announcements.length,
      itemBuilder: (BuildContext context, int index) {
        final item = announcements[index];

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: InkWell(
            onTap: () {
              // 點擊項目：導航到詳細頁面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnnouncementDetail(announcement: item),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 公告標題
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 發布日期和作者
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            item.formattedBillDate,
                            style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            item.createdBy,
                            style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}