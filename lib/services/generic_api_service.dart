import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth_manager.dart'; // 確保引入 AuthManager

// 共用 API 常數
//const String BASE_IP = "https://api.gex.com.tw:8033";
//const String COMMON_API_ENDPOINT = "xapi/v2/eis_demo/orm_api_v2/2/";
//const String COMMON_API_URL = "$BASE_IP/$COMMON_API_ENDPOINT";

class GenericApiService {
  // [修改] 移除 const COMMON_API_URL，改為方法獲取
  static const String BASE_IP = "https://api.gex.com.tw";  // :8033

  // 修改後的動態 URL 產生器，支援傳入不同的 store procedure 與回傳 dataset 數
  String _getProcedureUrl(String endpoint, String version) {
    final String db = AuthManager().currentCompany ?? "demo"; //
    final String dbAll = "eis_$db"; //
    return "$BASE_IP/xapi/v2/$dbAll/$endpoint/$version/"; //
  }

  /// 呼叫 Store Procedure 的通用方法
  /// [T] : 目標資料模型
  /// [procedureEndpoint] : 端點名稱 (例如: 'sp_get_channel_sales_stats')
  /// [version] : 版本號，預設為 "2"
  /// [params] : 傳遞給 SP 的參數 Map
  /// [fromJson] : 將 Map 轉換為物件的工廠方法
  Future<List<T>> fetchProcedure<T>({
    required String procedureEndpoint,
    String version = "2",
    required Map<String, String> params,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    String? token = await AuthManager.getToken();
    if (token == null) throw Exception('未登入：找不到有效 Token');

    final Map<String, String> body = {"token": token, ...params};
    final String url = _getProcedureUrl(procedureEndpoint, version);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final int code = responseData['code'] ?? responseData['Code'] ?? -1;

        if (code == 0) {
          final dynamic dataObject = responseData['data'];

          if (dataObject is List) {
            return dataObject.map((j) => fromJson(j as Map<String, dynamic>)).toList();
          } else if (dataObject is Map<String, dynamic>) {
            return [fromJson(dataObject)];
          }
          return []; // 數據格式不符回傳空清單
        } else {
          print("API 錯誤: ${responseData['msg'] ?? responseData['message']}");
          return []; // Code 不為 0 回傳空清單
        }
      } else {
        // [關鍵修正] statusCode 不為 200 時拋出異常或回傳空清單
        throw Exception('HTTP 錯誤: ${response.statusCode}');
      }
    } catch (e) {
      print("fetchProcedure 發生異常: $e");
      rethrow; // 重新拋出異常讓呼叫端處理
    }
    // [關鍵修正] 確保函式末端一定有回傳值，解決截圖中的錯誤
  }

  // 以下是 orm_api
  String _getDynamicUrl() {
    // 從 AuthManager 獲取目前登入的公司別，若無則預設 eis_demo
    final String db = AuthManager().currentCompany ?? "demo";
    final String dbAll = "eis_$db";
    return "$BASE_IP/xapi/v2/$dbAll/orm_api_v2/2/";
  }

  /// 通用的獲取列表方法
  /// [T] : 目標資料模型 (例如 Announcement 或 Todo)
  /// [tableName] : 資料庫表名 (API 參數)
  /// [pk] : 主鍵欄位名稱 (API 參數)
  /// [queryFilter] : 查詢過濾條件 (API 參數)
  /// [fromJson] : 將 Map 轉換為物件的工廠方法 (例如 Announcement.fromJson)
  /// [action] : API 動作指令，預設為 'P'
  Future<List<T>> fetchList<T>({
    required String tableName,
    required String pk,
    required String queryFilter,
    required T Function(Map<String, dynamic>) fromJson,
    String action = 'P', // 對應 index.js 中的 _$_action
    Map<String, dynamic> data = const {}, // 存放實際要存入資料庫的欄位值
  }) async {

    // 1. 讀取 Token (index.js 會優先檢查 body.token)
    String? token = await AuthManager.getToken();
    if (token == null) {
      throw Exception('未登入：找不到有效 Token');
    }

    // 2. 建立 API 參數
    final Map<String, String> params = {
      "token": token,
      "_\$_tableName": tableName,
      "_\$_pk": pk,
      "_\$_action": action, // [修改] 使用傳入的參數
      "_\$_query_filter": queryFilter,
    };

    // 3. 處理動態資料欄位 (將所有 value 轉為 String 以符合 http.post body 要求)
    data.forEach((key, value) {
      if (value != null) {
        params[key] = value.toString();
      }
    });

    try {
      final response = await http.post(
        Uri.parse(_getDynamicUrl()),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // 【修正】同時相容大寫 Code 與小寫 code
        final int code = responseData['code'] ?? responseData['Code'] ?? -1;

        // 檢查後端回傳的 code
        if (code == 0) {
          final dynamic dataObject = responseData['data'];

          // 處理 index.js 回傳的資料結構 (data -> items)
          if (dataObject is Map && dataObject['items'] is List) {
            List<dynamic> listJson = dataObject['items'];
            return listJson.map((json) => fromJson(json as Map<String, dynamic>)).toList();
          } else if (dataObject is Map) {
            // 處理直接回傳單一物件的情況
            return [fromJson(dataObject as Map<String, dynamic>)];
          }
          // 若直接回傳 List (部分 action 可能直接回傳 dataResult)
          else if (dataObject is List) {
            return dataObject.map((json) => fromJson(json as Map<String, dynamic>)).toList();
          }
          return [];
        } else {
          print("API 錯誤: ${responseData['msg'] ?? responseData['message']}");
          return [];
        }
      } else {
        throw Exception('HTTP 錯誤: ${response.statusCode}');
      }
    } catch (e) {
      print("GenericApiService 發生異常: $e");
      rethrow;
    }
  }
}