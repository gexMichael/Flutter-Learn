import 'package:flutter/material.dart';
// 確保你的 news.dart 文件和 News 類已經被正確引入
import 'news.dart';
// 確保引入 MainMenu 所在的 main.dart 文件，以便導航
import '../main.dart';

class NewsManager extends StatefulWidget {
  const NewsManager({super.key});

  @override
  State<StatefulWidget> createState() {
    return _NewsManagerState();
  }
}

class _NewsManagerState extends State<NewsManager> {
  List<String> news = ['第一筆資料: F-16 戰機升級計畫', '第二筆資料: 台積電研發新突破'];

  void _addNews() {
    setState(() {
      news.add('新增資料：最新動態 ${DateTime.now().second}');
    });
  }

  // 新增的導航函數：返回到主選單
  void _backToHome() {
    // Navigator.popUntil 會一直彈出 (Pop) 路由堆棧中的頁面，直到遇到一個
    // 滿足條件 (predicte) 的路由。在這裡，我們使用 (route) => route.isFirst
    // 來返回到路由堆棧中的第一個頁面，也就是 MainMenu (如果您的啟動順序是 Login -> MainMenu)。
    // 如果 MainMenu 不是第一個頁面，您可以考慮使用：
    // Navigator.popUntil(context, ModalRoute.withName('/main_menu'));
    // 但這需要您在 MaterialApp 中為 MainMenu 設定路由名稱。

    // 最保險且簡單的方法是直接彈出所有，然後重新推入 MainMenu（確保 MainMenu 不會有歷史記錄）
    // 或者我們假設 MainMenu 是 Login 成功後的第一個頁面，使用 pushReplacement 清理過的堆棧。
    // 在本例中，我們直接導航回 MainMenu，並清除所有在它之上的頁面。

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainMenu()),
          (Route<dynamic> route) => false, // 移除所有前面的路由
    );

    // 註：若 NewsManager 已經是 Scaffold 的子頁面，使用 Navigator.pop(context)
    // 即可返回上一個頁面（即 MainMenu）。但如果想確保是回主頁，用 pushAndRemoveUntil 更明確。
  }

  @override
  Widget build(BuildContext context) {
    // *** 關鍵修改：將整個頁面包裹在 Scaffold 中以包含 AppBar ***
    return Scaffold(
      appBar: AppBar(
        title: const Text('公告事項'),
        // ----------------------------------------------------
        // 新增的返回主頁按鈕
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.home), // 使用一個 Home 圖標
            tooltip: '返回主頁', // 長按時的提示
            onPressed: _backToHome, // 點擊時呼叫導航函數
          ),
        ],
        // ----------------------------------------------------
      ),
      body: Column(
        children: <Widget>[
          // 1. 固定高度的按鈕部分
          Container(
            margin: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: _addNews,
              child: const Text(
                '新增資料',
                style: TextStyle(fontSize: 20, color: Colors.redAccent),
              ),
            ),
          ),

          // 2. 佔據剩餘空間的列表部分
          Expanded(
            child: News(news),
          ),
        ],
      ),
    );
  }
}