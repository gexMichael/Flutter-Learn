import './message_model.dart';
import '../services/generic_api_service.dart';
import 'package:intl/intl.dart';

class MessageApiService {
  final GenericApiService _apiService = GenericApiService();

  // 獲取個人通知訊息紀錄 (僅顯示 30 天內)
  Future<List<EipMessage>> fetchMessages(String userId) async {
    // 計算 30 天前的日期，作為查詢參數
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final dateParam = DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);

    // 格式：當前頁^每頁筆數^排序欄位^關鍵字欄位^關鍵字內容
    // 排序：按通知日期 (create_date) 降冪排列
    // 實務上可根據您的 Generic API 支援度，將 dateParam 傳入作為過濾條件
    // String queryFilter = "1^100^create_date^*^^^receivers^$userId^after^$dateParam";
    String queryFilter = "1^100^create_date^*^create_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)^^receivers^$userId^^";

    return await _apiService.fetchList<EipMessage>(
      tableName: "eip_message", // 指向訊息資料表
      pk: "id", //
      queryFilter: queryFilter,
      fromJson: (json) => EipMessage.fromJson(json),
    );
  }

  // (選用) 更新訊息為已讀狀態
  Future<bool> markAsRead(int messageId) async {
    // 實作呼叫更新 msg_status 的 API 邏輯
    // ...
    return true;
  }
}