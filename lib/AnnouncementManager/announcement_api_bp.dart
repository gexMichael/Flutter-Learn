import 'package:http/http.dart' as http;
import 'dart:convert';
import './announcement_model.dart';
import '../auth_manager.dart'; // 確保引入 AuthManager

// API 相關常數 (假設與登入 API 使用相同的 Base URL 結構)
const String BASE_IP = "https://api.gex.com.tw:8033";
// **請替換成您實際獲取公告列表的 API 路徑**
const String ANNOUNCEMENT_LIST_ENDPOINT = "xapi/v2/eis_demo/orm_api/3/";
const String ANNOUNCEMENT_LIST_URL = "$BASE_IP/$ANNOUNCEMENT_LIST_ENDPOINT";

class AnnouncementApiService {
  Future<List<Announcement>> fetchAnnouncements() async {
    // 1. 讀取儲存的 Token
    String? token = await AuthManager.getToken();

    if (token == null) {
      print("錯誤：未找到登入 Token，請重新登入！");
      // 這裡通常會導航回登入頁面
      // return;
    }

    // 建立 API 參數 (假設獲取公告列表需要類似的 token/身份驗證參數)
    final Map<String, String> params = {
      "token": '$token',
      //"page": "${page}",
      //"perPage": "${perPage}",
      //"keywords": "${keywords}",
      "_\$_tableName": "eipbbs_m",
      "_\$_pk": "uniqueno",
      "_\$_action": "P",
      "_\$_query_filter": "1^10^uniqueno^*^^pmsm02^^"
    };

    try {
      final response = await http.post(
        Uri.parse(ANNOUNCEMENT_LIST_URL),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params,
      );

      // 檢查狀態碼
      if (response.statusCode == 200) {
        // 解析 API 回應
        final Map<String, dynamic> responseData = json.decode(response.body);

        // 1. 檢查 code 是否為 0
        if (responseData['code'] == 0) {

          // 2. 根據截圖，'data' 是一個 Map，裡面包著 'items'
          final dynamic dataObject = responseData['data'];

          // 檢查 dataObject 是否為 Map，且裡面是否有 'items' 並且是 List
          if (dataObject is Map && dataObject['items'] is List) {

            // 3. 取得真正的列表 'items'
            List<dynamic> listJson = dataObject['items'];

            // 將 JSON 列表轉換為 Announcement 物件列表
            return listJson.map((json) => Announcement.fromJson(json)).toList();
          } else {
            // 雖然 code=0，但資料結構不符合預期 (例如 data 是 null 或沒有 items)
            return []; // 或拋出異常，視您的需求而定
          }
        } else {
          // API 邏輯失敗 (例如 code 不為 0)
          throw Exception(responseData['msg'] ?? 'API 呼叫失敗，但連線成功。');
        }
      } else {
        // HTTP 錯誤
        throw Exception('HTTP 錯誤: ${response.statusCode}');
      }
    } catch (e) {
      // 網路或解析錯誤
      print('公告獲取錯誤: $e');
      throw Exception('無法載入公告列表，請檢查網路。');
    }
  }
}