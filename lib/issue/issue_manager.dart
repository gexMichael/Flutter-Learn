import 'package:flutter/material.dart';
import './issue_api.dart';
import './issue_model.dart';
import './issue_detail.dart';

class IssueManager extends StatefulWidget {
  // 實際應用中，這裡應該傳入當前用戶 ID
  final String currentUserId;
  const IssueManager({this.currentUserId = 'admin', super.key});

  @override
  State<StatefulWidget> createState() {
    return _IssueManagerState();
  }
}

class _IssueManagerState extends State<IssueManager> {
  late IssueApiService _apiService;
  late Future<List<Issue>> _issuesFuture;

  @override
  void initState() {
    super.initState();
    _apiService = IssueApiService(currentUserId: widget.currentUserId);
    _issuesFuture = _apiService.fetchIssues();
  }

  void _refreshIssues() {
    setState(() {
      _issuesFuture = _apiService.fetchIssues();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('指派給我的問題清單 (${widget.currentUserId})'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新列表',
            onPressed: _refreshIssues,
          ),
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: '返回主頁',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Issue>>(
        future: _issuesFuture,
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
                  ElevatedButton(onPressed: _refreshIssues, child: const Text('重試')),
                ],
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return IssueList(issues: snapshot.data!);
          } else {
            return const Center(child: Text('目前沒有指派給您的問題。'));
          }
        },
      ),
      // 底部浮動按鈕：新增問題
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('待實作新增問題頁面。')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('新增問題'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

// -----------------------------------------------------------
// 列表顯示小部件 (IssueList)
// -----------------------------------------------------------

class IssueList extends StatelessWidget {
  final List<Issue> issues;

  const IssueList({required this.issues, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: issues.length,
      itemBuilder: (BuildContext context, int index) {
        final item = issues[index];

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
          child: InkWell(
            onTap: () {
              // 點擊項目：導航到詳細頁面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IssueDetail(issue: item),
                ),
              );
            },
            child: ListTile(
              // 左側顯示優先級
              leading: Icon(
                item.priorityIcon,
                color: item.priorityColor,
                size: 30,
              ),
              title: Text(
                '#${item.issueId} ${item.description ?? '無描述'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '專案: ${item.projectId ?? 'N/A'} | 提出人: ${item.raisedBy ?? 'N/A'}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.statusText,
                    style: TextStyle(fontSize: 12, color: item.statusColor, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    item.formattedExpectedDate,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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