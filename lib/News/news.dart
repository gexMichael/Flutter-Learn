import 'package:flutter/material.dart';
// 1. 確保引入 news_detail.dart
import '../News/news_detail.dart';

class News extends StatelessWidget {
  final List<String> news;

  // 構造函數保持不變
  const News(this.news, {super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 ListView.builder 替代 Column 和 map().toList()
    // 這樣可以確保內容可以捲動，並且只構建可見的項目，效率更高。
    return ListView.builder(
      // 設置列表的長度，即 news 列表的項目數
      itemCount: news.length,

      // 根據索引來構建每個列表項目
      itemBuilder: (BuildContext context, int index) {
        final String currentNewsTitle = news[index]; // 提取當前新聞標題

        // 使用 news[index] 來取得對應的新聞文本
        return Card(
          elevation: 5, // 可選: 增加卡片陰影
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // 增加邊距
          // 在這裡可以選擇添加 Key
          key: ValueKey(currentNewsTitle + index.toString()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 讓圖片和文字可以寬度延伸
            children: <Widget>[
              // --- 點擊功能的修改在這裡 ---
              GestureDetector(
                onTap: () {
                  // 點擊事件：導航到 NewsDetail 畫面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewsDetail(
                        // 2. 將當前新聞的標題/內容傳遞給詳細頁面
                        newsTitle: currentNewsTitle,
                      ),
                    ),
                  );
                },
                child: Image.asset(
                  'assets/F16-02.jpg',
                  fit: BoxFit.cover,
                  height: 200,
                ),
              ),
              // --------------------------
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  currentNewsTitle,
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}