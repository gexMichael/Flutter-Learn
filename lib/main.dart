import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 必須引入這個才能使用 kReleaseMode
import 'News/news_manager.dart';
import './placeholder_screens.dart';
import './login_page.dart';        // 確保引入登入頁面
import './auth_manager.dart';

/*
  您的 Dart HTTP 客戶端可能無法完成與伺服器的 SSL/TLS 握手。這需要將您的整個 App 結構調整為使用 io.HttpClient
  警告： 這是一個臨時且不安全的解決方案。 它會強制 Dart 客戶端信任所有憑證。只建議在無法控制伺服器憑證或開發環境中臨時使用。
  還需要找時間查一下錯誤原因 20251214 modify by Gemini 3.0
*/
import 'dart:io';

// 確保引入新的公告管理器
import './AnnouncementManager/announcement_manager.dart';
import './todo/todo_manager.dart';
import './employee/person_manager.dart';
import './meeting/meeting_manager.dart';
import './issue/issue_manager.dart';
import './setup/settings_page.dart';
import './clockin/clock_in_manager.dart';
import './leave/leave_manager.dart';
import './calendar/calendar_manager.dart';
import './expense/expense_manager.dart';
import './chart/channel_sales_manager.dart';
import './bpm/sign_todo_manager.dart';
import './message/message_manager.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (cert, host, port) => !kReleaseMode;
      //    (X509Certificate cert, String host, int port) => true; // 總是回傳 true (忽略 SSL 錯誤)
  }
}

void main() async {
  // 在 main 函數中加入這行(否則 https 在 debug 可能會報錯)
  HttpOverrides.global = MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();
  // App 啟動時先載入一次，之後全域都不用再寫 await
  await AuthManager().initialize();

  runApp(const ZenApp());
}

class ZenApp extends StatelessWidget {
  const ZenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '企業行動e化中控台',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // 使用 Material 3 風格
        useMaterial3: true,
      ),
      // 設置主選單畫面為首頁
      // home: const MainMenu(),
      home: const LoginPage(),
    );
  }
}

// ------------------------------------
// 主選單的資料結構 (Data Model)
// ------------------------------------

class MenuItem {
  final String title;
  final IconData icon;
  final Widget targetScreen;

  MenuItem({
    required this.title,
    required this.icon,
    required this.targetScreen,
  });
}

// ------------------------------------
// 主選單畫面 (MainMenu) - 九宮格實作
// ------------------------------------
class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  // 公司資訊變數
  final String companyName = "中華開放原始碼應用推廣協會";
  final String slogan = "推動開源 × 數位轉型 × 企業創新";
  final String copyrightYear = "2024";

  @override
  Widget build(BuildContext context) {
    // 從 AuthManager 取得當前用戶 ID，若為空則預設 guest
    final String uid = AuthManager().currentUserId ?? "admin";

    // 所有選單項目的列表
    final List<MenuItem> menuItems = [
      MenuItem(title: '公告事項', icon: Icons.article, targetScreen: AnnouncementManager()),
      MenuItem(title: '員工打卡',icon: Icons.access_time_filled,targetScreen: ClockInManager(userId: uid)),
      MenuItem(title: '請假作業', icon: Icons.event_available, targetScreen: LeaveManager(currentUserId: uid)),
      MenuItem(title: '待簽核事項', icon: Icons.pending_actions, targetScreen: SignTodoManager()),
      MenuItem(title: '待辦事項', icon: Icons.checklist, targetScreen: TodoManager(currentUserId: uid)),
      MenuItem(title: '行事曆', icon: Icons.calendar_today, targetScreen: CalendarManager(userId: uid)),
      MenuItem(title: '會議通知', icon: Icons.people_alt, targetScreen: MeetingManager()),
      MenuItem(title: '產品型錄', icon: Icons.local_mall, targetScreen: PlaceholderScreen(title: '產品型錄')),
      MenuItem(title: '通訊錄', icon: Icons.contact_phone, targetScreen: PersonManager()),
      MenuItem(title: '業績查詢', icon: Icons.query_stats, targetScreen: ChannelSalesManager()),
      MenuItem(title: 'Issue List', icon: Icons.bug_report, targetScreen: IssueManager()),
      MenuItem(title: '訊息通知', icon: Icons.notifications, targetScreen: MessageManager(currentUserId: uid)),
      MenuItem(title: '費用申請', icon: Icons.article, targetScreen: ExpenseManager(currentUserId: uid)),
      MenuItem(title: '新聞(Demo)', icon: Icons.article, targetScreen: NewsManager()),
      MenuItem(title: '設定', icon: Icons.settings, targetScreen: SettingsPage()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('企業應用主選單'),
        // 增加 App Bar 的高度，使其更符合 Material 3 風格 (可選)
        toolbarHeight: 70,
        // 可以在這裡加入登出按鈕
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthManager.logout(); // <-- 記得加入此行

              // 登出：導航回登入頁面並清除所有歷史堆棧
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      // 使用 Column 將 GridView 和底部資訊垂直堆疊
      body: Column(
        children: <Widget>[
          // 1. 主要內容區 (Grid View) - 使用 Expanded 佔滿剩餘空間
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              // 核心：使用 GridView.count 建立九宮格佈局
              child: GridView.count(
                // 每行顯示 3 個項目（實現九宮格的第一條件）
                crossAxisCount: 3,
                // 項目間的間距
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                // 遍歷 menuItems 列表來構建每個選單項目
                children: menuItems.map((item) {
                  return MainMenuItemTile(item: item);
                }).toList(),
              ),
            ),
          ),
          // 2. 底部公司資訊、Slogan 和版權宣告 (固定在最下方)
          Container(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            width: double.infinity, // 佔滿寬度
            child: Column(
              children: <Widget>[
                // 公司名稱
                Text(
                  companyName,
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4.0),
                // Slogan
                Text(
                  slogan,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8.0),
                // 版權宣告
                /*
                Text(
                  'Copyright © $copyrightYear $companyName. All rights reserved.',
                  style: TextStyle(
                    fontSize: 10.0,
                    color: Colors.grey[500],
                  ),
                ),
                */
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------
// 單個選單項目的小部件 (MainMenuItemTile)
// ------------------------------------

class MainMenuItemTile extends StatelessWidget {
  final MenuItem item;

  const MainMenuItemTile({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0, // 增加陰影，更有質感
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: InkWell(
        // 使用 InkWell 獲得點擊時的漣漪效果
        onTap: () {
          // 點擊後導航到對應的目標畫面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => item.targetScreen,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 選單圖標
            Icon(
              item.icon,
              size: 48.0,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8.0),
            // 選單名稱
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}