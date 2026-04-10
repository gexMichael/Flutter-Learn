import 'package:flutter/material.dart';
import './meeting_api.dart';
import './meeting_model.dart';
import './meeting_detail.dart';

class MeetingManager extends StatefulWidget {
  // 實際應用中，這裡應該傳入當前用戶 ID
  final String currentUserId;
  const MeetingManager({this.currentUserId = 'admin', super.key});

  @override
  State<StatefulWidget> createState() {
    return _MeetingManagerState();
  }
}

class _MeetingManagerState extends State<MeetingManager> {
  late MeetingApiService _apiService;
  late Future<List<Meeting>> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    // 服務初始化時傳入當前用戶 ID
    _apiService = MeetingApiService(currentUserId: widget.currentUserId);
    _meetingsFuture = _apiService.fetchMeetings();
  }

  // 刷新資料的函數
  void _refreshMeetings() {
    setState(() {
      _meetingsFuture = _apiService.fetchMeetings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的會議通知'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新列表',
            onPressed: _refreshMeetings,
          ),
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: '返回主頁',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Meeting>>(
        future: _meetingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('載入失敗: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _refreshMeetings, child: const Text('重試')),
                ],
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return MeetingList(meetings: snapshot.data!);
          } else {
            return const Center(child: Text('目前沒有相關會議通知。'));
          }
        },
      ),
    );
  }
}

// -----------------------------------------------------------
// 列表顯示小部件 (MeetingList)
// -----------------------------------------------------------

class MeetingList extends StatelessWidget {
  final List<Meeting> meetings;

  const MeetingList({required this.meetings, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: meetings.length,
      itemBuilder: (BuildContext context, int index) {
        final item = meetings[index];

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
          child: InkWell(
            onTap: () {
              // 點擊項目：導航到詳細頁面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeetingDetail(meeting: item),
                ),
              );
            },
            child: ListTile(
              // 左側圖示顯示
              leading: Icon(
                Icons.calendar_month,
                color: item.statusColor,
                size: 32,
              ),
              title: Text(
                item.meetingTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '地點: ${item.meetingPlace ?? '待定'} | 主持: ${item.bossPersonId ?? 'N/A'}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.statusText,
                    style: TextStyle(fontSize: 10, color: item.statusColor),
                  ),
                  Text(
                    item.formattedStartDateTime,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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