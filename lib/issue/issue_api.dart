import './issue_model.dart';
import '../services/generic_api_service.dart'; // 引入共用服務
import '../auth_manager.dart'; // 確保引入 AuthManager

class IssueApiService {
  final GenericApiService _apiService = GenericApiService();
  final String currentUserId; // 應由登入頁面傳入

  IssueApiService({this.currentUserId = 'admin'});

  Future<List<Issue>> fetchIssues() async {
    // 篩選條件：指派給當前使用者 (responsible = currentUserId) 且狀態非 '已結案' (Status != 4)
    // 格式: 1^100^raised_date^*^responsible^=^$currentUserId^issue_status^!=^4
    // 讀取 user_id
    String? userId = await AuthManager.getUserId();
    String filterPart = "responsible^$userId";

    // 完整的 queryFilter 格式：Page^PageSize^SortColumn^SortOrder^Filter...
    String queryFilter = "1^100^issueid^*^^^$filterPart";

    return await _apiService.fetchList<Issue>(
      tableName: "pms_issuelog", // 對應到問題追蹤表格
      pk: "issueid",              // 主鍵為 issueid
      queryFilter: queryFilter,
      fromJson: (json) => Issue.fromJson(json),
    );
  }
}