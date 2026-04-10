import '../services/generic_api_service.dart';
import './channel_sales_model.dart'; // 導入統一的模型

class SalesStatisticsService {
  final GenericApiService _apiService = GenericApiService();

  // 1. 標準獲取統計列表
  Future<List<SalesStats>> getChannelStats({
    required String startYYMM,
    required String endYYMM,
    String? channelId,
  }) async {
    String filter = "stats_yymm^$startYYMM~$endYYMM";
    if (channelId != null && channelId.trim().isNotEmpty) {
      filter += "^channelid^$channelId";
    }
    String queryFilter = "1^1000^stats_yymm^*^^^$filter";

    return await _apiService.fetchList<SalesStats>(
      tableName: "dw_channel_sales_statistics",
      pk: "channelid",
      queryFilter: queryFilter,
      fromJson: (json) => SalesStats.fromJson(json),
    );
  }

  // 2. 呼叫 Store Procedure 進階分析
  Future<List<SalesStats>> executeSP({
    required String endpoint,
    required String p_01,
    required String p_02,
    required String p_03,
  }) async {
    // 必須明確傳入泛型 <ChannelSalesModel> 與 fromJson 參數
    return await _apiService.fetchProcedure<SalesStats>(
      procedureEndpoint: endpoint,
      params: {
        "para01": p_01,
        "para02": p_02,
        "para03": p_03
      },
      fromJson: (json) => SalesStats.fromJson(json), // 修正：加入轉型邏輯
    );
  }
}