import './leave_model.dart';
import '../services/generic_api_service.dart';
import 'package:intl/intl.dart';
import '../auth_manager.dart'; // 確保引入 AuthManager

class LeaveApiService {
  final GenericApiService _apiService = GenericApiService();

  // 新增：獲取所有啟用的假別清單
  // 實作快取：Key 為 leavetype_id, Value 為 leavetype_name
  static final Map<String, String> _leaveTypeCache = {};

  // *** 關聯取得假別名稱 define
  // 新增：提供外部存取快取的介面
  static String getTypeName(String id) => _leaveTypeCache[id] ?? id;

  Future<List<LeaveType>> fetchLeaveTypes() async {
    // 1. 從 API 取得原始資料
    final List<LeaveType> types = await _apiService.fetchList<LeaveType>(
      tableName: "hrs_leavetype",
      pk: "leavetype_id",
      queryFilter: "1^100^leavetype_id^*^^^",
      fromJson: (json) => LeaveType.fromJson(json),
    );

    // 2. 更新快取池
    for (var type in types) {
      _leaveTypeCache[type.id] = type.name;
    }

    return types;
  }
  // *** 關聯取得假別名稱 define

  // 查詢員工清單 (代理人)
  Future<List<Map<String, dynamic>>> fetchEmployees(String keyword) async {
    // 1. 設定查詢過濾器 (依據 Generic API 規範)
    // 格式：當前頁^每頁筆數^排序欄位^關鍵字欄位^關鍵字內容
    // 我們同時搜尋姓名(personcname)或工號(personid)
    String queryFilter = "1^50^personid^*^^^personcname^$keyword";

    final List<dynamic> result = await _apiService.fetchList<dynamic>(
      tableName: "basperson", // 指向員工主檔
      pk: "personid",
      queryFilter: queryFilter,
      fromJson: (json) => json,
    );

    // 2. 轉換並確保回傳正確的欄位映射
    return result.map((e) => {
      'id': e['personid'] ?? '',
      'name': e['personcname'] ?? '',
      'dept': e['departmentid'] ?? '',
    }).toList();
  }

  // 獲取個人請假紀錄
  Future<List<Leave>> fetchLeaves(String personId) async {
    // *** 關聯取得假別名稱，存到 Cache
    // 若快取為空，先執行一次同步
    if (_leaveTypeCache.isEmpty) {
      await fetchLeaveTypes();
    }
    // *** 關聯取得假別名稱，存到 Cache

    // 排序：按單據日期降冪
    String queryFilter = "1^100^billdate^*^start_date BETWEEN DATE_SUB(CURDATE(), INTERVAL 21 DAY) AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)^hrsm11^personid^$personId";

    return await _apiService.fetchList<Leave>(
      tableName: "hrs_leave",
      pk: "billno",
      queryFilter: queryFilter,
      fromJson: (json) => Leave.fromJson(json),
    );
  }

  // 提交請假單 (新增)
  //Future<bool> createLeave(Leave leave) async {
  Future<List<Leave>> createLeave(Leave leave) async {
    final String currentUid = AuthManager().currentUserId ?? leave.personId;

    final Map<String, dynamic> data = {
      "billdate": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      "billno": "LV${DateTime.now().millisecondsSinceEpoch}", // 範例編號
      "personid": currentUid,
      "agentid": leave.agentId,
      "leavetype": leave.leaveType,
      "starttime": DateFormat('yyyy-MM-dd HH:mm:ss').format(leave.startTime!),
      "endtime": DateFormat('yyyy-MM-dd HH:mm:ss').format(leave.endTime!),
      "days": leave.days,
      "hours": leave.hours,
      "leave_note": leave.leaveNote,
      "flow_status": "1", // 提交即進入審核中
      "create_user": currentUid,
      "create_date": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      // Sync calc
      "start_date": DateFormat('yyyy-MM-dd').format(leave.startTime!),
      "end_date": DateFormat('yyyy-MM-dd').format(leave.endTime!),
      "start_time": DateFormat('HH:mm').format(leave.startTime!),
      "end_time": DateFormat('HH:mm').format(leave.endTime!),
    };

    return await _apiService.fetchList<Leave>(
      tableName: "hrs_leave",
      pk: "ClockInId",
      queryFilter: "", // 通常新增不需要 filter，依後端 API 協議而定
      action: "C", // 傳入您指定的動作碼 'C' (Create)
      data: data, // 將打卡欄位資料透過額外參數傳入
      fromJson: (json) => Leave.fromJson(json), // 這裡填入模型的解析工廠
    );
  }

