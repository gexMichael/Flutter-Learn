// todo_api.dart

import './todo_model.dart';
import '../services/generic_api_service.dart';
import 'package:intl/intl.dart';

class TodoApiService {
  final GenericApiService _apiService = GenericApiService();
  final String currentUserId;

  TodoApiService({this.currentUserId = 'admin'});

  /// 獲取指定日期的任務清單
  Future<List<Todo>> fetchTodos({DateTime? selectedDate, String? statusFilter}) async {
    // 預設查詢今天的資料
    DateTime dateToQuery = selectedDate ?? DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(dateToQuery);

    // 1. 組合 wheresql_org (第 5 個參數)
    // 使用 LIKE 來比對 DATETIME 欄位，確保抓到該日期的所有時段
    String whereSql = "end_date LIKE '$formattedDate%'";

    // 2. 如果有傳入狀態過濾條件，動態加上 AND 語法
    if (statusFilter != null && statusFilter != 'All') {
      String dbStatus = '';
      if (statusFilter == 'Done') {
        dbStatus = 'DONE';
      } else if (statusFilter == 'In Progress') dbStatus = 'WIP';
      else if (statusFilter == 'To do') dbStatus = 'TODO'; // 假設你的待辦狀態是 TODO

      if (dbStatus.isNotEmpty) {
        whereSql += " AND pbi_status = '$dbStatus'";
      }
    }

    // 3. 嚴格依照 API 規範組裝 10 個參數 (共 9 個 ^ 分隔符)
    // 格式：pageno^pagerec^orderby^udf_fields^wheresql_org^menuid^where_fields^where_value^where_field^where_idvalue
    String queryFilter = "1^100^id^*^$whereSql^^^^^";

    return await _apiService.fetchList<Todo>(
      tableName: "eip_todolist",
      pk: "id",
      queryFilter: queryFilter,
      fromJson: (json) => Todo.fromJson(json),
    );
  }

  // 新增：提交任務至資料庫
  Future<bool> createTodo(Todo todo) async {
    final Map<String, dynamic> data = {
      "todolist_class": todo.className,
      "task_name": todo.taskName,
      "task_desc": todo.description,
      "issue_priority": todo.priority,
      "pbi_status": todo.status ?? 'WIP',
      "end_date": todo.endDate != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(todo.endDate!) : null,
      "create_user": currentUserId,
      "create_date": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      // 新增時先不寫入 update_user / update_date
    };

    try {
      await _apiService.fetchList<dynamic>(
        tableName: "eip_todolist",
        pk: "id",
        queryFilter: "",
        action: "C",
        data: data,
        fromJson: (json) => json,
      );
      return true;
    } catch (e) {
      print("Create Todo Error: $e");
      return false;
    }
  }

  /// 更新任務狀態為已完成
  Future<bool> updateTodoStatus(int id, String status) async {
    final Map<String, dynamic> data = {
      "id": id,                  // 必填 PK
      "pbi_status": status,      // 更新狀態
      // 修正為 Schema 正確的欄位名稱 update_user / update_date
      "update_user": currentUserId,
      "update_date": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    };

    try {
      await _apiService.fetchList<dynamic>(
        tableName: "eip_todolist",
        pk: "id",
        queryFilter: "",
        action: "U",
        data: data,
        fromJson: (json) => json,
      );
      return true;
    } catch (e) {
      print("Update Todo Status Error: $e");
      return false;
    }
  }
}