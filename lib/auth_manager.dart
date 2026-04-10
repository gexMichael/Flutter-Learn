import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  // --- 單例模式設定 ---
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  // 記憶體中的快取，讓您可以直接同步存取
  String? currentUserId;
  String? currentToken;
  String? currentCompany; // 記憶體快取

  // 定義鍵值常數，避免硬編碼字串出錯
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id'; // [新增] 用於儲存工號的鍵值
  static const String _companyKey = 'user_company'; // [新增] 公司別 Key

  /// 初始化：App 啟動時呼叫一次，把硬碟資料讀進記憶體
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString(_userIdKey);
    currentToken = prefs.getString(_tokenKey);
    currentCompany = prefs.getString(_companyKey); // [新增] 初始化讀取
  }

  /// 儲存登入資訊：包含 Token 與工號
  /// 當登入成功時，同時呼叫此方法
  static Future<void> saveLoginInfo(String token, String userId, String company) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_companyKey, company); // [新增] 儲存公司別

    // 同步更新記憶體快取
    AuthManager().currentUserId = userId;
    AuthManager().currentToken = token;
    AuthManager().currentCompany = company; // [新增] 同步快取
  }

  /// 讀取儲存的工號 (userid)
  /// 如果沒找到則回傳 null，可用於判斷是否需重新登入
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// 讀取儲存的 Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// 移除所有登入資訊 (用於登出)
  /// 確保 Token 與工號同步清除，保障資安
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    print('User logged out, auth info cleared.');
  }

  /// 檢查是否已登入 (Token 與 UserID 皆存在)
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final userId = await getUserId();
    return token != null && userId != null;
  }
}