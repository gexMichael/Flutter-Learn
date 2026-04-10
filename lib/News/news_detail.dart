import 'package:flutter/material.dart';

// 這是一個 StatelessWidget，用於顯示單條新聞的詳細內容
class NewsDetail extends StatelessWidget {
  final String newsTitle; // 接收從前一個畫面傳遞過來的新聞標題

  // 為了演示，我們假設詳細內容是一個較長的文本
  final String newsDetailContent =
      "這是新聞的詳細內容。它包含了更深入的分析、更多的數據和完整的背景資訊。點擊圖片後，使用者可以在這個頁面仔細閱讀。由於這是一個範例，我們使用了一些重複的文本來模擬文章長度，以確保頁面可以滾動。在這個頁面，您可以加入更多的元素，例如不同的圖片、作者資訊、發布日期等。";

  const NewsDetail({required this.newsTitle, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 設置 App Bar，標題可以是傳入的新聞標題
      appBar: AppBar(
        title: Text(newsTitle, overflow: TextOverflow.ellipsis), // 防止標題過長
      ),
      // 使用 SingleChildScrollView 確保頁面內容超出螢幕時可以滾動
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 再次顯示圖片 (可選)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  'assets/F16-02.jpg',
                  fit: BoxFit.cover,
                  height: 250,
                  width: double.infinity, // 佔滿寬度
                ),
              ),
              const SizedBox(height: 16.0),

              // 顯示新聞標題
              Text(
                newsTitle,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Divider(height: 32.0), // 分隔線

              // 顯示新聞詳細內容
              Text(
                newsDetailContent * 5, // 重複內容 5 次來模擬長文章
                style: const TextStyle(
                  fontSize: 16.0,
                  height: 1.5, // 增加行高，改善閱讀體驗
                ),
                textAlign: TextAlign.justify, // 內容兩端對齊
              ),
            ],
          ),
        ),
      ),
    );
  }
}