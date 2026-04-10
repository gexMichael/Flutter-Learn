import 'package:flutter/material.dart';
import '../auth_manager.dart'; // 引入剛才修正的 AuthManager

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _currentUserId = '載入中...';
  bool _isNotificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // 從本地儲存載入使用者工號
  Future<void> _loadUserInfo() async {
    final userId = await AuthManager.getUserId();
    setState(() {
      _currentUserId = userId ?? '未登入';
    });
  }

  // 處理登出邏輯
  void _handleLogout() async {
    // 顯示確認對話框
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認登出'),
        content: const Text('您確定要登出系統嗎？登出後將清除本地緩存資訊。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('確定', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthManager.logout();
      // 導向登入頁面並清空路由棧
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系統設定'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 區塊一：個人資訊
          _buildSectionHeader('個人帳戶'),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('當前使用者'),
            subtitle: Text('工號：$_currentUserId'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () { /* 導向個人詳細資料 */ },
          ),

          const Divider(),

          // 區塊二：系統設定
          _buildSectionHeader('偏好設定'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('推播通知'),
            subtitle: const Text('接收即時會議與 Issue 通知'),
            value: _isNotificationEnabled,
            onChanged: (bool value) {
              setState(() {
                _isNotificationEnabled = value;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('深色模式'),
            trailing: const Text('跟隨系統'),
            onTap: () { /* 實作切換主題邏輯 */ },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('語系設定'),
            trailing: const Text('繁體中文'),
            onTap: () { /* 實作切換語言邏輯 */ },
          ),

          const Divider(),

          // 區塊三：關於與支援
          _buildSectionHeader('其他'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本資訊'),
            trailing: const Text('v1.0.2'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('使用手冊'),
            onTap: () { /* 開啟 PDF 或網頁 */ },
          ),

          const SizedBox(height: 30),

          // 登出按鈕
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('安全登出'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 輔助函式：建立區塊標題
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}