  // 修正 5: 實作撤回請假單 API
  Future<bool> withdrawLeave(String billNo) async {
    try {
      await _apiService.fetchList<dynamic>(
        tableName: "hrs_leave",
        pk: "billno",
        queryFilter: "billno^$billNo", // 指定該單號
        action: "U", // U 代表 Update
        data: {
          "flow_status": "0", // 0: 退回草稿/已撤回
          "update_user": AuthManager().currentUserId,
          "update_date": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        },
        fromJson: (json) => json,
      );
      return true;
    } catch (e) {
      print("撤回失敗: $e");
      return false;
    }
  }

  // 修正 3: 查詢簽核進度 (FlowLog)
  Future<List<FlowLog>> fetchFlowLogs(String billNo) async {
    // 假設有一張表 flow_log 記錄簽核歷程
    return await _apiService.fetchList<FlowLog>(
      tableName: "flow_log",
      pk: "log_id",
      queryFilter: "1^50^create_date^*^^^billno^$billNo",
      fromJson: (json) => FlowLog(
        stepName: json['step_name'] ?? '簽核節點',
        approverName: json['approver_name'] ?? '系統/主管',
        status: json['status'] ?? '0',
        time: json['create_date'] != null ? DateTime.tryParse(json['create_date']) : null,
      ),
    );
  }

  /// 上呈請假單
  /// 上呈請假單
  /// 對應 API 規格: bpmm02_spread
  Future<bool> promoteLeave(String personId, String billNo) async {
    // 依據標準規範，參數一律使用 para0x
    final Map<String, String> params = {
      "para01": "hrsm11",
      "para02": personId,
      "para03": billNo,
    };

    try {
      // 使用與 sign_todo_api.dart 相同的 fetchProcedure 結構
      // 依據您提供的 url: ".../bpmm02_spread/1/"，這裡將 endpoint 設為 "bpmm02_spread/1/"
      // (若底層機制會自動補齊後方的 /1/，可自行改為 "bpmm02_spread")
      await _apiService.fetchProcedure<dynamic>(
        procedureEndpoint: "bpmm02_spread",
        params: params,
        fromJson: (json) => json, // 僅需確認執行成功，回傳值暫不處理
      );

      // 只要 fetchProcedure 沒有拋出異常 (且底層已處理 code == 0)，即視為成功
      return true;
    } catch (e) {
      // 統一的錯誤捕獲與日誌
      print("LeaveApiService.promoteLeave 異常: $e");
      return false;
    }
  }

  /// 取得簽核進度歷程
  /// 對應 API: bpm_sign_history/2/
  Future<List<Map<String, dynamic>>> fetchSignHistory(String billNo) async {
    final Map<String, String> params = {
      "para01": "hrsm11", // 來源單別 functiontag
      "para02": billNo,   // 原單單號 query_id
    };

    try {
      // 呼叫 SP，並將回傳的每一筆資料解析為 Map
      return await _apiService.fetchProcedure<Map<String, dynamic>>(
        procedureEndpoint: "bpm_sign_history",
        params: params,
        fromJson: (json) => json,
      );
    } catch (e) {
      print("LeaveApiService.fetchSignHistory 異常: $e");
      return [];
    }
  }
}