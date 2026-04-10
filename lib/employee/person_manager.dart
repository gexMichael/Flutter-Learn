import 'package:flutter/material.dart';
import './person_api.dart';
import './person_model.dart';
import './person_detail.dart'; // 稍後創建

class PersonManager extends StatefulWidget {
  const PersonManager({super.key});

  @override
  State<StatefulWidget> createState() {
    return _PersonManagerState();
  }
}

class _PersonManagerState extends State<PersonManager> {
  late PersonApiService _apiService;
  late Future<List<Person>> _peopleFuture;

  // 新增：搜尋文字控制器
  final TextEditingController _searchController = TextEditingController();

  // 新增：用於記錄當前的搜尋關鍵字
  String _currentSearchTerm = '';

  @override
  void initState() {
    super.initState();
    _apiService = PersonApiService();
    // 頁面加載時自動開始獲取資料
    _peopleFuture = _apiService.fetchPeople();

    // 新增：監聽搜尋框文字變更
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // 釋放資源
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // 搜尋文字變更時觸發的邏輯
  void _onSearchChanged() {
    final newTerm = _searchController.text;
    // 只有當關鍵字真正改變時才刷新
    if (newTerm != _currentSearchTerm) {
      _currentSearchTerm = newTerm;
      _refreshPeople();
    }
  }

  // 刷新資料的函數
  void _refreshPeople() {
    setState(() {
      // 調用 API 時傳入目前的搜尋關鍵字
      _peopleFuture = _apiService.fetchPeople(searchName: _currentSearchTerm);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('公司通訊錄'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新列表',
            onPressed: _refreshPeople,
          ),
        ],
        // 新增：底部放置搜尋框
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '輸入姓名進行查詢...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _currentSearchTerm.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear(); // 清空文字會觸發 _onSearchChanged
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Person>>(
        future: _peopleFuture,
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
                  ElevatedButton(onPressed: _refreshPeople, child: const Text('重試')),
                ],
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return PersonList(people: snapshot.data!);
          } else {
            return const Center(child: Text('查無人員資料。'));
          }
        },
      ),
    );
  }
}

// -----------------------------------------------------------
// 列表顯示小部件 (PersonList)
// -----------------------------------------------------------

class PersonList extends StatelessWidget {
  final List<Person> people;

  const PersonList({required this.people, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: people.length,
      itemBuilder: (BuildContext context, int index) {
        final person = people[index];

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
          child: InkWell(
            onTap: () {
              // 點擊項目：導航到詳細頁面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PersonDetail(person: person),
                ),
              );
            },
            child: ListTile(
              // 左側性別指示器
              leading: Icon(
                person.sexIcon,
                color: person.sexColor,
                size: 32,
              ),
              title: Text(
                person.personCName ?? '姓名未知',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${person.departmentId ?? '無部門'} | ${person.jobName ?? '無職稱'}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}