import './clock_in_model.dart';
import '../services/generic_api_service.dart';
import 'package:intl/intl.dart';
import '../auth_manager.dart'; // 確保引入 AuthManager

class ClockInApiService {
  final GenericApiService _apiService = GenericApiService();

  // 1. 獲取店點清單 (對應新 table)
  Future<List<ClockInStore>> fetchStores() async {
    return await _apiService.fetchList<ClockInStore>(
      tableName: "hrs_ClockInStore",
      pk: "StoreId",
      queryFilter: "1^100^StoreId^*^^^Stat^Y", // 假設 Stat='Y' 為啟用
      fromJson: (json) => ClockInStore.fromJson(json),
    );
  }

  // 2. 獲取打卡歷史
  Future<List<ClockInRecord>> fetchHistory(String userId) async {
    // 1. 讀取 Token
    String? userId = await AuthManager.getUserId();

    // String queryFilter = "1^100^ClockInDateTime^*^^^ClockInUserId^$userId";
    return await _apiService.fetchList<ClockInRecord>(
      tableName: "hrs_ClockInRecord",
      pk: "ClockInId",
      queryFilter: "1^100^ClockInDateTime^*^ClockInDateTime >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)^hrs_ClockInRecord^ClockInUserId^$userId",
      fromJson: (json) => ClockInRecord.fromJson(json),
    );
  }

  // 3. 提交打卡
  //Future<List> postClockIn(ClockInRecord record) async {
  Future<List<ClockInRecord>> postClockIn(ClockInRecord record) async {
    // 取得當前登入者 ID (確保 AuthManager 已改為單例模式)
    final String currentUid = AuthManager().currentUserId ?? record.userId.toString();

    // 將所有欄位轉為 String，避免 Map<String, String?> 的錯誤
    final Map<String, String> data = {
      "ClockInUserId": currentUid,
      "ClockInDateTime": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      "ClockInLatitude": (record.latitude ?? 0.0).toString(),
      "ClockInLongitude": (record.longitude ?? 0.0).toString(),
      "ClockInType": record.type ?? "未知",
      "ClockInStoreId": record.storeId ?? "",
      "CreatorId": currentUid,
      "CreateDateTime": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    };

    return await _apiService.fetchList<ClockInRecord>(
      tableName: "hrs_ClockInRecord",
      pk: "ClockInId",
      queryFilter: "", // 通常新增不需要 filter，依後端 API 協議而定
      action: "C", // 傳入您指定的動作碼 'C' (Create)
      data: data, // 將打卡欄位資料透過額外參數傳入
      fromJson: (json) => ClockInRecord.fromJson(json), // 這裡填入模型的解析工廠
    );
  }
}