import './meeting_model.dart';
import '../services/generic_api_service.dart'; // 引入共用服務

class MeetingApiService {
  final GenericApiService _apiService = GenericApiService();
  final String currentUserId; // 應由登入頁面傳入

  MeetingApiService({this.currentUserId = 'admin'});

  Future<List<Meeting>> fetchMeetings() async {
    // 目標：獲取與當前用戶 (currentUserId) 相關的會議通知。
    // 採用過濾邏輯：篩選參與者名單 (meeting_users) 中包含 currentUserId 的記錄。

    // 預設參數：頁碼1，每頁100筆，按 startdate 降冪排序 (*表示降冪)
    // 格式: 1^100^startdate^*^meeting_users^LIKE^%currentUserId%
    String filterPart = "startdate^*^meeting_users^LIKE^%$currentUserId%";

    // 完整的 queryFilter 格式：Page^PageSize^SortColumn^SortOrder^FilterColumn^Operator^FilterValue...
    String queryFilter = "1^100^$filterPart";

    return await _apiService.fetchList<Meeting>(
      tableName: "eipmeetingrec_m", // 對應到會議通知表格
      pk: "uniqueno",              // 主鍵為 uniqueno
      queryFilter: queryFilter,
      fromJson: (json) => Meeting.fromJson(json),
    );
  }
}